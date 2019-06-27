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

class Utils {
    
    // from auto-generated variable OPTIMIZELYSDKVERSION
    static var sdkVersion: String = OPTIMIZELYSDKVERSION
    
    // @objc NSNumber can be casted either Bool, Int, or Double
    // more filtering required to avoid NSNumber(false, true) interpreted as Int(0, 1) instead of Bool
    
    // MARK: - Type Checking
    
    static func isBoolType(_ value: Any) -> Bool {
        return (value is Bool) && !isNSNumberValueType(value)
    }
    
    static func isIntType(_ value: Any) -> Bool {
        let allSwiftIntTypes: [Any.Type] = [Int.self, Int8.self, Int16.self, Int32.self, Int64.self,
                                            UInt.self, UInt8.self, UInt16.self, UInt32.self, UInt64.self]
        
        let isSwiftIntType = allSwiftIntTypes.contains { $0 == type(of: value) }

        return isSwiftIntType || isNSNumberIntegerType(value)
    }
    
    static func isDoubleType(_ value: Any) -> Bool {
        // Float32 === Float, Float64 ==== Double
        let allSwiftNumTypes: [Any.Type] = [Double.self,
                                            Float.self, CLongDouble.self]
        
        let isSwiftNumType = allSwiftNumTypes.contains { $0 == type(of: value) }

        return isSwiftNumType || isNSNumberDoubleType(value)
    }
    
    // MARK: - NSNumber
    
    static func isNSNumberBoolType(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: true))
    }
    
    static func isNSNumberValueType(_ value: Any) -> Bool {
        return type(of: value) == type(of: NSNumber(value: 0))
    }
    
    static func isNSNumberIntegerType(_ value: Any) -> Bool {
        guard isNSNumberValueType(value) else { return false }
        
        // Swift cannot tell NSNumber(int) and NSNumber(double), both __NSCFNumber type
        // Need to look at objCType ("q": integer, "d": decimal
        
        let ptr1 = (value as! NSNumber).objCType
        let ptr2 = (10 as NSNumber).objCType
        return String(cString: ptr1) == String(cString: ptr2)
    }

    static func isNSNumberDoubleType(_ value: Any) -> Bool {
        guard isNSNumberValueType(value) else { return false }

        let ptr1 = (value as! NSNumber).objCType
        let ptr2 = NSNumber(value: 10.5).objCType
        return String(cString: ptr1) == String(cString: ptr2)
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
        case is CLongDouble: finalValue = Double(value as! CLongDouble)
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
