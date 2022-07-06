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

class ODPManager {
    let odpConfig: OptimizelyODPConfig
    
    let vuidManager: ODPVUIDManager
    let segmentManager: ODPSegmentManager
    let eventManager: ODPEventManager
    
    let logger = OPTLoggerFactory.getLogger()

    init(sdkKey: String,
         odpConfig: OptimizelyODPConfig,
         vuidManager: ODPVUIDManager? = nil,
         segmentManager: ODPSegmentManager? = nil,
         eventManager: ODPEventManager? = nil) {
        self.odpConfig = odpConfig
        self.vuidManager = vuidManager ?? ODPVUIDManager.shared
        self.segmentManager = segmentManager ?? ODPSegmentManager(odpConfig: odpConfig)
        self.eventManager = eventManager ?? ODPEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
        
        self.eventManager.registerVUID(vuid: self.vuidManager.vuid)
    }
    
    func fetchQualifiedSegments(userId: String,
                                segmentsToCheck: [String],
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        let userKey = vuidManager.isVuid(visitorId: userId) ? Constants.ODP.keyForVuid : Constants.ODP.keyForUserId
        let userValue = userId
    
        segmentManager.fetchQualifiedSegments(userKey: userKey,
                                              userValue: userValue,
                                              segmentsToCheck: segmentsToCheck,
                                              options: options,
                                              completionHandler: completionHandler)
    }
    
    func identifyUser(userId: String) {
        eventManager.identifyUser(vuid: vuidManager.vuid, userId: userId)
    }
    
    func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any]) {
        var identifiersWithVuid = identifiers
        if identifiers[Constants.ODP.keyForVuid] == nil {
            identifiersWithVuid[Constants.ODP.keyForVuid] = vuidManager.vuid
        }
        
        eventManager.sendEvent(type: type, action: action, identifiers: identifiersWithVuid, data: data)
    }
    
    func updateODPConfig(apiKey: String?, apiHost: String?) {
        odpConfig.update(apiKey: apiKey, apiHost: apiHost)
        eventManager.flush()
    }
    
    var vuid: String {
        return vuidManager.vuid
    }
    
}
