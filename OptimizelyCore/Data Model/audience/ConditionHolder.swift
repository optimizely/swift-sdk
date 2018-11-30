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
            if let value = try? container.decode(String.self) {
                self = .string(value)
                return
            }
            if let value = try? container.decode(UserAttribute.self) {
                self = .userAttribute(value)
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
    
    static func Convert(holders:[ConditionHolder]) -> Condition? {
        func convertArray(conditionHolder:[ConditionHolder]) -> [Any] {
            let arr = conditionHolder.map { (holder) -> Any in
                switch holder {
                case .string(let op):
                    return op
                case .userAttribute(let userAttr):
                    return userAttr
                case .array(let arr):
                    return convertArray(conditionHolder: arr)
                }
            }
            return arr
        }
        
        return try? OrCondition.Populate(from: convertArray(conditionHolder: holders) as NSArray)
    }
}
