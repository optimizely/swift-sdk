//
//  CustomLogger.swift
//  DemoSwiftiOS
//
//  Created by Jae Kim on 1/29/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import OptimizelySwiftSDK

class CustomLogger: OPTLogger {
    static var logLevel: OPTLogLevel = .error
    
    static func createInstance(logLevel: OPTLogLevel) -> OPTLogger? {
        return CustomLogger()
    }
    
    func log(level: OPTLogLevel, message: String) {
        
    }
    
    
}
