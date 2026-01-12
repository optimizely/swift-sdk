//
// Copyright 2022-2023, Optimizely, Inc. and contributors
// 
// Licensed under the Apache License, Version 2.0 (the "License");  
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at   
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

open class OdpEventManager {
    var odpConfig = OdpConfig()
    var apiMgr: OdpEventApiManager

    var maxQueueSize = 100
    var maxBatchEvents = 10
    let maxFailureCount = 3
    let queueLock: DispatchQueue
    let eventQueue: DataStoreQueueStackImpl<OdpEvent>

    let reachability = NetworkReachability(maxContiguousFails: 1)
    let logger = OPTLoggerFactory.getLogger()
    
    /// OdpEventManager init
    /// - Parameters:
    ///   - sdkKey: datafile sdkKey
    ///   - apiManager: OdpEventApiManager
    ///   - resourceTimeoutInSecs: timeout for event dispatch
    public init(sdkKey: String,
                apiManager: OdpEventApiManager? = nil,
                resourceTimeoutInSecs: Int? = nil) {
        self.apiMgr = apiManager ?? OdpEventApiManager(timeout: resourceTimeoutInSecs)
        
        self.queueLock = DispatchQueue(label: "event")
        
        // a separate event queue for each sdkKey (which may have own ODP public key)
        let storeName = "OPTEvent-ODP-\(sdkKey)"
        self.eventQueue = DataStoreQueueStackImpl<OdpEvent>(queueStackName: "odp",
                                                            dataStore: DataStoreFile<[Data]>(storeName: storeName))
    }
    
    // MARK: - events
    
    func sendInitializedEvent(vuid: String) {
        sendEvent(type: Constants.ODP.eventType,
                  action: "client_initialized",
                  identifiers: [
                    Constants.ODP.keyForVuid: vuid
                  ],
                  data: [:])
    }
    
    func identifyUser(vuid: String?, userId: String?) {
        var identifiers = [String: String]()
        if let _vuid = vuid {
            identifiers[Constants.ODP.keyForVuid] = _vuid
        }
        if let userId = userId {
            identifiers[Constants.ODP.keyForUserId] = userId
        }
        
        sendEvent(type: Constants.ODP.eventType,
                  action: "identified",
                  identifiers: identifiers,
                  data: [:])
    }
    
