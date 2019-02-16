//
//  AttributeValue.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

enum AttributeValue: Codable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    
    init?(value: Any?) {
        if value is String {
            self = .string(value as! String)
            return
        }
        
        if value is Int {
            self = .int(value as! Int)
            return
        }
        
        if value is Double {
            self = .double(value as! Double)
            return
        }
        
        if value is Bool {
            self = .bool(value as! Bool)
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
        
        if let value = try? container.decode(Int.self) {
            self = .int(value)
            return
        }
        
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        
        if let value = try? container.decode(Bool.self) {
            self = .bool(value)
            return
        }

        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode Condition"))
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
        }
    }
}

// MARK: - Evaluate

extension AttributeValue {
    
    func isExactMatch(with target: Any?) throws -> Bool {
        guard let targetValue = AttributeValue(value: target) else {
            throw OptimizelyError.conditionInvalidValueType(#function)
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

    func isSubstring(of target: Any?) throws -> Bool {
        guard case .string(let value) = self else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        guard let target = target as? String else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        return target.contains(value)
    }
    
    func isGreater(than target: Any?) throws -> Bool {
        guard let targetValue = AttributeValue(value: target) else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        guard let currentDouble = self.doubleValue else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        guard let targetDouble = targetValue.doubleValue else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        return currentDouble > targetDouble
    }
    
    func isLess(than target: Any?) throws -> Bool {
        guard let targetValue = AttributeValue(value: target) else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        guard let currentDouble = self.doubleValue else {
            throw OptimizelyError.conditionInvalidValueType(#function)
        }
        
        guard let targetDouble = targetValue.doubleValue else {
            throw OptimizelyError.conditionInvalidValueType(#function)
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
}
