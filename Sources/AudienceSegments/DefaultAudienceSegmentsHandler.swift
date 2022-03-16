//
// Copyright 2021, Optimizely, Inc. and contributors 
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

class DefaultAudienceSegmentsHandler: OPTAudienceSegmentsHandler {
    
    let testApiKey = "W4WzcEs-ABgXorzY7h1LCQ"
    let testUserId = "d66a9d81923d4d2f99d8f64338976322"
    
    let zaiusMgr = ZaiusApiManager()
    let cache = SegmentsCache()

    func fetchQualifiedSegments(apiKey: String, user: OptimizelyUserContext, completionHandler: @escaping ([String]?, Error?) -> Void) {
        let apiKey = testApiKey
        let userId = testUserId
        
        zaiusMgr.fetch(apiKey: apiKey, userId: userId) { segments, err in
            completionHandler(segments, err)
        }
    }
    
}
