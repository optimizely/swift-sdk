//
//  DefaultUserProfileService.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/5/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

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

class DefaultUserProfileService : UserProfileService {
    static let variationId = "variation_id"
    static let userId = "user_id"
    static let experimentMap = "experiment_bucket_map"
    static let storageName = "user-profile-service"
    
    var profiles = Dictionary<String, Dictionary<String,Any>>()
    
    init() {
        profiles = UserDefaults.standard.dictionary(forKey: DefaultUserProfileService.storageName) as? [String : Dictionary<String, Any>] ?? Dictionary<String, Dictionary<String,Any>>()
    }
    static func createInstance() -> UserProfileService {
        return DefaultUserProfileService()
    }
    
    func lookup(userId: String) -> Dictionary<String, Any>? {
        return profiles[userId]
    }

    func variationId(userId: String, experimentId:String) -> String? {
        if let profile =  profiles[userId] as? Dictionary<String,Dictionary<String,Any>> {
            if let experimentMap = profile[DefaultUserProfileService.experimentMap] as? Dictionary<String,String> {
                return experimentMap[experimentId]
            }
        }
        
        return nil
    }

    func save(userProfile: Dictionary<String, Any>) {
        profiles = userProfile as! [String : Dictionary<String, Any>]
        let defaults = UserDefaults.standard
        defaults.setPersistentDomain(profiles, forName: DefaultUserProfileService.storageName)
        defaults.synchronize()
        
    }
    
    func saveProfile(userId:String, experimentId:String, variationId:String) {
        if var profile =  profiles[userId] {
            if var experimentMap = profile[DefaultUserProfileService.experimentMap] as? Dictionary<String,String> {
                experimentMap[experimentId] = variationId
            }
            else {
                profile[DefaultUserProfileService.userId] = userId
                var experimentMap = Dictionary<String,String>()
                experimentMap[experimentId] = variationId
                profile[DefaultUserProfileService.experimentMap] = experimentMap
                profiles[userId] = profile
                save(userProfile: profiles)
            }
        }
        else {
            var profile = Dictionary<String,Any>()
            var experimentMap = Dictionary<String,String>()
            experimentMap[experimentId] = variationId
            profile[DefaultUserProfileService.experimentMap] = experimentMap
            profile[DefaultUserProfileService.userId] = userId
            profiles[userId] = profile
            save(userProfile: profiles)
        }
        
    }
    
    
}
