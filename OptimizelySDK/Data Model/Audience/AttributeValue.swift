//
//  AttributeValue.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

enum AttributeValue: Codable, Equatable, CustomStringConvertible {
    case string(String)
    case int(Int64)         // supported value range [-2^53, 2^53]
    case double(Double)
    case bool(Bool)
    // not defined in datafile schema, but required for forward compatiblity (see Nikhil's doc)
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
        if let doubleValue = Utils.getDoubleValue(value),
            AttributeValue.isValueValidRange(num: doubleValue)
        {
            self = .double(doubleValue)
            return
        }
        
        if let int64Value = Utils.getInt64Value(value),
            AttributeValue.isValueValidRange(num: Double(int64Value))
        {
            self = .int(int64Value)
            return
        }
        
        if let boolValue = Utils.getBoolValue(value) {
            self = .bool(boolValue)
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
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        
        if let value = try? container.decode(Int64.self) {
            self = .int(value)
            return
        }
        
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }
        
        // accept all other types (null, {}, []) for forward compatibility support
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
        case .others:
            return
        }
    }
}

// MARK: - Evaluate

extension AttributeValue {
    
    func isExactMatch(with target: Any) throws -> Bool {
        guard let targetValue = AttributeValue(value: target) else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        guard self.isComparable(with: targetValue) else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        // same type and same value
        if self == targetValue {
            return true
        }
        
        // allow int value compared to double as extra evaluation
        if let doubleValue = self.doubleValue, doubleValue == targetValue.doubleValue {
            return true
        }
        
        return false
    }

    func isSubstring(of target: Any) throws -> Bool {
        guard case .string(let value) = self else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        guard let targetStr = target as? String else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        return targetStr.contains(value)
    }
    
    func isGreater(than target: Any) throws -> Bool {
        guard let targetValue = AttributeValue(value: target) else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        guard let currentDouble = self.doubleValue,
            let targetDouble = targetValue.doubleValue else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        return currentDouble > targetDouble
    }
    
    func isLess(than target: Any) throws -> Bool {
        guard let targetValue = AttributeValue(value: target) else {
            throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }
        
        guard let currentDouble = self.doubleValue,
            let targetDouble = targetValue.doubleValue else {
                throw OptimizelyError.conditionInvalidValueType(prettySrc(#function, target: target))
        }

        return currentDouble < targetDouble
    }
    
    var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
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
        default: return false
        }
    }
    
    static func isValueValidRange(num: Double) -> Bool {
        // valid range: [-2^53, 2^53] i
        return abs(num) <= pow(2, 53)
    }

    func prettySrc(_ src: String, target: Any? = nil) -> String {
        return "(\(src)): \(self) target: " + (target != nil ? "\(target!)" : "nil")
    }
    
}

