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
//
//  UserProfileService.swift
//  OptimizelySDK
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

import Foundation

public protocol OPTUserProfileService {
    
    init()

    /**
     Returns a user entity corresponding to the user ID.
     - Parameter userId: The user id to get the user entity of.
     - Returns: A dictionary of the user profile details.
     **/
    func lookup(userId:String) -> Dictionary<String,Any>?

    /**
     Saves the user profile.
     - Parameter userProfile: The user profile.
     **/
    func save(userProfile:Dictionary<String,Any>)
 
    /**
    Get a variation id for a experiment id for a user
    - Parameter userId: The user id to lookup the map.
     - Parameter experimentId: experiment id to lookup variation id in the "experiment_bucket_map"
     - Returns: the variation id if one is saved for this user.
    **/
    func variationId(userId: String, experimentId:String) -> String?
    
    /**
     Save entry for a user in the experiment_bucket_map for experiment.
     - Parameter userId: The user id to lookup the map.
     - Parameter experimentId: experiment id to lookup variation id in the "experiment_bucket_map"
     - Parameter variationId: variation id that the user was bucketed into for the experiment.
     **/
    func saveProfile(userId:String, experimentId:String, variationId:String)
}
