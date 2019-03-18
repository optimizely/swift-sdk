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
    
    static func isBoolType(_ value: Any) -> Bool {
        return (value is Bool) && type(of: value) != type(of: NSNumber(value: 0))
    }
    
    static func isIntType(_ value: Any) -> Bool {
        return (value is Int) && type(of: value) != type(of: NSNumber(value: true))
    }
    
    static func isDoubleType(_ value: Any) -> Bool {
        return (value is Double) && type(of: value) != type(of: NSNumber(value: true))
    }
    
    static func isFloatType(_ value: Any) -> Bool {
        return (value is Float) && type(of: value) != type(of: NSNumber(value: true))
    }

}
