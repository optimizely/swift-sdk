/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import Foundation

extension OptimizelyClient {
    
    public func setUserContext(_ user: OptimizelyUserContext) throws {
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
              
        var user = user
        
        if user.userId == nil {
            let uuidKey = "optimizely-uuid"
            var uuid = UserDefaults.standard.string(forKey: uuidKey)
            if uuid == nil {
                uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: uuidKey)
            }
            user.userId = uuid
        }
        
        guard let userId = user.userId else {
            throw OptimizelyError.generic    // TODO: refine error type
        }
        
        // bucketingId
        
        if let bucketingId = user.bucketingId {
            user.attributes[Constants.Attributes.OptimizelyBucketIdAttribute] = bucketingId
        }
        
        // userProfileUpdates
        
        if let decisionService = self.decisionService as? DefaultDecisionService {
            let requests = user.userProfileUpdates

            requests.forEach { (key, value) in
                if let key = key, let value = value {
                    decisionService.saveProfile(config: config,
                                                userId: userId,
                                                experimentKey: key,
                                                variationKey: value)
                } else {
                    // clear one or all UPS for the user
                    decisionService.removeProfile(config: config,
                                                  userId: userId,
                                                  experimentKey: key)
                }
            }
            
            user.userProfileUpdates = []
        }
        
        userContext = user
    }
    
}
