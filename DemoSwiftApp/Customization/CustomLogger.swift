//
//  CustomLogger
//  DemoSwiftiOS
//
//  Created by Jae Kim on 1/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import Optimizely

class CustomLogger: OPTLogger {
    
    static var level:OptimizelyLogLevel?
    static var logLevel: OptimizelyLogLevel = .info
    
    required init() {
    }
    
    func log(level: OptimizelyLogLevel, message: String) {
        if level.rawValue <= CustomLogger.logLevel.rawValue {
            print("🐱 - [\(level.name)] Kitty - \(message)")
        }
    }
    
}
