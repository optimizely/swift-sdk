/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import Foundation

public enum DataStoreType {
    case file, memory, userDefaults
}

open class BatchEventProcessor: BackgroundingCallbacks, OPTEventsProcessor {
    
    static let sharedInstance = BatchEventProcessor()
    
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
    
    // the max failure count.  there is no backoff timer.
    
    let eventDispatcher: OPTEventsDispatcher
    lazy var logger = OPTLoggerFactory.getLogger()
    var backingStore: DataStoreType
    var backingStoreName: String
    
    // for dispatching events
    let dispatcher = DispatchQueue(label: "DefaultEventDispatcherQueue")
    // using a datastore queue with a backing file
    let dataStore: DataStoreQueueStackImpl<EventForDispatch>
    // timer as a atomic property.
    var timer: AtomicProperty<Timer> = AtomicProperty<Timer>()
    
    // synchronous dispatching
    let notify = DispatchGroup()
    
    var observerProjectId: NSObjectProtocol?
    var observerRevision: NSObjectProtocol?
    
    func getNotificationCenter(sdkKey: String) -> OPTNotificationCenter? {
        return HandlerRegistryService.shared.injectNotificationCenter(sdkKey: sdkKey)
    }

    public init(eventDispatcher: OPTEventsDispatcher = HTTPEventDispatcher(),
                batchSize: Int = DefaultValues.batchSize,
                timerInterval: TimeInterval = DefaultValues.timeInterval,
                maxQueueSize: Int = DefaultValues.maxQueueSize,
                backingStore: DataStoreType = .file,
                dataStoreName: String = "OPTEventQueue") {
        self.eventDispatcher = eventDispatcher
        self.batchSize = batchSize > 0 ? batchSize : DefaultValues.batchSize
        self.timerInterval = timerInterval >= 0 ? timerInterval : DefaultValues.timeInterval
        self.maxQueueSize = maxQueueSize >= 100 ? maxQueueSize : DefaultValues.maxQueueSize
        
        self.backingStore = backingStore
        self.backingStoreName = dataStoreName

        switch backingStore {
        case .file:
            self.dataStore = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                       dataStore: DataStoreFile<[Data]>(storeName: backingStoreName))
        case .memory:
            self.dataStore = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
                                                                       dataStore: DataStoreMemory<[Data]>(storeName: backingStoreName))
        case .userDefaults:
            self.dataStore = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue",
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
    
    open func process(event: UserEvent, completionHandler: DispatchCompletionHandler? = nil) {
        // EP can be shared by multiple clients
        dispatcher.async {
            guard self.dataStore.count < self.maxQueueSize else {
                let error = OptimizelyError.eventDispatchFailed("EventQueue is full")
                self.logger.e(error)
                
                self.flush()
                completionHandler?(.failure(error))
                return
            }
            
            guard let body = try? JSONEncoder().encode(event.batchEvent) else {
                let error = OptimizelyError.eventDispatchFailed("Event serialization failed")
                self.logger.e(error)
                
                completionHandler?(.failure(error))
                return
            }
            
            self.dataStore.save(item: EventForDispatch(sdkKey: event.userContext.config.sdkKey, body: body))
            
            if self.dataStore.count >= self.batchSize {
                self.flush()
            } else {
                self.startTimer()
            }
            
            completionHandler?(.success(body))
        }
    }

    open func flush() {
        dispatcher.async {
            // we don't remove anthing off of the queue unless it is successfully sent.
            var failureCount = 0
            
            func removeStoredEvents(num: Int) {
                if let removedItem = self.dataStore.removeFirstItems(count: num), removedItem.count > 0 {
                    // avoid event-log-message preparation overheads with closure-logging
                    self.logger.d({ "Removed stored \(num) events starting with \(removedItem.first!)" })
                } else {
                    self.logger.e("Failed to removed \(num) events")
                }
            }
            
            while let eventsToSend: [EventForDispatch] = self.dataStore.getFirstItems(count: self.batchSize) {
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
                
                // send notification BEFORE sending event to the server
                if let event = try? JSONSerialization.jsonObject(with: batchEvent.body, options: []) as? [String: Any] {
                    let url = batchEvent.url.absoluteString
                    let sdkKey = batchEvent.sdkKey

                    if let notifCenter = self.getNotificationCenter(sdkKey: sdkKey) {
                        let args: [Any] = [url, event]
                        notifCenter.sendNotifications(type: NotificationType.logEvent.rawValue, args: args)
                    }
                } else {
                    self.logger.e("LogEvent notification discarded due to invalid event")
                }
                
                // make the send event synchronous. enter our notify
                self.notify.enter()
                self.eventDispatcher.dispatch(event: batchEvent) { (result) -> Void in
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
    
    func applicationDidEnterBackground() {
        stopTimer()
        flush()
    }
    
    func applicationDidBecomeActive() {
        if dataStore.count > 0 {
            flush()
        }
    }
    
    func startTimer() {
        // timer is activated only for iOS10+ and non-zero interval value
        guard #available(iOS 10.0, tvOS 10.0, *), timerInterval > 0 else {
            flush()
            return
        }
        
        guard self.timer.property == nil else { return }
        
        DispatchQueue.main.async {
            // should check here again
            guard self.timer.property == nil else { return }
            
            self.timer.property = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { _ in
                self.dispatcher.async {
                    if self.dataStore.count > 0 {
                        self.flush()
                    } else {
                        self.stopTimer()
                    }
                }
            }
        }
    }
    
    func stopTimer() {
        timer.performAtomic { (timer) in
            timer.invalidate()
        }
        timer.property = nil
    }
}

// MARK: - Notification Observers

extension BatchEventProcessor {
    
    func addProjectChangeNotificationObservers() {
        observerProjectId = NotificationCenter.default.addObserver(forName: .didReceiveOptimizelyProjectIdChange, object: nil, queue: nil) { [weak self] (_) in
            self?.logger.d("Event flush triggered by datafile projectId change")
            self?.flush()
        }
        
        observerRevision = NotificationCenter.default.addObserver(forName: .didReceiveOptimizelyRevisionChange, object: nil, queue: nil) { [weak self] (_) in
            self?.logger.d("Event flush triggered by datafile revision change")
            self?.flush()
        }
    }
    
    func removeProjectChangeNotificationObservers() {
        if let observer = observerProjectId {
            NotificationCenter.default.removeObserver(observer, name: .didReceiveOptimizelyProjectIdChange, object: nil)
        }
        if let observer = observerRevision {
            NotificationCenter.default.removeObserver(observer, name: .didReceiveOptimizelyRevisionChange, object: nil)
        }
    }
    
    // MARK: - Tests

    open func close() {
        sync()
        flush()
        sync()
    }
    
    open func sync() {
        dispatcher.sync {}
    }
    
}
