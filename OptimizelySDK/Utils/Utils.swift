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
        let isSwiftIntType = value is Int || value is Int8 || value is Int16 ||
            value is Int32 || value is Int64
        
        return isSwiftIntType && !isNSNumberBoolType(value)
    }
    
    static func isDoubleType(_ value: Any) -> Bool {
        let isSwiftNumType = value is Double || value is Float
            
        return isSwiftNumType && !isNSNumberBoolType(value)
    }
    
    static func isNSNumberBoolType(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: true))
    }
    
    static func isNSNumberValueType(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: 0))
    }
    
    // MARK: - Type Conversion
    
    static func getIntValue(_ value: Any) -> Int? {
        guard isIntType(value) else { return nil }
        
        var finalValue: Int
        switch value {
        case is Int8: finalValue = Int(value as! Int8)
        case is Int16: finalValue = Int(value as! Int16)
        case is Int32: finalValue = Int(value as! Int32)
        case is Int64: finalValue = Int(value as! Int64)
        default: finalValue = Int(value as! Int)
        }
        
        return finalValue
    }
    
    static func getDoubleValue(_ value: Any) -> Double? {
        guard isDoubleType(value) else { return nil }
        
        var finalValue: Double
        switch value {
        case is Float: finalValue = Double(value as! Float)
        default: finalValue = Double(value as! Double)
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
