//
// Copyright 2022-2023, Optimizely, Inc. and contributors 
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

class OdpManager {
    var enabled: Bool
    var vuidManager: OdpVuidManager

    var odpConfig: OdpConfig!
    var segmentManager: OdpSegmentManager!
    var eventManager: OdpEventManager!
    
    let logger = OPTLoggerFactory.getLogger()

    var vuid: String {
        return vuidManager.vuid
    }
    
    /// OdpManager init
    /// - Parameters:
    ///   - sdkKey: datafile sdkKey
    ///   - disable: disable ODP
    ///   - cacheSize: segment cache size
    ///   - cacheTimeoutInSecs: segment cache timeout
    ///   - timeoutForSegmentFetchInSecs: timeout for segment fetch
    ///   - timeoutForEventDispatchInSecs: timeout for event dispatch
    ///   - segmentManager: ODPSegmentManager
    ///   - eventManager: ODPEventManager
    init(sdkKey: String,
         disable: Bool,
         cacheSize: Int,
         cacheTimeoutInSecs: Int,
         timeoutForSegmentFetchInSecs: Int? = nil,
         timeoutForEventDispatchInSecs: Int? = nil,
         segmentManager: OdpSegmentManager? = nil,
         eventManager: OdpEventManager? = nil) {
        
        self.enabled = !disable
        self.vuidManager = OdpVuidManager.shared
        
        guard enabled else {
            logger.i(.odpNotEnabled)
            return
        }
        
        self.segmentManager = segmentManager ?? OdpSegmentManager(cacheSize: cacheSize,
                                                                  cacheTimeoutInSecs: cacheTimeoutInSecs,
                                                                  resourceTimeoutInSecs: timeoutForSegmentFetchInSecs)
        self.eventManager = eventManager ?? OdpEventManager(sdkKey: sdkKey,
                                                            resourceTimeoutInSecs: timeoutForEventDispatchInSecs)        
        self.odpConfig = OdpConfig()
        self.segmentManager.odpConfig = odpConfig
        self.eventManager.odpConfig = odpConfig
        
        self.eventManager.registerVUID(vuid: self.vuidManager.vuid)
    }
    
    func fetchQualifiedSegments(userId: String,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        guard enabled else {
            completionHandler(nil, .odpNotEnabled)
            return
        }
        
        let userKey = OdpVuidManager.isVuid(userId) ? Constants.ODP.keyForVuid : Constants.ODP.keyForUserId
        let userValue = userId
    
        segmentManager.fetchQualifiedSegments(userKey: userKey,
                                               userValue: userValue,
                                               options: options,
                                               completionHandler: completionHandler)
    }
    
    func identifyUser(userId: String) {
        guard enabled else {
            logger.d("ODP identify event is not dispatched (ODP disabled).")
            return
        }
        
        guard odpConfig.eventQueueingAllowed else {
            logger.d("ODP identify event is not dispatched (ODP not integrated).")
            return
        }

        var vuid = vuidManager.vuid
        var fsUserId: String? = userId
        if OdpVuidManager.isVuid(userId) {
            // overwrite if userId is vuid (when userContext is created with vuid)
            vuid = userId
            fsUserId = nil
        }
        
        eventManager.identifyUser(vuid: vuid, userId: fsUserId)
    }
    
    /// Send an event to the ODP server.
    ///
    /// - Parameters:
    ///   - type: the event type.
    ///   - action: the event action name.
    ///   - identifiers: a dictionary for identifiers.
    ///   - data: a dictionary for associated data. The default event data will be added to this data before sending to the ODP server.
    /// - Throws: `OptimizelyError` if error is detected
    func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any?]) throws {
        guard enabled else { throw OptimizelyError.odpNotEnabled }
        guard odpConfig.eventQueueingAllowed else { throw OptimizelyError.odpNotIntegrated }
        guard eventManager.isDataValidType(data) else { throw OptimizelyError.odpInvalidData }
        
        var identifiersWithVuid = identifiers
        if identifiers[Constants.ODP.keyForVuid] == nil {
            identifiersWithVuid[Constants.ODP.keyForVuid] = vuidManager.vuid
        }
        
        eventManager.sendEvent(type: type, action: action, identifiers: identifiersWithVuid, data: data)
    }
    
    func updateOdpConfig(apiKey: String?, apiHost: String?, segmentsToCheck: [String]) {
        guard enabled else { return }

        // flush old events using old odp publicKey (if exists) before updating odp key.
        // NOTE: It should be rare but possible that odp public key is changed for the same datafile (sdkKey).
        //       Try to send all old events with the previous public key.
        //       If it fails to flush all the old events here (network error), remaning events will be discarded.
        eventManager.flush()

        let configChanged = odpConfig.update(apiKey: apiKey,
                                             apiHost: apiHost,
                                             segmentsToCheck: segmentsToCheck)
        if configChanged {
            // reset segments cache when odp integration or segmentsToCheck are changed
            segmentManager.reset()
        }
    }
        
}

extension OdpManager: BackgroundingCallbacks {
    func applicationDidEnterBackground() {
        guard enabled else { return }

        eventManager.flush()
    }
    
    func applicationDidBecomeActive() {
        guard enabled else { return }

        // no actions here for now
    }
}
