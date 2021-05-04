//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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
        
    lazy var logger = OPTLoggerFactory.getLogger()
    // for dispatching events
    let queueLock = DispatchQueue(label: "DefaultEventDispatcherQueue")
    // using a datastore queue with a backing file
    let eventQueue: DataStoreQueueStackImpl<EventForDispatch>
    // timer as a atomic property.
    var timer = AtomicProperty<Timer>()
    var observers = [NSObjectProtocol]()
    
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
        
        addProjectChangeNotificationObservers()
        
        subscribe()
    }
    
    deinit {
        stopTimer()
        
        removeProjectChangeNotificationObservers()

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

    // notify group used to ensure that the sendEvent is synchronous.
    // used in flushEvents
    let notify = DispatchGroup()
    
    open func flushEvents() {
        queueLock.async {
            // we don't remove anthing off of the queue unless it is successfully sent.
            var failureCount = 0
            
            func removeStoredEvents(num: Int) {
                if let removedItem = self.eventQueue.removeFirstItems(count: num), removedItem.count > 0 {
                    // avoid event-log-message preparation overheads with closure-logging
                    self.logger.d({ "Removed stored \(num) events starting with \(removedItem.first!)" })
                } else {
                    self.logger.e("Failed to removed \(num) events")
                }
            }
            
            while let eventsToSend: [EventForDispatch] = self.eventQueue.getFirstItems(count: self.batchSize) {
                let (numEvents, batched) = eventsToSend.batch()
                
                guard numEvents > 0 else { break }
                
                guard let batchEvent = batched else {
                    // discard an invalid event that causes batching failure
                    // - if an invalid event is found while batching, it batches all the valid ones before the invalid one and sends it out.
                    // - when trying to batch next, it finds the invalid one at the header. It discards that specific invalid one and continue batching next ones.

                    removeStoredEvents(num: 1)
                    continue
                }
                
                // we've exhuasted our failure count.  Give up and try the next time a event
                // is queued or someone calls flush.
                if failureCount > DefaultValues.maxFailureCount {
                    self.logger.e(.eventSendRetyFailed(failureCount))
                    break
                }
                
                // make the send event synchronous. enter our notify
                self.notify.enter()
                self.sendEvent(event: batchEvent) { (result) -> Void in
                    switch result {
                    case .failure(let error):
                        self.logger.e(error.reason)
                        failureCount += 1
                    case .success:
                        // we succeeded. remove the batch size sent.
                        removeStoredEvents(num: numEvents)

                        // reset failureCount
                        failureCount = 0
                    }
                    // our send is done.
                    self.notify.leave()
                    
                }
                // wait for send
                self.notify.wait()
            }
        }
    }
    
    open func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        var request = URLRequest(url: event.url)
        request.httpMethod = "POST"
        request.httpBody = event.body
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
        }
        
        task.resume()
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
    
    // MARK: - Tests

    open func close() {
        self.flushEvents()
        self.queueLock.sync {}
    }
    
}

// MARK: - Notification Observers

extension DefaultEventDispatcher {
    
    func addProjectChangeNotificationObservers() {
        observers.append(
            NotificationCenter.default.addObserver(forName: .didReceiveOptimizelyProjectIdChange, object: nil, queue: nil) { [weak self] _ in
                self?.logger.d("Event flush triggered by datafile projectId change")
                self?.flushEvents()
            }
        )
        
        observers.append(
            NotificationCenter.default.addObserver(forName: .didReceiveOptimizelyRevisionChange, object: nil, queue: nil) { [weak self] _ in
                self?.logger.d("Event flush triggered by datafile revision change")
                self?.flushEvents()
            }
        )
    }
    
    func removeProjectChangeNotificationObservers() {
        observers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }
    
}
