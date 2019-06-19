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
    var timerInterval:TimeInterval // every minute
    // default batchSize.
    // attempt to send events in batches with batchSize number of events combined
    var batchSize:Int
    // start trimming the front of the queue when we get to over maxQueueSize
    // TODO: implement
    var maxQueueSize: Int = 30000
    
    lazy var logger = OPTLoggerFactory.getLogger()
    var backingStore:DataStoreType
    var backingStoreName:String
    
    // for dispatching events
    let dispatcher = DispatchQueue(label: "DefaultEventDispatcherQueue")
    // using a datastore queue with a backing file
    let dataStore: DataStoreQueueStackImpl<EventForDispatch>
    // timer as a atomic property.
    var timer: AtomicProperty<Timer> = AtomicProperty<Timer>()
    
    public init(batchSize:Int = 10, backingStore:DataStoreType = .file, dataStoreName:String = "OPTEventQueue", timerInterval:TimeInterval = 60*1 ) {
        self.batchSize = batchSize > 0 ? batchSize : 1
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
        timer.performAtomic { (timer) in
            timer.invalidate()
        }
        unsubscribe()
    }
    
    open func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        dataStore.save(item: event)
        
        // TODO: use or clean up completionHandler

        setTimer()
    }
    
    open func flushEvents() {
        print("flushing" )
        // we don't remove anything off of the queue unless it is successfully sent.
        var failureCount = 0
        // if we can't batch the events because they are not from the same project or
        // are being sent to a different url.  we set the batchSizeHolder to batchSize
        // and batchSize to 1 until we have sent the last batch that couldn't be batched.
        var batchSizeHolder = 0
        // the batch send count if the events failed to be batched.
        var sendCount = 0
        
        let failedBatch = { () -> Void in
            // hold the batch size
            batchSizeHolder = self.batchSize
            // set it to 1 until the last batch that couldn't be batched is sent
            self.batchSize = 1
        }
        
        let resetBatch = { () -> Void in
            if batchSizeHolder != 0 {
                self.batchSize = batchSizeHolder
                sendCount = 0
                batchSizeHolder = 0
            }
        }
        
        // iteratively batch and remove events from queue to send
        while let eventsToSend: [EventForDispatch] = self.dataStore.removeFirstItems(count: self.batchSize) {
            let actualEventsSize = eventsToSend.count
            var eventToSend = eventsToSend.batch()
            if eventToSend != nil {
                // we merged the event and ready for batch
                // if the bacth size is not equal to the actual event size,
                // then setup the batchSizeHolder to be the size of the event.
                if actualEventsSize != self.batchSize {
                    batchSizeHolder = self.batchSize
                    self.batchSize = actualEventsSize
                    sendCount = actualEventsSize - 1
                }
            } else {
                failedBatch()
                // just send the first one and let the rest be sent until sendCount == batchSizeHolder
                eventToSend = eventsToSend.first
            }
            
            guard let event = eventToSend else {
                self.logger.e(.eventBatchFailed)
                resetBatch()
                return
            }

            // we've exhuasted our failure count.  Give up and try the next time a event
            // is queued or someone calls flush.
            if failureCount > DefaultEventDispatcher.MAX_FAILURE_COUNT {
                self.logger.e(.eventSendRetyFailed(failureCount))
                failureCount = 0
                resetBatch()
                return
            }
            
            // create closure that is called when sendEvent task completes
            let flushBatch = { (result: OptimizelyResult<Data>) -> Void in
                // on success, removes a batch of events from queue
                switch result {
                case .failure(let error):
                    self.logger.e(error.reason)
                    failureCount += 1
                case .success:
                    self.logger.d({ "Successfully sent event: \(event)" })
                    // reset failureCount
                    failureCount = 0
                    // did we have to send a batch one at a time?
                    if batchSizeHolder != 0 {
                        sendCount += 1
                        // have we sent all the events in this batch?
                        if sendCount == self.batchSize {
                            resetBatch()
                        }
                    } else {
                        // batch had batchSize items
                    }
                }
            }
            // pass in closure as parameter so delegate can access
            self.sendEvent(event: event, flushBatch: flushBatch)
        }
    }
    
    open func sendEvent(event: EventForDispatch, flushBatch: @escaping (_ result: OptimizelyResult<Data>) -> Void) {
        // instantiate URLSession delegate
        let config = URLSessionConfiguration.ephemeral
        let delegate = DefaultURLSessionDelegate(event, flushBatch)
        let session = URLSession.init(configuration: config, delegate: delegate, delegateQueue: nil)
        var request = URLRequest(url: event.url)
        request.httpMethod = "POST"
        request.httpBody = event.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // perform sendEvent task, DefaultURLSessionDelegate method called when task is complete
        let task = session.uploadTask(with: request, from: event.body)
        task.resume()
    }
    
    func applicationDidEnterBackground() {
        timer.performAtomic { (timer) in
            timer.invalidate()
        }
        timer.property = nil
        
        flushEvents()
    }
    
    func applicationDidBecomeActive() {
        if dataStore.count > 0 {
            let contents: [EventForDispatch]! = dataStore.getFirstItems(count: dataStore.count)
            print("printing contents of dataStore")
            for content in contents {
                print(content)
            }
            setTimer()
        }
    }
    
    func setTimer() {
        // timer is activated only for iOS10+ and non-zero interval value
        guard #available(iOS 10.0, tvOS 10.0, *), timerInterval > 0 else {
            flushEvents()
            return
        }
        
        guard self.timer.property == nil else { return }
        
        DispatchQueue.main.async {
            // should check here again
            guard self.timer.property == nil else { return }
            
            self.timer.property = Timer.scheduledTimer(withTimeInterval: self.timerInterval, repeats: true) { (timer) in
                self.dispatcher.async {
                    if self.dataStore.count == 0 {
                        self.timer.performAtomic() { (timer) in
                            timer.invalidate()
                        }
                        self.timer.property = nil
                    }
                    else {
                        self.flushEvents()
                    }
                }
            }
        }
    }
}
