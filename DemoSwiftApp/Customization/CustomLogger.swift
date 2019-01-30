//
//  CustomLogger.swift
//  DemoSwiftiOS
//
//  Created by Jae Kim on 1/29/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import Optimizely

class CustomLogger: OPTLogger {
    static var logLevel: OptimizelyLogLevel = .error
    
    static func createInstance(logLevel: OptimizelyLogLevel) -> OPTLogger? {
        return CustomLogger()
    }
    
    func log(level: OptimizelyLogLevel, message: String) {
        
    }
    
    
}
