//
// Copyright 2022, Optimizely, Inc. and contributors 
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
import UIKit

class OdpEventManager {
    var odpConfig: OdpConfig
    var apiMgr: OdpEventApiManager
    
    var maxQueueSize = 100
    let maxBatchEvents = 10
    let queueLock: DispatchQueue
    let eventQueue: DataStoreQueueStackImpl<OdpEvent>
    
    let logger = OPTLoggerFactory.getLogger()
    
    init(sdkKey: String, odpConfig: OdpConfig? = nil, apiManager: OdpEventApiManager? = nil) {
        self.odpConfig = odpConfig ?? OdpConfig()
        self.apiMgr = apiManager ?? OdpEventApiManager()
        
        self.queueLock = DispatchQueue(label: "event")
        
        // a separate event queue for each sdkKey (which may have own ODP public key)
        let storeName = "OPTEvent-ODP-\(sdkKey)"
        self.eventQueue = DataStoreQueueStackImpl<OdpEvent>(queueStackName: "odp",
                                                            dataStore: DataStoreFile<[Data]>(storeName: storeName))
    }
    
    // MARK: - events
    
    func registerVUID(vuid: String) {
        sendEvent(type: Constants.ODP.eventType,
                  action: "client_initialized",
                  identifiers: [
                    Constants.ODP.keyForVuid: vuid
                  ],
                  data: [:])
    }
    
    func identifyUser(vuid: String, userId: String) {
        sendEvent(type: Constants.ODP.eventType,
                  action: "identified",
                  identifiers: [
                    Constants.ODP.keyForVuid: vuid,
                    Constants.ODP.keyForUserId: userId
                  ],
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
    
    func dispatch(_ event: OdpEvent) {
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
        
        queueLock.async {
            func removeStoredEvents(num: Int) {
                if let removedItem = self.eventQueue.removeFirstItems(count: num), removedItem.count > 0 {
                    // avoid event-log-message preparation overheads with closure-logging
                    self.logger.d({ "ODP: Removed stored \(num) events starting with \(removedItem.first!)" })
                } else {
                    self.logger.e("ODP: Failed to removed \(num) events")
                }
            }
            
            // sync group used to ensure that the sendEvent is synchronous.
            // used in flushEvents
            let sync = DispatchGroup()
            
            while let events: [OdpEvent] = self.eventQueue.getFirstItems(count: self.maxBatchEvents) {
                let numEvents = events.count
                
                // multiple auto-retries are disabled for now
                // - this may be too much since they'll be retried any way when next events arrive.
                // - also, no guarantee on success after multiple retries, so it helps minimal with extra complexity.
                
                var odpError: OptimizelyError?
                
                sync.enter()  // make the send event synchronous. enter our notify
                self.apiMgr.sendOdpEvents(apiKey: odpApiKey,
                                          apiHost: odpApiHost,
                                          events: events) { error in
                    odpError = error
                    sync.leave()  // our send is done.
                }
                sync.wait()  // wait for send completed
                
                if let error = odpError {
                    self.logger.e(error.reason)
                    
                    // retry only if needed (non-permanent)
                    if case .odpEventFailed(_, let canRetry) = error {
                        if canRetry {
                            // keep the failed event queue so it can be re-sent later
                            break
                        } else {
                            // permanent errors (400 response or invalid events, etc)
                            // discard these events so that they do not block following valid events
                        }
                    }
                }
                
                removeStoredEvents(num: numEvents)
            }
        }
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
