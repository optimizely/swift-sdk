//
//  UserProfileService.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

protocol UserProfileService {
    
    static func createInstance() -> UserProfileService

/**
 * Returns a user entity corresponding to the user ID.
 *
 * @param userId The user id to get the user entity of.
 * @returns A dictionary of the user profile details.
 **/
    func lookup(userId:String) -> Dictionary<String,Any>?

/**
 * Saves the user profile.
 *
 * @param userProfile The user profile.
 **/
    func save(userProfile:Dictionary<String,Any>)
}
