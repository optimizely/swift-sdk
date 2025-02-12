//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

enum AttributeValue: Codable, Equatable, CustomStringConvertible {
    typealias AttrArray = Array<AttributeValue>
    typealias AttrDictionary = [String : AttributeValue]
    
    case string(String)
    case int(Int64)         // supported value range [-2^53, 2^53]
    case double(Double)
    case bool(Bool)
    case array(AttrArray)
    case dictionary(AttrDictionary)
    case others
    
    var description: String {
        switch self {
        case .string(let value):
            return "string(\(value))"
        case .double(let value):
            return "double(\(value))"
        case .int(let value):
            return "int(\(value))"
        case .bool(let value):
            return "bool(\(value))"
        case .array(let value):
            return "array(\(value))"
        case .dictionary(let value):
            return "dictionary(\(value))"
        case .others:
            return "others"
        }
    }
    
    init?(value: Any?) {

        guard let value = value else { return nil }

        if let stringValue = Utils.getStringValue(value) {
            self = .string(stringValue)
            return
        }

        // NOTE: keep {Double, Float} before Int checking for testing consistency
        if let doubleValue = Utils.getDoubleValue(value) {
            self = .double(doubleValue)
            return
        }
        
        if let int64Value = Utils.getInt64Value(value) {
            self = .int(int64Value)
            return
        }
        
        if let boolValue = Utils.getBoolValue(value) {
            self = .bool(boolValue)
            return
        }
        
        if let arrValue = value as? [Any] {
            let attr = arrValue.compactMap { AttributeValue(value: $0) }
            self = .array(attr)
            return
        }
        
        if let dicValue = value as? [String : Any] {
            let attr = dicValue.compactMapValues { AttributeValue(value: $0) }
            self = .dictionary(attr)
            return
        }

        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        
        // NOTE: keep {Double, Float} before Int checking for testing consistency
        //       Int values are all filtered as Double, so no separate parsing for int
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        
        if let value = try? container.decode(AttrArray.self) {
            self = .array(value)
            return
        }
        
        if let value = try? container.decode(AttrDictionary.self) {
            self = .dictionary(value)
            return
        }
        
        
        // accept all other types (null) for forward compatibility support
        self = .others
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .string(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value.mapValues { $0 })
        case .others:
            return
        }
    }
}

// MARK: - Evaluate

extension AttributeValue {
    
    func isExactMatch(with target: Any, condition: String = "", name: String = "") throws -> Bool {
        
        if !self.isValidForExactMatcher || (self.doubleValue?.isInfinite ?? false) {
            throw OptimizelyError.evaluateAttributeInvalidCondition(condition)
        }
        
        guard let targetValue = AttributeValue(value: target), self.isComparable(with: targetValue) else {
            throw OptimizelyError.evaluateAttributeInvalidType(condition, target, name)
        }
        
        try checkValidAttributeNumber(target, condition: condition, name: name)
        
        // same type and same value
        if self == targetValue {
            return true
        }
        
        // allow int value compared to double as extra evaluation
        if let doubleValue = self.doubleValue, doubleValue == targetValue.doubleValue {
            return true
        }
        
        if case .array(let selfArr) = self, case .array(let targetArr) = targetValue {
            return selfArr == targetArr
        }
        
        if case .dictionary(let selfDict) = self, case .dictionary(let targetDict) = targetValue {
            return selfDict == targetDict
        }
        
        return false
    }
    
    func isSubstring(of target: Any, condition: String = "", name: String = "") throws -> Bool {
        
        guard case .string(let value) = self else {
            throw OptimizelyError.evaluateAttributeInvalidCondition(condition)
        }
        
        guard let targetStr = target as? String else {
            throw OptimizelyError.evaluateAttributeInvalidType(condition, target, name)
        }
        
        return targetStr.contains(value)
    }
    
