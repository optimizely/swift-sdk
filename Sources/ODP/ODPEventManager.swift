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

class ODPEventManager {
    let odpConfig: OptimizelyODPConfig
    let zaiusMgr: ZaiusRestApiManager
    
    let maxQueueSize = 100
    let maxFailureCount = 3
    let queueLock: DispatchQueue
    let eventQueue: DataStoreQueueStackImpl<ODPEvent>

    let logger = OPTLoggerFactory.getLogger()

    init(sdkKey: String, odpConfig: OptimizelyODPConfig) {
        self.odpConfig = odpConfig
        self.zaiusMgr = ZaiusRestApiManager()
        
        self.queueLock = DispatchQueue(label: "event")
        
        // a separate event queue for each sdkKey (which may have own ODP public key)
        let storeName = "OPDEvent-\(sdkKey)"
        self.eventQueue = DataStoreQueueStackImpl<ODPEvent>(queueStackName: "odp",
                                                            dataStore: DataStoreFile<[Data]>(storeName: storeName))
    }
    
    // MARK: - events
    
    func registerVUID(vuid: String) {
        let event = ODPEvent(type: Constants.ODP.eventType,
                             action: "client_initialized",
                             identifiers: [
                                Constants.ODP.keyForVuid: vuid
                             ],
                             data: addCommonEventData())
        dispatch(event)
    }
    
    func identifyUser(vuid: String, userId: String) {
        let event = ODPEvent(type: Constants.ODP.eventType,
                             action: "identified",
                             identifiers: [
                                Constants.ODP.keyForVuid: vuid,
                                Constants.ODP.keyForUserId: userId
                             ],
                             data: addCommonEventData())
        dispatch(event)
    }
        
    func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any]) {
        let event = ODPEvent(type: type,
                             action: action,
                             identifiers: identifiers,
                             data: addCommonEventData(data))
        dispatch(event)
    }
    
    func dispatch(_ event: ODPEvent) {
        guard eventQueue.count < maxQueueSize else {
            let error = OptimizelyError.eventDispatchFailed("ODP EventQueue is full")
            self.logger.e(error)
            return
        }

        eventQueue.save(item: event)
        flush()
    }
    
    func addCommonEventData(_ customData: [String: Any] = [:]) -> [String: Any] {
        let commonData = [
            "source": "swift-sdk"
            // others?
        ]
        
        var data = customData
        data.merge(commonData) { (current, _) in current }   // keep custom data if conflicts
        return data
    }
        
    func flush() {
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
