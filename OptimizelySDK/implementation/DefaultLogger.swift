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

public class DefaultLogger : OPTLogger {
    private static var _logLevel: OPTLogLevel?
    public static var logLevel: OPTLogLevel {
        get {
            return _logLevel ?? .all
        }
        set (newLevel){
            if _logLevel == nil {
                _logLevel = newLevel
            }
        }
    }
    
    public init(level: OPTLogLevel) {
        DefaultLogger.logLevel = level
    }
    
    public static func createInstance(logLevel: OPTLogLevel) -> OPTLogger? {
        return DefaultLogger(level:logLevel)
    }
    
    public func log(level: OPTLogLevel, message: String) {
        if level.rawValue > DefaultLogger.logLevel.rawValue {
            return
        }
        let message = "[OPTIMIZELY SDK][" + level.name + "]:" + message
        NSLog(message)
    }
}
