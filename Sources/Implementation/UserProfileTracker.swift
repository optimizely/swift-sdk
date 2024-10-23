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

class UserProfileTracker {
    var userId: String
    var profileUpdated: Bool = false
    var userProfileService: OPTUserProfileService
    var userProfile: UserProfile?
    var logger: OPTLogger
    
    // user-profile-service read-modify-write lock for supporting multiple clients
    static let upsRMWLock = DispatchQueue(label: "ups-rmw")
    
    init(userId: String, userProfileService: OPTUserProfileService, logger: OPTLogger) {
        self.userId = userId
        self.userProfileService = userProfileService
        self.logger = logger
    }
    
    func loadUserProfile() {
        userProfile = userProfileService.lookup(userId: userId) ?? [String: Any]()
    }
    
    func updateProfile(experiment: Experiment, variation: Variation) {
        let experimentId = experiment.id
        let variationId = variation.id
        var bucketMap = userProfile?[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
        bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
        userProfile?[UserProfileKeys.kBucketMap] = bucketMap
        userProfile?[UserProfileKeys.kUserId] = userId
        profileUpdated = true
        logger.i("Update variation of experiment \(experimentId) for user \(userId)")
    }
    
    func save() {
        UserProfileTracker.upsRMWLock.sync {
            guard profileUpdated else {
                logger.w("Profile not updated for \(userId)")
                return
            }
            
            guard let userProfile else {
                logger.e("Failed to save user profile for \(userId)")
                return
            }
            
            userProfileService.save(userProfile: userProfile)
            logger.i("Saved user profile for \(userId)")
        }
        
    }
}
