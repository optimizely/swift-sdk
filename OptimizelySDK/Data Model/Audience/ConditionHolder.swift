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

enum LogicalOp: String, Codable {
    case and
    case or
    case not
}

enum ConditionHolder: Codable, Equatable {
    case logicalOp(LogicalOp)
    case audienceId(String)
    case array([ConditionHolder])
    
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
            
            if let value = try? container.decode([ConditionHolder].self) {
                self = .array(value)
                return
            }
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode ConditionHolder"))
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
    
    func evaluate(attributes: [String: Any]) -> Bool? {
        
        return nil
    }
    
    func evaluate(project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        switch self {
        case .logicalOp:
            return nil   // invalid
        case .audienceId(let id):
            return project.evaluateAudience(audienceId: id, attributes: attributes)
        case .array(let conditions):
            return conditions.evaluate(project: project, attributes: attributes)
        }
    }
}

extension Array where Element == ConditionHolder {
    
    func evaluate(project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        guard self.count > 0 else { return nil }
        
        let firstItem = self.first!
        
        switch firstItem {
        case .logicalOp(let op):
            return evaluate(op: op, project: project, attributes: attributes)
        case .audienceId:
            guard self.count == 1 else { return nil }
            return firstItem.evaluate(project: project, attributes: attributes)
        default:
            return nil    // invalid first item
        }
    }
    
    func evaluate(op: LogicalOp, project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        guard self.count > 1 else { return nil }
        
        switch op {
        case .and:
            return andEvaluate(project: project, attributes: attributes)
        case .or:
            return orEvaluate(project: project, attributes: attributes)
        case .not:
            return notEvaluate(project: project, attributes: attributes)
        }
    }
    
    func orEvaluate(project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        var foundNil = false
        
        for i in 1..<self.count {
            let condition = self[i]
            if let result = condition.evaluate(project: project, attributes: attributes) {
                if result == true {
                    return true
                }
            } else {
                foundNil = true
            }
        }
        
        return foundNil ? nil : false
    }
    
    func andEvaluate(project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        var foundNil = false
        
        for i in 1..<self.count {
            let condition = self[i]
            if let result = condition.evaluate(project: project, attributes: attributes) {
                if result == false {
                    return false
                }
            } else {
                foundNil = true
            }
        }
        
        return foundNil ? nil : true
    }
    
    func notEvaluate(project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        let condition = self[1]
        
        if let result = condition.evaluate(project: project, attributes: attributes) {
            return !result
        }
        
        return nil
    }
    
}
