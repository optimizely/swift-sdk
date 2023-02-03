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

public class OdpSegmentManager {    
    var odpConfig = OdpConfig()
    var segmentsCache: LruCache<String, [String]>
    var apiMgr: OdpSegmentApiManager
    
    let logger = OPTLoggerFactory.getLogger()
    
    /// OdpSegmentManager init
    /// - Parameters:
    ///   - cacheSize: segment cache size
    ///   - cacheTimeoutInSecs: segment cache timeout
    ///   - apiManager: OdpSegmentApiManager
    ///   - resourceTimeoutInSecs: timeout for segment fetch
    public init(cacheSize: Int,
                cacheTimeoutInSecs: Int,
                apiManager: OdpSegmentApiManager? = nil,
                resourceTimeoutInSecs: Int? = nil) {
        self.odpConfig = odpConfig ?? OdpConfig()
        self.apiMgr = apiManager ?? OdpSegmentApiManager(timeout: resourceTimeoutInSecs)
        
        self.segmentsCache = LruCache<String, [String]>(size: cacheSize,
                                                        timeoutInSecs: cacheTimeoutInSecs)
    }
    
    func fetchQualifiedSegments(userKey: String,
                                userValue: String,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        guard let odpApiKey = odpConfig.apiKey, let odpApiHost = odpConfig.apiHost else {
            completionHandler(nil, .fetchSegmentsFailed("apiKey/apiHost not defined"))
            return
        }
        
        // empty segmentsToCheck (no ODP audiences found in datafile) is not an error. return immediately without checking with the ODP server.
        let segmentsToCheck = odpConfig.segmentsToCheck
        guard segmentsToCheck.count > 0 else {
            completionHandler([], nil)
            return
        }
        
        let cacheKey = makeCacheKey(userKey, userValue)
        
        let ignoreCache = options.contains(.ignoreCache)
        let resetCache = options.contains(.resetCache)
        
        if resetCache {
            reset()
        }
        
        if !ignoreCache {
            if let segments = segmentsCache.lookup(key: cacheKey) {
                completionHandler(segments, nil)
                return
            }
        }
        
        apiMgr.fetchSegments(apiKey: odpApiKey,
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
    
    func reset() {
        segmentsCache.reset()
    }
}

// MARK: - Utils

extension OdpSegmentManager {
    
    func makeCacheKey(_ userKey: String, _ userValue: String) -> String {
        return userKey + "-$-" + userValue
    }
    
}
