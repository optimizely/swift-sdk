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

public class DefaultUserProfileService : OPTUserProfileService {
    static let variationId = "variation_id"
    static let userId = "user_id"
    static let experimentMap = "experiment_bucket_map"
    static let storageName = "user-profile-service"
    
    var profiles = Dictionary<String, Dictionary<String,Any>>()
    
    required public init() {
        profiles = UserDefaults.standard.dictionary(forKey: DefaultUserProfileService.storageName) as? [String : Dictionary<String, Any>] ?? Dictionary<String, Dictionary<String,Any>>()
    }
    public static func createInstance() -> OPTUserProfileService {
        return DefaultUserProfileService()
    }
    
    public func lookup(userId: String) -> Dictionary<String, Any>? {
        return profiles[userId]
    }

    public func variationId(userId: String, experimentId:String) -> String? {
        if let profile =  profiles[userId] as? Dictionary<String,Dictionary<String,Any>> {
            if let experimentMap = profile[DefaultUserProfileService.experimentMap] as? Dictionary<String,String> {
                return experimentMap[experimentId]
            }
        }
        
        return nil
    }

    public func save(userProfile: Dictionary<String, Any>) {
        profiles = userProfile as! [String : Dictionary<String, Any>]
        let defaults = UserDefaults.standard
        defaults.set(profiles, forKey: DefaultUserProfileService.storageName)
        defaults.synchronize()
        
    }
    
    public func saveProfile(userId:String, experimentId:String, variationId:String) {
        var profile = profiles[userId] ?? [String: Any]()
        var experimentMap = profile[DefaultUserProfileService.experimentMap] as? [String: [String: String]] ?? [String: [String: String]]()
        
        experimentMap[experimentId] = [DefaultUserProfileService.variationId: variationId]
        profile[DefaultUserProfileService.experimentMap] = experimentMap
        profile[DefaultUserProfileService.userId] = userId
        profiles[userId] = profile
        save(userProfile: profiles)
    }
    
}