    func isGreater(than target: Any, condition: String = "", name: String = "") throws -> Bool {
        
        guard let currentDouble = self.doubleValue, currentDouble.isFinite else {
            throw OptimizelyError.evaluateAttributeInvalidCondition(condition)
        }
        
        guard let targetValue = AttributeValue(value: target),
            let targetDouble = targetValue.doubleValue else {
                throw OptimizelyError.evaluateAttributeInvalidType(condition, target, name)
        }
        
        try checkValidAttributeNumber(target, condition: condition, name: name)
        
        return currentDouble > targetDouble
    }

    func isGreaterOrEqual(than target: Any, condition: String = "", name: String = "") throws -> Bool {
        return try isGreater(than: target, condition: condition, name: name) || isExactMatch(with: target, condition: condition, name: name)
    }
    
    func isLess(than target: Any, condition: String = "", name: String = "") throws -> Bool {
                
        guard let currentDouble = self.doubleValue, currentDouble.isFinite else {
            throw OptimizelyError.evaluateAttributeInvalidCondition(condition)
        }
        
        guard let targetValue = AttributeValue(value: target),
            let targetDouble = targetValue.doubleValue else {
                throw OptimizelyError.evaluateAttributeInvalidType(condition, target, name)
        }
        try checkValidAttributeNumber(target, condition: condition, name: name)

        return currentDouble < targetDouble
    }
    
    func isLessOrEqual(than target: Any, condition: String = "", name: String = "") throws -> Bool {
        return try isLess(than: target, condition: condition, name: name) || isExactMatch(with: target, condition: condition, name: name)
    }
    
    func isSemanticVersionEqual(than target: SemanticVersion) throws -> Bool {
        return try (self.stringValue as SemanticVersion).compareVersion(targetedVersion: target) == 0
    }

    func isSemanticVersionGreater(than target: SemanticVersion) throws -> Bool {
        return try (self.stringValue as SemanticVersion).compareVersion(targetedVersion: target) > 0
    }

    func isSemanticVersionLess(than target: SemanticVersion) throws -> Bool {
        return try (self.stringValue as SemanticVersion).compareVersion(targetedVersion: target) < 0
    }

    func isSemanticVersionGreaterOrEqual(than target: SemanticVersion) throws -> Bool {
        return try (self.stringValue as SemanticVersion).compareVersion(targetedVersion: target) >= 0    }

    func isSemanticVersionLessOrEqual(than target: SemanticVersion) throws -> Bool {
        return try (self.stringValue as SemanticVersion).compareVersion(targetedVersion: target) <= 0
    }

    var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }
    
    var stringValue: String {
        switch self {
        case .string(let value):
            return value
        case .double(let value):
            return String(value)
        case .int(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        case .array(let value):
            return String(describing: value)
        case .dictionary(let value):
            return String(describing: value)
        case .others:
            return "UNKNOWN"
        }
    }
    
    func isComparable(with target: AttributeValue) -> Bool {
        switch (self, target) {
        case (.string, .string): return true
        case (.int, .double): return true
        case (.int, .int): return true
        case (.double, .int): return true
        case (.double, .double): return true
        case (.bool, .bool): return true
        case (.array, .array): return true
        case (.dictionary, .dictionary): return true
        default: return false
        }
    }
    
    func checkValidAttributeNumber(_ number: Any?, condition: String, name: String, caller: String = #function) throws {
        // check range for any value types (Int, Int64, Double, Float...)
        // do not check value range for string types
        
        guard let number = number else { return }
    
        var num: Double
        if let number = Utils.getInt64Value(number) {
            num = Double(number)
        } else if let number = Utils.getDoubleValue(number) {
            num = number
        } else {
            return
        }

        // valid range: [-2^53, 2^53]
        if abs(num) > pow(2, 53) {
            throw OptimizelyError.evaluateAttributeValueOutOfRange(condition, name)
        }
    }
    
    var isValidForExactMatcher: Bool {
        switch self {
        case (.string): return true
        case (.int): return true
        case (.double): return true
        case (.bool): return true
        case (.array): return true
        case (.dictionary): return true
        default: return false
        }
    }

    func prettySrc(_ src: String, target: Any? = nil) -> String {
        return "\(self):(\(src)) target: " + (target != nil ? "\(target!)" : "nil")
    }
    
}
