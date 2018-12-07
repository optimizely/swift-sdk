//
//  DefaultLogger.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/5/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class DefaultLogger : Logger {
    private static var _logLevel:OptimizelyLogLevel?
    static var logLevel: OptimizelyLogLevel {
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
    
    static func createInstance(logLevel: OptimizelyLogLevel) -> Logger? {
        return DefaultLogger(level:logLevel)
    }
    
    func log(level: OptimizelyLogLevel, message: String) {
        if level.rawValue > DefaultLogger.logLevel.rawValue {
            return
        }
        let message = "[OPTIMIZELY SDK][" + DefaultLogger.logLevelNames[level.rawValue] + "]:" + message
        NSLog(message)
    }
    
    
}
