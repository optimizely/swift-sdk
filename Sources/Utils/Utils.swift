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

#if os(watchOS)
import WatchKit
#elseif os(macOS)
import Cocoa
#else
import UIKit
#endif

class Utils {
    
    // from auto-generated variable OPTIMIZELYSDKVERSION
    static var sdkVersion: String = OPTIMIZELYSDKVERSION
    static let swiftSdkClientName = "swift-sdk"
    
    static var os: String {
        #if os(iOS)
        return "iOS"
        #elseif os(tvOS)
        return "tvOS"
        #elseif os(macOS)
        return "macOS"
        #elseif os(watchOS)
        return "watchOS"
        #else
        return "Other"
        #endif
    }
    
    static var osVersion: String {
        #if os(watchOS)
        return WKInterfaceDevice.current().systemVersion
        #elseif os(macOS)
        return ProcessInfo().operatingSystemVersionString
        #else
        return UIDevice.current.systemVersion
        #endif
    }
    
    static var deviceModel: String {
        #if os(watchOS)
        return WKInterfaceDevice.current().model
        #elseif os(macOS)
        return "N/A"
        #else
        return UIDevice.current.model
        #endif
    }
    
    static var deviceType: String {
        // UIUserInterfaceIdiom is an alternative solution, but some (.mac, etc) behaves in an unexpected way.
        #if os(iOS)
        return (UIDevice.current.userInterfaceIdiom == .phone) ? "Phone" : "Tablet"
        #elseif os(tvOS)
        return "Smart TV"
        #elseif os(macOS)
        return "PC"
        #elseif os(watchOS)
        return "Watch"
        #else
        return "Other"
        #endif
    }

    private static let jsonEncoder = JSONEncoder()
    
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
    
    static func isStringType(_ value: Any) -> Bool {
        return (value is String)
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
    
    static func getConditionString<T: Encodable>(conditions: T) -> String {
        if let jsonData = try? self.jsonEncoder.encode(conditions), let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "Invalid conditions format."
    }
    
    // valid versions: 3.0, 2.1.2, 1.0.0-beta, ...
    // invalid versions: "mac os 10.3", ...
    static func isValidVersion(_ version: String) -> Bool {
        let comps = version.split(separator: ".")
        return comps.count > 1 && Int(comps.first!) != nil
    }

}
