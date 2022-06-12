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

class ODPManager {    
    let odpConfig: OptimizelyODPConfig
    
    var zaiusMgr = ZaiusApiManager()
    var segmentsCache: LRUCache<String, [String]>
    let vuidManager: VUIDManager
    var eventManager: ODPEventManager
    
    let logger = OPTLoggerFactory.getLogger()

    init(odpConfig: OptimizelyODPConfig, vuidManager: VUIDManager? = nil) {
        self.odpConfig = odpConfig
        self.eventManager = ODPEventManager()
        self.vuidManager = vuidManager ?? VUIDManager.shared
        self.segmentsCache = LRUCache<String, [String]>(size: odpConfig.segmentsCacheSize, timeoutInSecs: odpConfig.segmentsCacheTimeoutInSecs)
        
        if !self.vuidManager.isVUIDRegistered {
            eventManager.registerVUID(vuid: self.vuidManager.vuid)
        }
    }
    
    func fetchQualifiedSegments(apiKey: String?,
                                apiHost: String?,
                                userKey: String,
                                userValue: String,
                                segmentsToCheck: [String]? = nil,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        guard let odpApiKey = apiKey ?? odpConfig.apiKey else {
            completionHandler(nil, .fetchSegmentsFailed("apiKey not defined"))
            return
        }
        
        guard let odpApiHost = apiHost ?? odpConfig.apiHost else {
            completionHandler(nil, .fetchSegmentsFailed("apiHost not defined"))
            return
        }

        let cacheKey = makeCacheKey(userKey, userValue)

        let ignoreCache = options.contains(.ignoreCache)
        let resetCache = options.contains(.resetCache)
        
        if resetCache {
            segmentsCache.reset()
        }
        
        if !ignoreCache {
            if let segments = segmentsCache.lookup(key: cacheKey) {
                completionHandler(segments, nil)
                return
            }
        }
        
        zaiusMgr.fetchSegments(apiKey: odpApiKey,
                               apiHost: odpApiHost,
                               userKey: userKey,
                               userValue: userValue,
                               segmentsToCheck: segmentsToCheck) { segments, err in
            if err == nil, let segments = segments {
                if !ignoreCache {
                    self.segmentsCache.save(key: cacheKey, value: segments)
                }
            }
            
            completionHandler(segments, err)
        }
    }
    
    func identifyUser(userId: String) {
        if vuidManager.isUserRegistered(userId: userId) {
            logger.d("ODP: user (\(userId)) is registered already.")
            return
        }

        eventManager.identifyUser(vuid: vuidManager.vuid, userId: userId)
    }
    
    func updateODPConfig(apiKey: String?, apiHost: String?) {
        // updaet apiKey for fetchQualifiedSegments
        
        // flush ODPEvents
        eventManager.flush()
    }
    
}

// MARK: - Utils

extension ODPManager {
    
    func makeCacheKey(_ userKey: String, _ userValue: String) -> String {
        return userKey + "-$-" + userValue
    }
    
}
