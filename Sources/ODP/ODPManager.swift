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
    
    let vuidManager: VUIDManager
    let segmentManager: ODPSegmentManager
    let eventManager: ODPEventManager
    
    let logger = OPTLoggerFactory.getLogger()

    init(odpConfig: OptimizelyODPConfig,
         vuidManager: VUIDManager? = nil,
         segmentManager: ODPSegmentManager? = nil,
         eventManager: ODPEventManager? = nil) {
        self.odpConfig = odpConfig
        self.vuidManager = vuidManager ?? VUIDManager()
        self.segmentManager = segmentManager ?? ODPSegmentManager(odpConfig: odpConfig)
        self.eventManager = eventManager ?? ODPEventManager(odpConfig: odpConfig)
        
        if !self.vuidManager.isVUIDRegistered {
            self.eventManager.registerVUID(vuid: self.vuidManager.vuid)
        }
    }
    
    func fetchQualifiedSegments(userId: String,
                                segmentsToCheck: [String]? = nil,
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
        if vuidManager.isUserRegistered(userId: userId) {
            logger.d("ODP: user (\(userId)) is registered already.")
            return
        }

        eventManager.identifyUser(vuid: vuidManager.vuid, userId: userId)
    }
    
    func updateODPConfig(apiKey: String?, apiHost: String?) {
        guard let apiKey = apiKey, let apiHost = apiHost else {
            logger.w("ODP: invalid apiKey or apiHost")
            return
        }
        
        odpConfig.apiKey = apiKey
        odpConfig.apiHost = apiHost

        // flush all ODP events waiting for apiKey
        eventManager.flushEvents()
    }
    
    var vuid: String {
        return vuidManager.vuid
    }
    
}
