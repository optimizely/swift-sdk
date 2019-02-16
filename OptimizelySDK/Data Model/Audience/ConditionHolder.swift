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
    case leaf(ConditionLeaf)
    case array([ConditionHolder])
    
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer() {
            if let value = try? container.decode(LogicalOp.self) {
                self = .logicalOp(value)
                return
            }
            
            if let value = try? container.decode(ConditionLeaf.self) {
                self = .leaf(value)
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
        case .leaf(let conditionLeaf):
            try? container.encode(conditionLeaf)
        case .array(let conditions):
            try? container.encode(conditions)
        }
    }
    
    func evaluate(project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        switch self {
        case .logicalOp:
            return nil   // invalid
        case .leaf(let conditionLeaf):
            return conditionLeaf.evaluate(project: project, attributes: attributes)
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
        case .leaf:
            // special case - array has a single ConditionLeaf
            guard self.count == 1 else { return nil }
            return firstItem.evaluate(project: project, attributes: attributes)
        default:
            // invalid first item
            return nil
        }
    }
    
    func evaluate(op: LogicalOp, project: ProjectProtocol, attributes: [String: Any]) -> Bool? {
        guard self.count > 1 else { return nil }
        
        let eval = { (idx: Int) -> Bool? in
            return self[idx].evaluate(project: project, attributes: attributes)
        }
        
        
        switch op {
        case .and:
            return andEvaluate(eval)
        case .or:
            return orEvaluate(eval)
        case .not:
            return notEvaluate(eval)
        }
    }
    
    func orEvaluate(_ eval: (Int) -> Bool?) -> Bool? {
        var foundNil = false
        
        for i in 1..<self.count {
            if let result = eval(i) {
                if result {
                    return true
                }
            } else {
                foundNil = true
            }
        }
        
        return foundNil ? nil : false
    }
    
    func andEvaluate(_ eval: (Int) -> Bool?) -> Bool? {
        for i in 1..<self.count {
            if let result = eval(i) {
                if result == false {
                    return false
                }
            } else {
                return nil
            }
        }
        
        return true
    }
    
    func notEvaluate(_ eval: (Int) -> Bool?) -> Bool? {
        if let result = eval(1) {
            return !result
        }
        
        return nil
    }

}
