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

class OdpManager {
    let enabled: Bool
    let odpConfig: OdpConfig
    
    let vuidManager: OdpVuidManager
    var segmentManager: OdpSegmentManager?
    var eventManager: OdpEventManager?
    
    let logger = OPTLoggerFactory.getLogger()

    var vuid: String {
        return vuidManager.vuid
    }
    
    init(sdkKey: String,
         enable: Bool,
         cacheSize: Int,
         cacheTimeoutInSecs: Int,
         segmentManager: OdpSegmentManager? = nil,
         eventManager: OdpEventManager? = nil) {
        
        self.enabled = enable
        self.odpConfig = OdpConfig()
        self.vuidManager = OdpVuidManager.shared
        
        if enable {
            self.segmentManager = segmentManager ?? OdpSegmentManager(cacheSize: cacheSize,
                                                                      cacheTimeoutInSecs: cacheTimeoutInSecs,
                                                                      odpConfig: odpConfig)
            self.eventManager = eventManager ?? OdpEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
            
            self.eventManager?.registerVUID(vuid: self.vuidManager.vuid)
        }
    }
    
    func fetchQualifiedSegments(userId: String,
                                segmentsToCheck: [String],
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        guard enabled else {
            completionHandler(nil, .odpNotEnabled)
            return
        }
        
        let userKey = vuidManager.isVuid(visitorId: userId) ? Constants.ODP.keyForVuid : Constants.ODP.keyForUserId
        let userValue = userId
    
        segmentManager?.fetchQualifiedSegments(userKey: userKey,
                                               userValue: userValue,
                                               segmentsToCheck: segmentsToCheck,
                                               options: options,
                                               completionHandler: completionHandler)
    }
    
    func identifyUser(userId: String) {
        guard enabled else {
            logger.d("ODP is not enabled.")
            return
        }

        eventManager?.identifyUser(vuid: vuidManager.vuid, userId: userId)
    }
    
    func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any]) {
        guard enabled else {
            logger.d("ODP is not enabled.")
            return
        }

        var identifiersWithVuid = identifiers
        if identifiers[Constants.ODP.keyForVuid] == nil {
            identifiersWithVuid[Constants.ODP.keyForVuid] = vuidManager.vuid
        }
        
        eventManager?.sendEvent(type: type, action: action, identifiers: identifiersWithVuid, data: data)
    }
    
    func updateOdpConfig(apiKey: String?, apiHost: String?) {
        guard enabled else {
            return
        }

        odpConfig.update(apiKey: apiKey, apiHost: apiHost)
        eventManager?.flush()
    }
    
}
