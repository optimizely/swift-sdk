//
//  OPTLogger+Register.swift
//  OptimizelySwiftSDK-iOS
//
//  Created by Thomas Zurkan on 1/16/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

private var OPTLoggerRegistry : Dictionary<String,((OptimizelyLogLevel)->OPTLogger)> = Dictionary<String,((OptimizelyLogLevel)->OPTLogger)>()

extension OPTLogger {
    public static func registerLogger(name:String, builder:@escaping ((OptimizelyLogLevel)->OPTLogger)) {
       OPTLoggerRegistry[name] = builder
    }
    
    public static func buildRegisteredLogger(name:String, level:OptimizelyLogLevel) -> OPTLogger? {
        if let builder = OPTLoggerRegistry[name] {
            return builder(level)
        }
        
        return nil
    }
    
    public static func lookupRegisteredLogger(name:String) -> Bool {
        return OPTLoggerRegistry[name] != nil
    }
}
