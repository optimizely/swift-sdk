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

class ODPSegmentManager {    
    let odpConfig: OptimizelyODPConfig
    let zaiusMgr = ZaiusGraphQLApiManager()
    let segmentsCache: LRUCache<String, [String]>
    
    let logger = OPTLoggerFactory.getLogger()

    init(odpConfig: OptimizelyODPConfig) {
        self.odpConfig = odpConfig
        self.segmentsCache = LRUCache<String, [String]>(size: odpConfig.segmentsCacheSize,
                                                        timeoutInSecs: odpConfig.segmentsCacheTimeoutInSecs)
    }
    
    func fetchQualifiedSegments(userKey: String,
                                userValue: String,
                                segmentsToCheck: [String]? = nil,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        guard let odpApiKey = odpConfig.apiKey else {
            completionHandler(nil, .fetchSegmentsFailed("apiKey not defined"))
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
                               apiHost: odpConfig.apiHost,
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
    
}

// MARK: - Utils

extension ODPSegmentManager {
    
    func makeCacheKey(_ userKey: String, _ userValue: String) -> String {
        return userKey + "-$-" + userValue
    }
    
}
