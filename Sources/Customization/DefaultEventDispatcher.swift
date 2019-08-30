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

open class DefaultEventDispatcher: BackgroundingCallbacks, OPTEventDispatcher {
    
    static let sharedInstance = DefaultEventDispatcher()
    
    // the max failure count.  there is no backoff timer.
    static let MAX_FAILURE_COUNT = 3
    
    // default timerInterval
    var timerInterval: TimeInterval
    // default batchSize.
    // attempt to send events in batches with batchSize number of events combined
    var batchSize: Int
    // start trimming the front of the queue when we get to over maxQueueSize
    // TODO: implement
    var maxQueueSize: Int = 30000
    
    lazy var logger = OPTLoggerFactory.getLogger()
    var backingStore: DataStoreType
    var backingStoreName: String
    
    // for dispatching events
    let dispatcher = DispatchQueue(label: "DefaultEventDispatcherQueue")
    // using a datastore queue with a backing file
    let dataStore: DataStoreQueueStackImpl<EventForDispatch>
    // timer as a atomic property.
    var timer: AtomicProperty<Timer> = AtomicProperty<Timer>()
    
    public struct DefaultValues {
        static public let batchSize = 10
        static public let timeInterval: TimeInterval = 60  // secs
    }
    
    public init(batchSize: Int = DefaultValues.batchSize,
                backingStore: DataStoreType = .file,
                dataStoreName: String = "OPTEventQueue",
                timerInterval: TimeInterval = DefaultValues.timeInterval ) {
        self.batchSize = batchSize > 0 ? batchSize : DefaultValues.batchSize
        self.backingStore = backingStore
        self.backingStoreName = dataStoreName
        self.timerInterval = timerInterval
        
        switch backingStore {
        case .file:
            self.dataStore = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreFile<[Data]>(storeName: backingStoreName))
        case .memory:
            self.dataStore = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreMemory<[Data]>(storeName: backingStoreName))
        case .userDefaults:
            self.dataStore = DataStoreQueueStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreUserDefaults())
        }
        
        subscribe()
    }
    
    deinit {
        stopTimer()

        unsubscribe()
    }
    
    open func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        dataStore.save(item: event)
        
        if dataStore.count == batchSize {
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
        dispatcher.async {
            // we don't remove anthing off of the queue unless it is successfully sent.
            var failureCount = 0
            
            let removeStoredEvents = { (num: Int) -> Void in
                if let removedItem = self.dataStore.removeFirstItems(count: num), removedItem.count > 0 {
                    // avoid event-log-message preparation overheads with closure-logging
                    self.logger.d({ "Removed stored \(num) events starting with \(removedItem.first!)" })
                } else {
                    self.logger.e("Failed to removed \(num) events")
                }
            }
            
            let foundInvalidEvent = { (event: EventForDispatch) -> Bool in
                return event.body.isEmpty
            }
            
            while let eventsToSend: [EventForDispatch] = self.dataStore.getFirstItems(count: self.batchSize) {
                guard let (numEvents, batchEvent) = eventsToSend.batch() else { break }
                
                guard !foundInvalidEvent(batchEvent) else {
                    // discard events that create invalid batch and continue
                    removeStoredEvents(numEvents)
                    continue
                }
                
                // we've exhuasted our failure count.  Give up and try the next time a event
                // is queued or someone calls flush.
                if failureCount > DefaultEventDispatcher.MAX_FAILURE_COUNT {
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
                        removeStoredEvents(numEvents)

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
        
        let task = session.uploadTask(with: request, from: event.body) { (_, response, error) in
            self.logger.d(response.debugDescription)
            
            if let error = error {
                completionHandler(.failure(.eventDispatchFailed(error.localizedDescription)))
            } else {
                self.logger.d("Event Sent")
                completionHandler(.success(event.body))
            }
        }
        
        task.resume()
        
    }
    
    func applicationDidEnterBackground() {
        stopTimer()
        
        flushEvents()
    }
    
    func applicationDidBecomeActive() {
        if dataStore.count > 0 {
            startTimer()
        }
    }
    
    func startTimer() {
        // timer is activated only for iOS10+ and non-zero interval value
        guard #available(iOS 10.0, tvOS 10.0, *), timerInterval > 0 else {
            flushEvents()
            return
        }
        
        guard self.timer.property == nil else { return }
        
        DispatchQueue.main.async {
            // should check here again
            guard self.timer.property == nil else { return }
            
            self.timer.property = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { _ in
                self.dispatcher.async {
                    if self.dataStore.count > 0 {
                        self.flushEvents()
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
