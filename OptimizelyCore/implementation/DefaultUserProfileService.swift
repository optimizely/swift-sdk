//
//  DefaultUserProfileService.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/5/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class DefaultUserProfileService : UserProfileService {
    var profile = Dictionary<String, Dictionary<String,Dictionary<String,String>>>()
    static func createInstance() -> UserProfileService {
        return DefaultUserProfileService()
    }
    
    func lookup(userId: String) -> Dictionary<String, Any>? {
        return profile[userId]
    }
    
    func save(userProfile: Dictionary<String, Any>) {
        profile = userProfile as! [String : Dictionary<String, Dictionary<String, String>>]
    }
    
    
}
