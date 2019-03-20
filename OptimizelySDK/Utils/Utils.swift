//
//  Utils.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/14/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

class Utils {
    
    // @objc NSNumber can be casted either Bool, Int, or Double
    // more filtering required to avoid NSNumber(false, true) interpreted as Int(0, 1) instead of Bool
    
    // MARK: - Type Checking
    
    static func isBoolType(_ value: Any) -> Bool {
        return (value is Bool) && !isNSNumberValueType(value)
    }
    
    static func isIntType(_ value: Any) -> Bool {
        let allSwiftIntTypes: [Any.Type] = [Int.self, Int8.self, Int16.self, Int32.self, Int64.self,
                                       UInt.self, UInt8.self, UInt16.self, UInt32.self, UInt64.self]

        let isSwiftIntType = allSwiftIntTypes.contains{ $0 == type(of: value) }
        let isNSNumberIntType = (value is Int)

        return (isSwiftIntType || isNSNumberIntType) && !isNSNumberBoolType(value)
    }
    
    static func isDoubleType(_ value: Any) -> Bool {
        // Float32 === Float, Float64 ==== Double
        let allSwiftNumTypes: [Any.Type] = [Double.self,
                                            Float.self, Float80.self]
        
        let isSwiftNumType = allSwiftNumTypes.contains{ $0 == type(of: value) }
        let isNSNumberNumType = (value is Double)

        return (isSwiftNumType || isNSNumberNumType) && !isNSNumberBoolType(value)
    }
    
    static func isNSNumberBoolType(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: true))
    }
    
    static func isNSNumberValueType(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: 0))
    }
    
    // MARK: - Type Conversion
    
    static func getInt64Value(_ value: Any) -> Int64? {
        guard isIntType(value) else { return nil }
        
        var finalValue: Int64?
        switch value {
        case is Int: finalValue = Int64(value as! Int)
        case is Int8: finalValue = Int64(value as! Int8)
        case is Int16: finalValue = Int64(value as! Int16)
        case is Int32: finalValue = Int64(value as! Int32)
        case is Int64: finalValue = Int64(value as! Int64)
        case is UInt: finalValue = Int64(value as! UInt)
        case is UInt8: finalValue = Int64(value as! UInt8)
        case is UInt16: finalValue = Int64(value as! UInt16)
        case is UInt32: finalValue = Int64(value as! UInt32)
        case is UInt64: finalValue = Int64(value as! UInt64)
        default: finalValue = nil
        }
        
        return finalValue
    }
    
    static func getDoubleValue(_ value: Any) -> Double? {
        guard isDoubleType(value) else { return nil }
        
        var finalValue: Double?
        switch value {
        case is Double: finalValue = Double(value as! Double)
        case is Float: finalValue = Double(value as! Float)
        case is Float80: finalValue = Double(value as! Float80)
        default: finalValue = nil
        }
        
        return finalValue
    }
    
    static func getStringValue(_ value: Any) -> String? {
        guard value is String else { return nil }
        return (value as! String)
    }

    static func getBoolValue(_ value: Any) -> Bool? {
        guard isBoolType(value) else { return nil }
        return (value as! Bool)
    }

}
