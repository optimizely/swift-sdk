/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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
            try container.encode(op)
        case .leaf(let conditionLeaf):
            try container.encode(conditionLeaf)
        case .array(let conditions):
            try container.encode(conditions)
        }
    }
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) -> Bool? {
        switch self {
        case .logicalOp:
            //TODO: replace with logger
            print("Logical operation not evaluated")
            return nil
        case .leaf(let conditionLeaf):
            return conditionLeaf.evaluate(project: project, attributes: attributes)
        case .array(let conditions):
            return conditions.evaluate(project: project, attributes: attributes)
        }
    }
}

// MARK: - [ConditionHolder]

extension Array where Element == ConditionHolder {
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) -> Bool? {
        guard let firstItem = self.first else {
            print("Empty condition array")
            return nil
        }
        
        switch firstItem {
        case .logicalOp(let op):
            return evaluate(op: op, project: project, attributes: attributes)
        case .leaf:
            // special case - no logical operator
            // implicit or
            return [[ConditionHolder.logicalOp(.or)],self].flatMap({$0}).evaluate(op: LogicalOp.or, project: project, attributes: attributes)
        default:
            print("Invalid first item")
            return nil
        }
    }
    
    func evaluate(op: LogicalOp, project: ProjectProtocol?, attributes: OptimizelyAttributes?) -> Bool? {
        guard self.count > 0 else {
            print("Empty condition array")
            return nil
        }
        
        let evalList = Array(self[1...])
        
        switch op {
        case .and:
            return evalList.and(project: project, attributes: attributes)
        case .or:
            return evalList.or(project: project, attributes: attributes)
        case .not:
            return evalList.not(project: project, attributes: attributes)
        }
    }
    
    // returns true only when all items are true and no-error
    func and(project: ProjectProtocol?, attributes: OptimizelyAttributes?) -> Bool? {
        guard self.count > 0 else {
            print(OptimizelyError.conditionInvalidFormat("AND with empty items"))
            return nil
        }
        
        var foundError = false
        
        for eval in self {
            if let value = eval.evaluate(project: project, attributes: attributes) {
                if !value {
                    return false
                }
            }
            else {
                foundError = true
            }
        }
        
        if foundError {
            print(OptimizelyError.conditionInvalidFormat("AND with invalid items [\(self)]"))
            return nil
        }
        
        return true
    }
    
    // return try if any item is true (even with other error items)
    func or(project: ProjectProtocol?, attributes: OptimizelyAttributes?) -> Bool? {
        var foundError: Bool = false
        
        for eval in self {
            if let value = eval.evaluate(project: project, attributes: attributes) {
                if value {
                    return true
                }
            }
            else {
                foundError = true
            }
        }
        
        if foundError {
            print(OptimizelyError.conditionInvalidFormat("OR with invalid items [\(self)]"))
            return nil
        }
        
        return false
    }
    
    // evalute the 1st item only
    func not(project: ProjectProtocol?, attributes: OptimizelyAttributes?) -> Bool? {
        guard let eval = self.first else {
            print(OptimizelyError.conditionInvalidFormat("NOT with empty items"))
            return nil
        }
        
        if let result = eval.evaluate(project: project, attributes: attributes) {
            return !result
        }

        print(OptimizelyError.conditionInvalidFormat("NOT with invalid items [\(eval)]"))
        return nil
    }

}

