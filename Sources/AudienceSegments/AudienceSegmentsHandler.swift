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
    var zaiusMgr = ZaiusApiManager()
    var segmentsCache: LRUCache<String, [String]>
    let logger = OPTLoggerFactory.getLogger()
    
    let odpConfig: OptimizelyODPConfig
    let vuidManager: VUIDManager
        
    init(odpConfig: OptimizelyODPConfig, vuidManager: VUIDManager? = nil) {
        self.odpConfig = odpConfig
        self.segmentsCache = LRUCache<String, [String]>(size: odpConfig.segmentsCacheSize, timeoutInSecs: odpConfig.segmentsCacheTimeoutInSecs)
        self.vuidManager = vuidManager ?? VUIDManager.shared
        
        self.registerVUID(apiKey: nil, apiHost: nil) { error in
            // stay silent for auto register on app start
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
    
    // MARK: - VUID
    
    
    // TODO: call this again after project config changed with a new datafile.


    public func registerVUID(apiKey: String?,
                             apiHost: String?,
                             completionHandler: @escaping (OptimizelyError?) -> Void) {
        if isVUIDRegistered {
            logger.d("ODP: vuid is registered already.")
            completionHandler(nil)
            return
        }

        guard let odpApiKey = apiKey ?? odpConfig.apiKey else {
            completionHandler(.odpEventFailed("apiKey not defined"))
            return
        }
        
        guard let odpApiHost = apiHost ?? odpConfig.apiHost else {
            completionHandler(.odpEventFailed("apiHost not defined"))
            return
        }

        let vuid = self.vuidManager.newVuid

        let identifiers = [
            "vuid": vuid
        ]
        
        zaiusMgr.sendODPEvent(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              identifiers: identifiers,
                              kind: "experimentation:client_initialized") { error in
            if error == nil {
                self.logger.d("ODP: vuid registered (\(vuid)) successfully")
                self.vuidManager.updateRegisteredVUID(vuid)
            }
            completionHandler(error)
        }
    }
    
    public func identifyUser(apiKey: String?,
                             apiHost: String?,
                             userId: String,
                             completionHandler: @escaping (OptimizelyError?) -> Void) {
        if isUserRegistered(userId: userId) {
            logger.d("ODP: user (\(userId)) is registered already.")
            completionHandler(nil)
            return
        }

        guard let odpApiKey = apiKey ?? odpConfig.apiKey else {
            completionHandler(.odpEventFailed("apiKey not defined"))
            return
        }
        
        guard let odpApiHost = apiHost ?? odpConfig.apiHost else {
            completionHandler(.odpEventFailed("apiHost not defined"))
            return
        }

        guard let vuid = vuidManager.vuid else {
            completionHandler(.odpEventFailed("invalid vuid for identify"))
            return
        }
        
        let identifiers = [
            "vuid": vuid,
            "fs_user_id": userId
        ]

        zaiusMgr.sendODPEvent(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              identifiers: identifiers,
                              kind: "experimentation:identified") { error in
            if error == nil {
                self.logger.d("ODP: idenfier (\(userId)) added successfully")
                self.vuidManager.updateRegisteredUsers(userId: userId)
            }
            completionHandler(error)
        }
    }
    
    var isVUIDRegistered: Bool {
        return vuidManager.isVUIDRegistered
    }
    
    func isUserRegistered(userId: String) -> Bool {
        return vuidManager.isUserRegistered(userId: userId)
    }

}

// MARK: - Utils

extension ODPManager {
    
    func makeCacheKey(_ userKey: String, _ userValue: String) -> String {
        return userKey + "-$-" + userValue
    }
    
}
