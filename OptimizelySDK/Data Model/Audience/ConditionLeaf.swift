//
//  ConditionLeaf.swift
//  OptimizelySwiftSDK-iOS
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

enum ConditionLeaf: Codable, Equatable {
    case audienceId(String)
    case attribute(UserAttribute)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self = .audienceId(value)
            return
        }
        
        do {
            let value = try container.decode(UserAttribute.self)
            self = .attribute(value)
            return
        } catch {
                
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode ConditionLeaf"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .audienceId(let id):
            try container.encode(id)
        case .attribute(let userAttribute):
            try container.encode(userAttribute)
        }
    }
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) throws -> Bool {
        switch self {
        case .audienceId(let id):
            guard let project = project else {
                throw OptimizelyError.conditionCannotBeEvaluated("audienceId: \(id)")
            }
            
            return try project.evaluateAudience(audienceId: id, attributes: attributes)
        case .attribute(let userAttribute):
            return try userAttribute.evaluate(attributes: attributes)
        }
    }
    
}
