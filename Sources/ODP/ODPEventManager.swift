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

class ODPEventManager {
    let odpConfig: OptimizelyODPConfig
    let zaiusMgr: ZaiusRestApiManager
    
    let maxQueueSize = 100
    let maxFailureCount = 3
    let queueLock: DispatchQueue
    let eventQueue: DataStoreQueueStackImpl<ODPEvent>

    let logger = OPTLoggerFactory.getLogger()

    init(sdkKey: String, odpConfig: OptimizelyODPConfig, apiManager: ZaiusRestApiManager? = nil) {
        self.odpConfig = odpConfig
        self.zaiusMgr = apiManager ?? ZaiusRestApiManager()
        
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
    
    func addCommonEventData(_ customData: [String: Any] = [:]) -> [String: Any] {
        var data: [String: Any] = [
            "idempotence_id": UUID().uuidString,
            
            "data_source_type": "sdk",
            "data_source": Utils.swiftSdkClientName,        // "swift-sdk"
            "data_source_version": Utils.sdkVersion,        // "3.10.2"
            
            // [optional] client sdks only
            "os": Utils.os,                                 // ("iOS", "Android", "Mac OS", "Windows", "Linux", ...)
            "os_version": Utils.osVersion,                  // "13.2", ...
            "device_type": Utils.deviceType,                // fixed set = ("Phone", "Tablet", "Smart TV", “PC”, "Other")
            "model": Utils.deviceModel                      // ("iPhone 12", "iPad 2", "Pixel 2", "SM-A515F", ...)

            // [optional]
            // "data_source_instance": <sub>,               // if need subtypes of data_source
        ]
        
        data.merge(customData) { (_, custom) in custom }    // keep custom data if conflicts
        return data
    }
        
    // MARK: - dispatch
    
    func dispatch(_ event: ODPEvent) {
        guard eventQueue.count < maxQueueSize else {
            let error = OptimizelyError.eventDispatchFailed("ODP EventQueue is full")
            self.logger.e(error)
            return
        }

        eventQueue.save(item: event)
        flush()
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
                    defer {
                        notify.leave()  // our send is done.
                    }
                    
                    if let error = error {
                        self.logger.e(error.reason)
                        
                        // retry only if needed (non-permanent)
                        if case .odpEventFailed(_, let canRetry) = error {
                            if canRetry {
                                failureCount += 1
                                return
                            } else {
                                // permanent errors (400 response or invalid events, etc)
                                // discard these events so not they do not block following valid events
                            }
                        }
                    }
                        
                    removeStoredEvents(num: numEvents)
                    failureCount = 0
                }
                
                notify.wait()  // wait for send completed
            }
        }
    }
    
}
