/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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

struct UserProfileKeys {
    static let kBucketMap = "experiment_bucket_map"
    static let kVariationId = "variation_id"
    static let kUserId = "user_id"
}

@objc public protocol OPTUserProfileService {
    
    typealias UPProfile = [String: Any]   // {"experiment_bucket_map", "user_id"}
    typealias UPBucketMap = [String: UPExperimentMap]
    typealias UPExperimentMap = [String: String]
    
    init()

    /**
     Returns a user entity corresponding to the user ID.
     - Parameter userId: The user id to get the user entity of.
     - Returns: A dictionary of the user profile details.
     **/
    func lookup(userId: String) -> UPProfile?

    /**
     Saves the user profile.
     - Parameter userProfile: The user profile.
     **/
    func save(userProfile: UPProfile)
    
}
