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

public class DefaultAudienceSegmentsHandler: OPTAudienceSegmentsHandler {
    // configurable size + timeout
    public static var cacheMaxSize = 100
    public static var cacheTimeoutInSecs = 10*60

    var zaiusMgr = ZaiusApiManager()
    var segmentsCache = LRUCache<String, [String]>(size: DefaultAudienceSegmentsHandler.cacheMaxSize,
                                                   timeoutInSecs: DefaultAudienceSegmentsHandler.cacheTimeoutInSecs)
    let logger = OPTLoggerFactory.getLogger()
    
    func fetchQualifiedSegments(apiKey: String,
                                userKey: String,
                                userValue: String,
                                segmentsToCheck: [String]? = nil,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        let cacheKey = cacheKey(userKey, userValue)

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
        
        zaiusMgr.fetch(apiKey: apiKey,
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

extension DefaultAudienceSegmentsHandler {
    
    func cacheKey(_ userKey: String, _ userValue: String) -> String {
        return userKey + "-$-" + userValue
    }
    
}