    func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any?]) {
        let event = OdpEvent(type: type,
                             action: action,
                             identifiers: identifiers,
                             data: addCommonEventData(data))
        dispatch(event)
    }
    
    func addCommonEventData(_ customData: [String: Any?] = [:]) -> [String: Any?] {
        var data: [String: Any?] = [
            "idempotence_id": UUID().uuidString,
            
            "data_source_type": "sdk",
            "data_source": Utils.swiftSdkClientName,        // "swift-sdk"
            "data_source_version": Utils.sdkVersion,        // "3.10.2"
            
            // [optional] client sdks only
            "os": Utils.os,                                    // ("iOS", "tvOS", "watchOS", "macOS", "Android", "Windows", "Linux", ...)
            "os_version": Utils.osVersion,                  // "13.2", ...
            "device_type": Utils.deviceType,                // fixed set = ("Phone", "Tablet", "Smart TV", "Watch", “PC”, "Other")
            "model": Utils.deviceModel                      // ("iPhone 12", "iPad 2", "Pixel 2", "SM-A515F", ...)
            
            // [optional]
            // "data_source_instance": <sub>,               // if need subtypes of data_source
        ]
        
        data.merge(customData) { (_, custom) in custom }    // keep custom data if conflicts
        return data
    }
    
    // MARK: - dispatch
    
    // open for FSC testing support
    open func dispatch(_ event: OdpEvent) {
        if eventQueue.count < maxQueueSize {
            eventQueue.save(item: event)
        } else {
            let error = OptimizelyError.eventDispatchFailed("ODP EventQueue is full")
            self.logger.e(error)
        }
        
        flush()
    }
    
    func flush() {
        guard odpConfig.eventQueueingAllowed else {
            // clean up all pending events if datafile becomes ready but has no ODP public key (not integrated)
            reset()
            return
        }

        guard let odpApiKey = odpConfig.apiKey, let odpApiHost = odpConfig.apiHost else {
            return
        }

        // check if network is down to avoid that all existing events in the queue get discarded when network is down
        guard !reachability.shouldBlockNetworkAccess() else {
            logger.e(.eventDispatchFailed("NetworkReachability down for ODP events"))
            return
        }

        queueLock.async {
            // Global failure counter across all batches in this flush
            var globalFailureCount = 0
            let notify = DispatchGroup()

            func removeStoredEvents(num: Int) {
                if let removedItem = self.eventQueue.removeFirstItems(count: num), removedItem.count > 0 {
                    self.logger.d({ "ODP: Removed \(num) event(s) from queue starting with \(removedItem.first!)" })
                } else {
                    self.logger.e("ODP: Failed to remove \(num) event(s) from queue")
                }
            }

            while let events: [OdpEvent] = self.eventQueue.getFirstItems(count: self.maxBatchEvents) {
                let numEvents = events.count

                // Check global failure counter BEFORE processing batch
                if globalFailureCount >= self.maxFailureCount {
                    self.logger.e(.odpEventSendRetyFailed(globalFailureCount))
                    break
                }

                // Check network before each batch
                guard !self.reachability.shouldBlockNetworkAccess() else {
                    break
                }

                // Per-batch retry logic (up to 3 attempts for recoverable errors)
                var batchAttempt = 0
                var batchSucceeded = false
                var isRecoverable = true

                while batchAttempt < 3 && !batchSucceeded && isRecoverable {
                    var odpError: OptimizelyError?

                    // Make send synchronous
                    notify.enter()
                    self.apiMgr.sendOdpEvents(apiKey: odpApiKey,
                                              apiHost: odpApiHost,
                                              events: events) { error in
                        odpError = error
                        notify.leave()
                    }
                    notify.wait()  // Block until send completes

                    if let error = odpError {
                        self.logger.e(error.reason)

                        // Check if recoverable
                        if case .odpEventFailed(_, let canRetry) = error, canRetry {
                            // Recoverable error - can retry
                            isRecoverable = true
                            batchAttempt += 1

                            // Sleep between retry attempts (not after last failure)
                            if batchAttempt < 3 {
                                let delay = self.calculateRetryDelay(attempt: batchAttempt)
                                Thread.sleep(forTimeInterval: delay)
                            }
                        } else {
                            // Non-recoverable error - don't retry
                            isRecoverable = false
                            batchSucceeded = false
                        }
                    } else {
                        // Success
                        batchSucceeded = true
                    }
                }

                // Update reachability AFTER all retry attempts for this batch
                let finallyFailed = !batchSucceeded
                self.reachability.updateNumContiguousFails(isError: finallyFailed)

                // Update global counter and remove events based on result
                if batchSucceeded {
                    removeStoredEvents(num: numEvents)
                    globalFailureCount = 0  // Reset on success
                } else if !isRecoverable {
                    // Non-recoverable error - discard and continue
                    removeStoredEvents(num: numEvents)
                    globalFailureCount = 0  // Don't count non-recoverable as failure
                } else {
                    // Recoverable error, exhausted retries
                    globalFailureCount += 1  // Increment on failure
                    // Event stays in queue
                }
            }
        }
    }

    /// Calculate retry delay using exponential backoff
    /// - Parameter attempt: Current attempt number (1, 2, 3)
    /// - Returns: Delay in seconds (200ms, 400ms, 800ms, capped at 1s)
    private func calculateRetryDelay(attempt: Int) -> TimeInterval {
        let retryStrategy = RetryStrategy(maxRetries: 2,
                                          initialInterval: 0.2,
                                          maxInterval: 1.0)
        return retryStrategy.delayForRetry(attempt: attempt)
    }
        
    func reset() {
        _ = eventQueue.removeFirstItems(count: self.maxQueueSize)
    }
    
    // MARK: - Utils
    
    /// Validate if data has all valid types only (string, integer, float, boolean, and nil),
    /// - Parameter data: a dictionary.
    /// - Returns: true if all values are valid types.
    func isDataValidType(_ data: [String: Any?]) -> Bool {
        for value in data.values {
            if let v = value {
                if Utils.isStringType(v) || Utils.isIntType(v) || Utils.isDoubleType(v) || Utils.isBoolType(v) {
                    continue
                } else {
                    return false // not a nil or a valid type
                }
            } else {
                continue // nil should be accepted
            }
        }
        
        return true
    }
}
