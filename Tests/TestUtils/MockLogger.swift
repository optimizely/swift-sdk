//
// Copyright 2021, Optimizely, Inc. and contributors 
// 
// Licensed under the Apache License, Version 2.0 (the "License");  
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at   
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class MockLogger: OPTLogger {
    static var logFound = false
    static var expectedLog = ""
    private static var _logLevel: OptimizelyLogLevel?
    
    public static var logLevel: OptimizelyLogLevel {
        get {
            return _logLevel ?? .info
        }
        set (newLevel){
            if _logLevel == nil {
                _logLevel = newLevel
            }
        }
    }
    
    required public init() {
        MockLogger.logLevel = .info
    }
    
    open func log(level: OptimizelyLogLevel, message: String) {
        if  ("[Optimizely][Error] " + message) == MockLogger.expectedLog {
            MockLogger.logFound = true
        }
    }
}

