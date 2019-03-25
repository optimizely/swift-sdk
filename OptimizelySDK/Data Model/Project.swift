//
//  Project.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

protocol ProjectProtocol {
    func evaluateAudience(audienceId: String, attributes: OptimizelyAttributes?) throws -> Bool
}

//[REF]: datafile schema
//       https://github.com/optimizely/optimizely/blob/43454b726a2a8aab7dcd953999cf8e1902b09d4d/src/www/services/datafile_generator/schema.json

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
    var anonymizeIP: Bool
    // V4
    var rollouts: [Rollout]
    var typedAudiences: [Audience]?
    var featureFlags: [FeatureFlag]
    var botFiltering: Bool?
}

extension Project: ProjectProtocol {
    
    func evaluateAudience(audienceId: String, attributes: OptimizelyAttributes?) throws -> Bool {
        let audienceMatch = typedAudiences?.filter{$0.id == audienceId}.first ??
                            audiences.filter{$0.id == audienceId}.first
        
        guard let audience = audienceMatch else {
            throw OptimizelyError.conditionNoMatchingAudience(audienceId)
        }
        
        return try audience.evaluate(project: self, attributes: attributes)
    }
    
}
