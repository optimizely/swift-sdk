//
//  DefaultLogger.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/5/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public class DefaultLogger : Logger {
    private static var _logLevel:OptimizelyLogLevel?
    public static var logLevel: OptimizelyLogLevel {
        get {
            return _logLevel ?? .OptimizelyLogLevelAll
        }
        set (newLevel){
            if _logLevel == nil {
                _logLevel = newLevel
            }
        }
    }
    
    private init(level:OptimizelyLogLevel) {
        DefaultLogger.logLevel = level
    }
    
    public static func createInstance(logLevel: OptimizelyLogLevel) -> Logger? {
        return DefaultLogger(level:logLevel)
    }
    
    public func log(level: OptimizelyLogLevel, message: String) {
        if level.rawValue > DefaultLogger.logLevel.rawValue {
            return
        }
        let message = "[OPTIMIZELY SDK][" + DefaultLogger.logLevelNames[level.rawValue] + "]:" + message
        NSLog(message)
    }
    
    
}
