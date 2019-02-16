//
//  AudienceCondition.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

enum LogicalOp: String, Codable {
    case and
    case or
    case not
}

enum AudienceCondition: Codable, Equatable {
    case logicalOp(LogicalOp)
    case audienceId(String)
    case array([AudienceCondition])
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode(LogicalOp.self) {
                self = .logicalOp(value)
                return
            }
            
            if let value = try? container.decode(String.self) {
                self = .audienceId(value)
                return
            }

            if let value = try? container.decode([AudienceCondition].self) {
                self = .array(value)
                return
            }
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode AudienceCondition"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .logicalOp(let op):
            try? container.encode(op)
        case .audienceId(let id):
            try? container.encode(id)
        case .array(let conditions):
            try? container.encode(conditions)
        }
    }
    
    func evaluate(projectConfig: ProjectConfig, attributes: [String: Any]) -> Bool? {
        switch self {
        case .logicalOp:
            return nil   // invalid
        case .audienceId(let id):
            
            let audienceMatch = projectConfig.project.typedAudiences.filter{$0.id == id}.first ??
                projectConfig.project.audiences.filter{$0.id == id}.first
            
            guard let audience = audienceMatch else { return nil }
            
            return audience.conditions.evaluate(projectConfig: projectConfig, attributes: attributes)
        case .array(let conditions):
            return conditions.evaluate(config: projectConfig, attributes: attributes)
        }
    }
}

extension Array where Element == AudienceCondition {

    func evaluate(config: ProjectConfig, attributes: [String: Any]) -> Bool? {
        guard self.count > 0 else { return nil }
        
        let firstItem = self.first!
        
        switch firstItem {
        case .audienceId:
            guard self.count == 1 else { return nil }
            return firstItem.evaluate(projectConfig: config, attributes: attributes)
        case .logicalOp(let op):
            return evaluate(op: op, config: config, attributes: attributes)
        default:
            return nil    // invalid first item
        }
    }
    
    func evaluate(op: LogicalOp, config: ProjectConfig, attributes: [String: Any]) -> Bool? {
        guard self.count > 1 else { return nil }
        
        switch op {
        case .and:
            return andEvaluate(config: config, attributes: attributes)
        case .or:
            return orEvaluate(config: config, attributes: attributes)
        case .not:
            return notEvaluate(config: config, attributes: attributes)
        }
    }
    
    func orEvaluate(config: ProjectConfig, attributes: [String: Any]) -> Bool? {
        var foundNil = false
        
        for i in 1..<self.count {
            let condition = self[i]
            if let result = condition.evaluate(projectConfig: config, attributes: attributes) {
                if result == true {
                    return true
                }
            } else {
                foundNil = true
            }
        }
        
        return foundNil ? nil : false
    }
    
    func andEvaluate(config: ProjectConfig, attributes: [String: Any]) -> Bool? {
        var foundNil = false
        
        for i in 1..<self.count {
            let condition = self[i]
            if let result = condition.evaluate(projectConfig: config, attributes: attributes) {
                if result == false {
                    return false
                }
            } else {
                foundNil = true
            }
        }
        
        return foundNil ? nil : true
    }
    
    func notEvaluate(config: ProjectConfig, attributes: [String: Any]) -> Bool? {
        let condition = self[1]
        
        if let result = condition.evaluate(projectConfig: config, attributes: attributes) {
            return !result
        }
        
        return nil
    }
    
}
