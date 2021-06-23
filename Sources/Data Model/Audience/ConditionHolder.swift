//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) throws -> Bool {
        switch self {
        case .logicalOp:
            throw OptimizelyError.conditionInvalidFormat("Logical operation not evaluated")
        case .leaf(let conditionLeaf):
            return try conditionLeaf.evaluate(project: project, attributes: attributes)
        case .array(let conditions):
            return try conditions.evaluate(project: project, attributes: attributes)
        }
    }
    
}

// MARK: - serialization

extension ConditionHolder {
    
    /// Returns a serialized string of audienceConditions
    /// - each audienceId is converted into "AUDIENCE(audienceId)", which can be translated to correponding names later
    ///
    /// Examples:
    /// - "123" => "AUDIENCE(123)"
    /// - ["and", "123", "456"] => "AUDIENCE(123) AND AUDIENCE(456)"
    /// - ["or", "123", ["and", "456", "789"]] => "AUDIENCE(123) OR ((AUDIENCE(456) AND AUDIENCE(789))"
    var serialized: String {
        switch self {
        case .logicalOp:
            return ""
        case .leaf(.audienceId(let audienceId)):
            return "AUDIENCE(\(audienceId))"
        case .array(let conditions):
            return "\(conditions.serialized)"
        default:
            return ""
        }
    }
    
    var isArray: Bool {
        if case .array = self {
            return true
        } else {
            return false
        }
    }
}

// MARK: - [ConditionHolder]

extension Array where Element == ConditionHolder {
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) throws -> Bool {
        guard let firstItem = self.first else {
            throw OptimizelyError.conditionInvalidFormat("Empty condition array")
        }
        
        switch firstItem {
        case .logicalOp(let op):
            return try evaluate(op: op, project: project, attributes: attributes)
        case .leaf:
            // special case - no logical operator
            // implicit or
            return try [[ConditionHolder.logicalOp(.or)], self].flatMap({$0}).evaluate(op: LogicalOp.or, project: project, attributes: attributes)
        default:
            throw OptimizelyError.conditionInvalidFormat("Invalid first item")
        }
    }
    
    func evaluate(op: LogicalOp, project: ProjectProtocol?, attributes: OptimizelyAttributes?) throws -> Bool {
        guard self.count > 0 else {
            throw OptimizelyError.conditionInvalidFormat("Empty condition array")
        }
        
        let itemsAfterOpTrimmed = Array(self[1...])
        
        // create closure array for delayed evaluations to avoid unnecessary ops
        let evalList = itemsAfterOpTrimmed.map { holder -> ThrowableCondition in
            return {
                return try holder.evaluate(project: project, attributes: attributes)
            }
        }
        
        switch op {
        case .and:
            return try evalList.and()
        case .or:
            return try evalList.or()
        case .not:
            return try evalList.not()
        }
    }
    
    /// Represents an array of ConditionHolder as a serialized string
    ///
    /// Examples:
    /// - ["not", A] => "NOT A"
    /// - ["and", A, B] => "A AND B"
    /// - ["or", A, ["and", B, C]] => "A OR (B AND C)"
    /// - [A] => "A"
    var serialized: String {
        var result = ""
        
        guard let firstItem = self.first else {
            return "\(result)"
        }

        // The first item of the array is supposed to be a logical op (and, or, not)
        // extract it first and join the rest of the array items with the logical op
        switch firstItem {
        case .logicalOp(.not):
            result = (self.count < 2) ? "" : "NOT \(self[1].serialized)"
        case .logicalOp(let op):
            result = self.enumerated()
                .filter { $0.offset > 0 }
                .map {
                    let desc = $0.element.serialized
                    return ($0.element.isArray) ? "(\(desc))" : desc
                }
                .joined(separator: " " + "\(op)".uppercased() + " ")
        case .leaf(.audienceId):
            result = "\([[ConditionHolder.logicalOp(.or)], self].flatMap({$0}).serialized)"
        default:
            result = ""
        }
        
        return "\(result)"
    }

}
