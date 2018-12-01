//
//  ConditionHolder.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/29/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

enum ConditionHolder : Codable {
    case string(String)
    case userAttribute(UserAttribute)
    case array([ConditionHolder])
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode([ConditionHolder].self) {
                self = .array(value)
                return
            }
            if let value = try? container.decode(String.self) {
                self = .string(value)
                return
            }
            if let value = try? container.decode(UserAttribute.self) {
                self = .userAttribute(value)
                return
            }
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode Condition"))
    }
    
    func encode(to encoder: Encoder) throws {
        switch self {
        case .string(let op):
            var container = encoder.singleValueContainer()
            try? container.encode(op)
        case .userAttribute(let userAttr):
            var container = encoder.singleValueContainer()
            try? container.encode(userAttr)
        case .array(let holder):
            var container = encoder.unkeyedContainer()
            try? container.encode(holder)
        }
    }
    
    func evaluate(projectConfig:ProjectConfig, attributes:Dictionary<String,Any>) -> Bool? {
        switch self {
        case .string(let op):
            // assume it is a audienceId if it is not an operand
            if !op.isOperand {
                if let audience = projectConfig.typedAudiences?.filter({$0.id == op}).first {
                    return audience.conditions?.evaluate(projectConfig: projectConfig, attributes: attributes)
                }
                else if let audience = projectConfig.audiences.filter({$0.id == op}).first {
                    return audience.conditions?.evaluate(projectConfig: projectConfig, attributes: attributes)
                }
            }
        case .userAttribute(let userAttr):
            return userAttr.evaluate(config: projectConfig, attributes: attributes)
        case .array(let holder):
            return holder.evaluate(config: projectConfig, attributes: attributes)
        }
        
        return nil
    }
}

extension String {
    var isOperand:Bool {
        switch self {
        case "and","or","not":
            return true
        default:
            return false;
        }
    }
}

extension Array where Element == ConditionHolder {
    func evaluate(config: ProjectConfig, attributes: Dictionary<String,Any>) -> Bool? {
        var operand:String?
        
        for i in 0..<self.count {
            let condition = self[i]
            switch condition {
            case .string(let op):
                if op.isOperand {
                    return evaluate(operand: op, config: config, attributes: attributes)
                }
                else {
                    if let audience = config.typedAudiences?.filter({$0.id == op}).first {
                        return audience.conditions?.evaluate(projectConfig: config, attributes: attributes)
                    }
                    else if let audience = config.audiences.filter({$0.id == op}).first {
                        return audience.conditions?.evaluate(projectConfig: config, attributes: attributes)
                    }

                }
            case .array(let conditions):
                return conditions.evaluate(config: config, attributes: attributes)
            case .userAttribute(let userAttr):
                return userAttr.evaluate(config: config, attributes: attributes)
            }
        }
        
        return nil
    }
    
    func evaluate(operand:String, config: ProjectConfig, attributes: Dictionary<String,Any>) -> Bool? {
        func orEvaluate() -> Bool? {
            var foundNil = false
            for i in 1..<self.count {
                let condition = self[i]
                if let result = condition.evaluate(projectConfig: config, attributes: attributes) {
                    if result == true {
                        return true
                    }
                }
                else {
                    foundNil = true
                }
            }
            return foundNil ? nil : false
        }
        func andEvaluate() -> Bool? {
            var foundNil = false
            for i in 1..<self.count {
                let condition = self[i]
                if let result = condition.evaluate(projectConfig: config, attributes: attributes) {
                    if result == false {
                        return false
                    }
                }
                else {
                    foundNil = true
                }
            }
            return foundNil ? nil : true
        }
        func notEvaluate() -> Bool? {
            let condition = self[1]
            if let result = condition.evaluate(projectConfig: config, attributes: attributes) {
                return !result
            }
            return nil
        }
        
        switch operand {
        case "and":
            return andEvaluate()
        case "or":
            return orEvaluate()
        case "not":
            return notEvaluate()
        default:
            return orEvaluate()
        }

     }
}
