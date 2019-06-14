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
import os.log

open class DefaultLogger: OPTLogger {
    private static var _logLevel: OptimizelyLogLevel?
    public static var logLevel: OptimizelyLogLevel {
        get {
            return _logLevel ?? .info
        }
        set (newLevel) {
            if _logLevel == nil {
                _logLevel = newLevel
                return
            }
        }
    }
    
    var osLogUsed = false
    
    required public init() {
    }
    
    open func log(level: OptimizelyLogLevel, message: String) {
        if level > DefaultLogger.logLevel {
            return
        }
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            var osLogType: OSLogType
            
            switch level {
            case .error: osLogType = .error
            case .info: osLogType = .info
            case .debug: osLogType = .debug
            default: osLogType = .default
            }
            
            os_log("[%{public}@] %{public}@", log: .optimizely, type: osLogType, level.name, message)
            osLogUsed = true
        } else {
            let message = "[OPTIMIZELY][" + level.name + "] " + message
            NSLog(message)
        }
    }
}

@available(iOS 10.0, tvOS 10.0, *)
extension OSLog {
    static let optimizely = OSLog(subsystem: "com.optimizely.swift-sdk", category: "OPTIMIZELY")
}
