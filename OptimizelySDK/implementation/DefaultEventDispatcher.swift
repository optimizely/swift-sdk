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

public class DefaultEventDispatcher : OPTEventDispatcher {
    // the max failure count.  there is no backoff timer.
    static let MAX_FAILURE_COUNT = 3
    
    // default batchSize.
    // attempt to send events in batches with batchSize number of events combined
    public var batchSize:Int = 4
    // start trimming the front of the queue when we get to over maxQueueSize
    // TODO: implement
    public var maxQueueSize:Int = 3000
    
    let logger = DefaultLogger(level: .debug)
    let dispatcher = DispatchQueue(label: "DefaultEventDispatcherQueue")
    // using a datastore queue with a backing file
    let dataStore = DataStoreQueuStackImpl<EventForDispatch>(queueStackName: "OPTEventQueue", dataStore: DataStoreFile<Array<Data>>(storeName: "OPTEventQueue"))
    let notify = DispatchGroup()
    
    public static func createInstance() -> OPTEventDispatcher? {
        return DefaultEventDispatcher()
    }
    
    public func dispatchEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        
        dataStore.save(item: event)
        
        flushEvents()
    }
    
    public func flushEvents() {
        dispatcher.async {
            // we don't remove anthing off of the queue unless it is successfully sent.
            var failureCount = 0;
            // if we can't batch the events because they are not from the same project or
            // are being sent to a different url.  we set the batchSizeHolder to batchSize
            // and batchSize to 1 until we have sent the last batch that couldn't be batched.
            var batchSizeHolder = 0
            // the batch send count if the events failed to be batched.
            var sendCount = 0
            while let eventsToSend:[EventForDispatch] = self.dataStore.getFirstItems(count:self.batchSize) {
                var eventToSend = eventsToSend.batch()
                if let _ = eventToSend {
                    // we merged the event and ready for batch
                }
                else {
                    // hold the batch size
                    batchSizeHolder = self.batchSize
                    // set it to 1 until the last batch that couldn't be batched is sent
                    self.batchSize = 1
                    // just send the first one and let the rest be sent until sendCount == batchSizeHolder
                    eventToSend = eventsToSend.first
                }
                
                guard let event = eventToSend else {
                    self.logger.log(level: .error, message: "Cannot find event to send")
                    break
                }

                // we've exhuasted our failure count.  Give up and try the next time a event
                // is queued or someone calls flush.
                if failureCount > DefaultEventDispatcher.MAX_FAILURE_COUNT {
                    self.logger.log(level: .error, message:"EventDispatcher failed to send \(failureCount) times. Backing off.")
                    failureCount = 0
                    break;
                }

                // make the send event synchronous. enter our notify
                self.notify.enter()
                self.sendEvent(event: event) { (result) -> (Void) in
                    switch result {
                    case .failure(let error):
                        self.logger.log(level: .error, message: error.localizedDescription)
                        failureCount += 1
                    case .success(_):
                        // we succeeded. remove the batch size sent.
                        if let removedItem:[EventForDispatch] = self.dataStore.removeFirstItems(count: self.batchSize) {
                            if self.batchSize == 1 && removedItem.first != event {
                                self.logger.log(level: .error, message: "Removed event different from sent event")
                            }
                            else {
                                self.logger.log(level: .debug, message: "Successfully sent event " + event.body.debugDescription)
                            }
                        }
                        else {
                            self.logger.log(level: .error, message: "Removed event nil for sent item")
                        }
                        // reset failureCount
                        failureCount = 0
                        // did we have to send a batch one at a time?
                        if batchSizeHolder != 0 {
                            sendCount += 1
                            // have we sent all the events in this batch?
                            if sendCount == batchSizeHolder {
                                self.batchSize = batchSizeHolder
                                sendCount = 0
                                batchSizeHolder = 0
                            }
                        }
                        else {
                            // batch worked
                        }
                    }
                    // our send it done.
                    self.notify.leave()
                }
                // wait for send
                self.notify.wait()
            }
        }

    }
    
    func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        let config = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: config)
        var request = URLRequest(url: event.url)
        request.httpMethod = "POST"
        request.httpBody = event.body
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = session.uploadTask(with: request, from: event.body) { (data, response, error) in
            self.logger.log(level: .debug, message: response.debugDescription)
            
            if let error = error {
                completionHandler(Result.failure(OPTEventDispatchError(description: error.localizedDescription)))
            }
            else {
                self.logger.log(level: .debug, message: "Event Sent")
                completionHandler(Result.success(event.body))
            }
        }
        
        task.resume()
        
    }
    
}
