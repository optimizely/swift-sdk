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

//{
//    124170 =     {
//        "experiment_bucket_map" =         {
//            11174010269 =             {
//                "variation_id" = 11198460034;
//            };
//            11178792174 =             {
//                "variation_id" = 11192561814;
//            };
//        };
//        "user_id" = 124170;
//    };
//    133904 =     {
//        "experiment_bucket_map" =         {
//            11174010269 =             {
//                "variation_id" = 11193600046;
//            };
//            11178792174 =             {
//                "variation_id" = 11192561814;
//            };
//        };
//        "user_id" = 133904;
//    };
//    205702 =     {
//        "experiment_bucket_map" =         {
//            11174010269 =             {
//                "variation_id" = 11198460034;
//            };
//            11178792174 =             {
//                "variation_id" = 11146534908;
//            };
//        };
//        "user_id" = 205702;
//    };
//    261193 =     {
//        "experiment_bucket_map" =         {
//            11174010269 =             {
//                "variation_id" = 11193600046;
//            };
//            11178792174 =             {
//                "variation_id" = 11146534908;
//            };
//        };
//        "user_id" = 261193;
//    };
//    89086 =     {
//        "experiment_bucket_map" =         {
//            11178792174 =             {
//                "variation_id" = 11192561814;
//            };
//        };
//        "user_id" = 89086;
//    };
//}

open class DefaultUserProfileService: OPTUserProfileService {
    public typealias UserProfileData = [String: UPProfile]

    var profiles: UserProfileData?
    let lock = DispatchQueue(label: "com.optimizely.UserProfileService")
    let kStorageName = "user-profile-service"

    public required init() {
        lock.async {
            self.profiles = UserDefaults.standard.dictionary(forKey: self.kStorageName) as? UserProfileData ?? UserProfileData()

        }
    }

    open func lookup(userId: String) -> UPProfile? {
        var retVal: UPProfile?
        lock.sync {
            retVal = profiles?[userId]
        }
        return retVal
    }

    open func save(userProfile: UPProfile) {
        guard let userId = userProfile[UserProfileKeys.kUserId] as? String else { return }
            
        lock.async {
            self.profiles?[userId] = userProfile
            let defaults = UserDefaults.standard
            defaults.set(self.profiles, forKey: self.kStorageName)
            defaults.synchronize()
        }
    }
    
    open func reset(userProfiles: UserProfileData? = nil) {
        lock.async {
            self.profiles = userProfiles ?? UserProfileData()
            let defaults = UserDefaults.standard
            defaults.set(self.profiles, forKey: self.kStorageName)
            defaults.synchronize()
        }
    }
}
