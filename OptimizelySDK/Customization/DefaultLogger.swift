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

open class DefaultLogger : OPTLogger {
    private static var _logLevel: OptimizelyLogLevel?
    public static var logLevel: OptimizelyLogLevel {
        get {
            return _logLevel ?? .all
        }
        set (newLevel){
            if _logLevel == nil {
                _logLevel = newLevel
            }
        }
    }
    
    required public init() {
        DefaultLogger.logLevel = .all
    }
    
    open func log(level: OptimizelyLogLevel, message: String) {
        if level.rawValue > DefaultLogger.logLevel.rawValue {
            return
        }
        let message = "[OPTIMIZELY SDK][" + level.name + "]:" + message
        NSLog(message)
    }
}
