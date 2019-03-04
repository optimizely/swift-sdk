//
//  Project.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

protocol ProjectProtocol {
    func evaluateAudience(audienceId: String, attributes: [String: Any]?) throws -> Bool
}

struct Project: Codable, Equatable {
    
    // V2
    var version: String
    var projectId: String
    var experiments: [Experiment]
    var audiences: [Audience]
    var groups: [Group]
    var attributes: [Attribute]
    var accountId: String
    var events: [Event]
    var revision: String
    // V3
    // TODO: [Jae] exist test files missing this. not requried?
    //       Should return this in the event (what value return if missing datafile
    var anonymizeIP: Bool?
    // TODO: [Jae] exist test files missing this. not requried?
    var variables: [FeatureVariable]?
    // V4
    // TODO: [Jae] exist test files missing this. not requried?
    var rollouts: [Rollout]?
    // TODO: [Jae] exist test files missing this. not requried?
    var typedAudiences: [Audience]?
    // TODO: [Jae] exist test files missing this. not requried?
    var featureFlags: [FeatureFlag]?
    // TODO: [Jae] exist test files missing this. not requried?
    var botFiltering: Bool?
    
}

extension Project: ProjectProtocol {
    
    func evaluateAudience(audienceId: String, attributes: [String: Any]?) throws -> Bool {
        let audienceMatch = typedAudiences?.filter{$0.id == audienceId}.first ??
                            audiences.filter{$0.id == audienceId}.first
        
        guard let audience = audienceMatch else {
            throw OptimizelyError.conditionNoMatchingAudience(audienceId)
        }
        
        return try audience.evaluate(project: self, attributes: attributes)
    }
    
}
