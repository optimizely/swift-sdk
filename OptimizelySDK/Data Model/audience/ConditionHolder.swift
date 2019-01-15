/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

public enum ConditionHolder : Codable {
    case string(String)
    case userAttribute(UserAttribute)
    case array([ConditionHolder])
    
    public init(from decoder: Decoder) throws {
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
    
    public func encode(to encoder: Encoder) throws {
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
    
    func evaluate(projectConfig:OPTProjectConfig, attributes:Dictionary<String,Any>) -> Bool? {
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
    func evaluate(config: OPTProjectConfig, attributes: Dictionary<String,Any>) -> Bool? {

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
    
    func evaluate(operand:String, config: OPTProjectConfig, attributes: Dictionary<String,Any>) -> Bool? {
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
