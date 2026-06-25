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
    case file(directory: FileManager.SearchPathDirectory? = nil), memory, userDefaults
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

    // sync group used to ensure that the flushEvents is synchronous for close()
    let notify = DispatchGroup()
    // track if flush is currently in progress
    private var isFlushing = false

    public init(batchSize: Int = DefaultValues.batchSize,
                backingStore: DataStoreType = .file(directory: nil),
                dataStoreName: String = "OPTEventQueue",
                timerInterval: TimeInterval = DefaultValues.timeInterval,
                maxQueueSize: Int = DefaultValues.maxQueueSize) {
        self.batchSize = batchSize > 0 ? batchSize : DefaultValues.batchSize
        self.timerInterval = timerInterval >= 0 ? timerInterval : DefaultValues.timeInterval
        self.maxQueueSize = maxQueueSize >= 100 ? maxQueueSize : DefaultValues.maxQueueSize
        
        switch backingStore {
        case .file(let directory):
            if let directory {
                self.eventQueue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                            dataStore: DataStoreFile<[Data]>(storeName: dataStoreName, directory: directory))
            } else {
                self.eventQueue = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                            dataStore: DataStoreFile<[Data]>(storeName: dataStoreName))
            }
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

    // Per-batch retry: Each batch gets up to 3 attempts with exponential backoff
    // Global failure counter stops processing after 3 consecutive batch failures

    open func flushEvents() {
        queueLock.async {
            guard !self.isFlushing else { return }
            
            self.isFlushing = true
            self.notify.enter()
            
            self.processNextBatch(failureCount: 0)
        }
    }
    
    private func processNextBatch(failureCount: Int) {
        // Global failure counter across all batches in this flush
        if failureCount >= DefaultValues.maxFailureCount {
            self.logger.e(.eventSendRetyFailed(failureCount))
            self.finishFlush()
            return
        }
        
        // Check reachability
        if self.reachability.shouldBlockNetworkAccess() {
            self.logger.e("NetworkReachability down")
            self.finishFlush()
            return
        }
        
        guard let eventsToSend: [EventForDispatch] = self.eventQueue.getFirstItems(count: self.batchSize) else {
            self.finishFlush()
            return
        }
        
        let (numEvents, batchedEvent) = eventsToSend.batch()
        
        guard numEvents > 0 else {
            self.finishFlush()
            return
        }
        
        guard let batchEvent = batchedEvent else {
            // discard an invalid event that causes batching failure
            // - if an invalid event is found while batching, it batches all the valid ones before the invalid one and sends it out.
            // - when trying to batch next, it finds the invalid one at the header. It discards and continue with next batch
            self.removeStoredEvents(num: 1)
            self.processNextBatch(failureCount: failureCount)
            return
        }
        
        self.sendBatch(event: batchEvent, numEvents: numEvents) { success in
            if success {
                self.removeStoredEvents(num: numEvents)
                self.processNextBatch(failureCount: 0)
            } else {
                // Retry with backoff
                let attempt = failureCount + 1
                if attempt < DefaultValues.maxFailureCount {
                    let delay = self.calculateRetryDelay(attempt: attempt)
                    self.queueLock.asyncAfter(deadline: .now() + delay) {
                        self.processNextBatch(failureCount: attempt)
                    }
                } else {
                    self.logger.e(.eventSendRetyFailed(attempt))
                    self.finishFlush()
                }
            }
        }
    }
    
    private func sendBatch(event: EventForDispatch, numEvents: Int, completion: @escaping (Bool) -> Void) {
        self.sendEvent(event: event) { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                self.logger.e(error.reason)
                completion(false)
            }
        }
    }
    
    private func finishFlush() {
        self.isFlushing = false
        self.notify.leave()
    }
    
    private func removeStoredEvents(num: Int) {
        if let removedItem = self.eventQueue.removeFirstItems(count: num), removedItem.count > 0 {
            self.logger.d({ "Removed \(num) event(s) from queue starting with \(removedItem.first!)" })
        } else {
            self.logger.e("Failed to remove \(num) event(s) from queue")
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
        // Ensure flush async block has started
        self.queueLock.sync {}
        // Wait for the flush to complete with a safety timeout.
        // We use a 10-second timeout to prevent the app from hanging indefinitely during shutdown.
        // If the flush takes longer (e.g. due to slow network or large queue), we proceed to close
        // to avoid the OS watchdog killing the app for blocking the main thread for too long.
        // This ensures a "best effort" flush while prioritizing a safe and graceful exit.
        _ = self.notify.wait(timeout: .now() + 10.0)
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
