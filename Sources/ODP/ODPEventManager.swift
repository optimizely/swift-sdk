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


struct ODPEvent: Codable {
    let type: String
    let action: String
    // TODO: change to [String: Any] to support arbitary value types
    let identifiers: [String: String]
    let data: [String: String]
    
    //let data_source = "fullstack:swift-sdk"
}

class ODPEventManager {
    let odpConfig: OptimizelyODPConfig
    let zaiusMgr: ZaiusRestApiManager
    
    let maxQueueSize = 100
    let maxFailureCount = 3
    let queueLock: DispatchQueue
    let eventQueue: DataStoreQueueStackImpl<ODPEvent>

    let logger = OPTLoggerFactory.getLogger()

    init(odpConfig: OptimizelyODPConfig) {
        self.odpConfig = odpConfig
        self.zaiusMgr = ZaiusRestApiManager()
        
        self.queueLock = DispatchQueue(label: "event")
        self.eventQueue = DataStoreQueueStackImpl<ODPEvent>(queueStackName: "odp",
                                                            dataStore: DataStoreFile<[Data]>(storeName: "OPT-ODPEvent"))
    }
    
    // MARK: - ODP API
    
    func registerVUID(vuid: String) {
        let event = ODPEvent(type: "experimentation",
                             action: "client_initialized",
                             identifiers: [
                                Constants.ODP.keyForVuid: vuid
                             ],
                             data: [:])
        dispatchEvent(event)
    }
    
    func identifyUser(vuid: String, userId: String) {
        let event = ODPEvent(type: "experimentation",
                             action: "identified",
                             identifiers: [
                                Constants.ODP.keyForVuid: vuid,
                                Constants.ODP.keyForUserId: userId
                             ],
                             data: [:])
        dispatchEvent(event)
    }
    
    func dispatchEvent(_ event: ODPEvent) {
        guard eventQueue.count < maxQueueSize else {
            let error = OptimizelyError.eventDispatchFailed("ODP EventQueue is full")
            self.logger.e(error)
            return
        }
        
        eventQueue.save(item: event)
        flushEvents()
    }
    
    // MARK: - Events
    
    func flushEvents() {
        guard let odpApiKey = odpConfig.apiKey else {
            logger.d("ODP: event cannot be dispatched since apiKey not defined")
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
            
            // notify group used to ensure that the sendEvent is synchronous.
            // used in flushEvents
            let notify = DispatchGroup()

            let maxBatchEvents = 10
            var failureCount = 0

            while let events: [ODPEvent] = self.eventQueue.getFirstItems(count: maxBatchEvents) {
                let numEvents = events.count

                // we've exhuasted our failure count.  Give up and try the next time a event
                // is queued or someone calls flush (changed to >= so that retried exactly "maxFailureCount" times).
                if failureCount >= self.maxFailureCount {
                    self.logger.e("ODP: Failed to send event with max retried")
                    break
                }
                
                // make the send event synchronous. enter our notify
                notify.enter()
                
                self.zaiusMgr.sendODPEvents(apiKey: odpApiKey,
                                            apiHost: self.odpConfig.apiHost,
                                            events: events) { error in
                    if error != nil {
                        self.logger.e(error!.reason)
                        failureCount += 1
                    } else {
                        removeStoredEvents(num: numEvents)
                        failureCount = 0
                    }
                    
                    // our send is done.
                    notify.leave()
                }
                
                // wait for send
                notify.wait()
            }
        }
    }
    
}
