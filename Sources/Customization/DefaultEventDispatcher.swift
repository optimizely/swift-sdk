//
// Copyright 2019, 2021-2022, Optimizely, Inc. and contributors
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

public enum DataStoreType {
    case file, memory, userDefaults
}

open class DefaultEventDispatcher: BackgroundingCallbacks, OPTEventDispatcher {
    static let sharedInstance = DefaultEventDispatcher()
    
    // timer-interval for batching (0 = no batching, negative = use default)
    var timerInterval: TimeInterval
    // batch size (1 = no batching, 0 or negative = use default)
    // attempt to send events in batches with batchSize number of events combined
    var batchSize: Int
    var maxQueueSize: Int
    
    public struct DefaultValues {
        static public let batchSize = 10
        static public let timeInterval: TimeInterval = 60  // secs
        static public let maxQueueSize = 10000
        static let maxFailureCount = 3
    }
        
    // thread-safe lazy logger load (after HandlerRegisterService ready)
    private let threadSafeLogger = ThreadSafeLogger()
    var logger: OPTLogger {
        return threadSafeLogger.logger
    }

    // for dispatching events
    let queueLock = DispatchQueue(label: "DefaultEventDispatcherQueue")
    // using a datastore queue with a backing file
    let eventQueue: DataStoreQueueStackImpl<EventForDispatch>
    // timer as a atomic property.
    var timer = AtomicProperty<Timer>()
    
    // network reachability
    let reachability = NetworkReachability(maxContiguousFails: 1)

    // sync group used to ensure that the sendEvent is synchronous
    let notify = DispatchGroup()

