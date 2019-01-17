//
//  CustomLogger.swift
//  DemoSwiftiOS
//
//  Created by Thomas Zurkan on 1/16/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import OptimizelySwiftSDK

public class CustomLogger : OPTLogger {
    public static var logLevel: OptimizelyLogLevel {
        get {
            return .all
        }
        set {
            // nope
        }
    }
    
    public required init(level: OptimizelyLogLevel) {
        
    }
    
    public func log(level: OptimizelyLogLevel, message: String) {
        print("CustomLogger:::::" +  CustomLogger.logLevelNames[level.rawValue] + "::::" + message)
    }
    
    
}