    public init(batchSize: Int = DefaultValues.batchSize,
                backingStore: DataStoreType = .file,
                dataStoreName: String = "OPTEventQueue",
                timerInterval: TimeInterval = DefaultValues.timeInterval,
                maxQueueSize: Int = DefaultValues.maxQueueSize) {
        self.batchSize = batchSize > 0 ? batchSize : DefaultValues.batchSize
        self.timerInterval = timerInterval >= 0 ? timerInterval : DefaultValues.timeInterval
        self.maxQueueSize = maxQueueSize >= 100 ? maxQueueSize : DefaultValues.maxQueueSize
        
        switch backingStore {
        case .file:
            self.eventQueue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                        dataStore: DataStoreFile<[Data]>(storeName: dataStoreName))
        case .memory:
            self.eventQueue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                        dataStore: DataStoreMemory<[Data]>(storeName: dataStoreName))
        case .userDefaults:
            self.eventQueue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                        dataStore: DataStoreUserDefaults())
        }
        
        if self.maxQueueSize < self.batchSize {
            self.logger.e(.eventDispatcherConfigError("batchSize cannot be bigger than maxQueueSize"))
            self.maxQueueSize = self.batchSize
        }
                
        subscribe()
    }
    
    deinit {
        stopTimer()
        unsubscribe()
    }
    
    open func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        let count = eventQueue.count
        guard count < maxQueueSize else {
            let error = OptimizelyError.eventDispatchFailed("EventQueue is full")
            self.logger.e(error)
            completionHandler?(.failure(error))
            return
        }
        
        eventQueue.save(item: event)
        
        if count + 1 >= batchSize {
            flushEvents()
        } else {
            startTimer()
        }
        
        completionHandler?(.success(event.body))
    }

    // Note: flushEvents is synchronous with blocking notify.wait() and Thread.sleep() for retry delays
    // Per-batch retry: Each batch gets up to 3 attempts with exponential backoff
    // Global failure counter stops processing after 3 consecutive batch failures

    open func flushEvents() {
        queueLock.async {
            // Global failure counter across all batches in this flush
            var globalFailureCount = 0

            func removeStoredEvents(num: Int) {
                if let removedItem = self.eventQueue.removeFirstItems(count: num), removedItem.count > 0 {
                    self.logger.d({ "Removed \(num) event(s) from queue starting with \(removedItem.first!)" })
                } else {
                    self.logger.e("Failed to remove \(num) event(s) from queue")
                }
            }

            while let eventsToSend: [EventForDispatch] = self.eventQueue.getFirstItems(count: self.batchSize) {
                let (numEvents, batchedEvent) = eventsToSend.batch()

                guard numEvents > 0 else { break }

                guard let batchEvent = batchedEvent else {
                    // Invalid event - discard and continue with next batch
                    removeStoredEvents(num: 1)
                    continue
                }

                // Check global failure counter BEFORE processing batch
                // Stop if we've exhausted our failure count (same as old behavior)
                if globalFailureCount >= DefaultValues.maxFailureCount {
                    self.logger.e(.eventSendRetyFailed(globalFailureCount))
                    break
                }

                // Per-batch retry logic (up to 3 attempts)
                var batchAttempt = 0
                var batchSucceeded = false

                while batchAttempt < 3 && !batchSucceeded {
                    // Make send synchronous
                    self.notify.enter()
                    self.sendEvent(event: batchEvent) { result in
                        switch result {
                        case .success:
                            batchSucceeded = true
                        case .failure(let error):
                            batchSucceeded = false
                            self.logger.e(error.reason)
                        }
                        self.notify.leave()
                    }
                    self.notify.wait()  // Block until send completes

                    if !batchSucceeded {
                        batchAttempt += 1

                        // Sleep between retry attempts (not after last failure)
                        if batchAttempt < 3 {
                            let delay = self.calculateRetryDelay(attempt: batchAttempt)
                            Thread.sleep(forTimeInterval: delay)
                        }
                    }
                }

                // Update global counter based on final batch result
                if batchSucceeded {
                    removeStoredEvents(num: numEvents)
                    globalFailureCount = 0  // Reset on success
                } else {
                    globalFailureCount += 1  // Increment on failure
                    // Event stays in queue for next flush
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
    
    open func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        
        if self.reachability.shouldBlockNetworkAccess() {
            completionHandler(.failure(.eventDispatchFailed("NetworkReachability down")))
            return
        }
        
        let session = getSession()
        // without this the URLSession will leak, see docs on URLSession and https://stackoverflow.com/questions/67318867
        defer { session.finishTasksAndInvalidate() }
        
        var request = URLRequest(url: event.url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // send notification BEFORE sending event to the server
        NotificationCenter.default.post(name: .willSendOptimizelyEvents, object: event)

        let task = session.uploadTask(with: request, from: event.body) { (_, _, error) in            
            if let error = error {
                completionHandler(.failure(.eventDispatchFailed(error.localizedDescription)))
            } else {
                self.logger.d("Event Sent")
                completionHandler(.success(event.body))
            }
            
            self.reachability.updateNumContiguousFails(isError: (error != nil))
        }
        
        task.resume()
    }
    
    func getSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        return URLSession(configuration: config)
    }
    
    // MARK: - Tests

    open func close() {
        self.flushEvents()
        // Ensure flush async block has started and completed
        self.queueLock.sync {}
    }

}

// MARK: - internals

extension DefaultEventDispatcher {
    
    func applicationDidEnterBackground() {
        stopTimer()
        
        flushEvents()
    }
    
    func applicationDidBecomeActive() {
        if eventQueue.count > 0 {
            startTimer()
        }
    }
    
    func startTimer() {
        // timer is activated only for non-zero interval value
        guard timerInterval > 0 else {
            flushEvents()
            return
        }
        
        guard timer.property == nil else { return }
        
        DispatchQueue.main.async {
            // should check here again
            guard self.timer.property == nil else { return }
            
            self.timer.property = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { _ in
                self.queueLock.async {
                    if self.eventQueue.count > 0 {
                        self.flushEvents()
                    } else {
                        self.stopTimer()
                    }
                }
            }
        }
    }
    
    func stopTimer() {
        timer.performAtomic { timer in
            timer.invalidate()
        }
        timer.property = nil
    }
    
}
