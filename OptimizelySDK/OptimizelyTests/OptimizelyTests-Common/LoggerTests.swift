//
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
    

import XCTest

class LoggerTests: XCTestCase {

    func testDebugLog() {
        CustomLogger.logCount = 0
        let logger = CustomLogger()
        CustomLogger.logLevel = .debug
        logger.d { () -> String in
            return "Log Message"
        }
        XCTAssertTrue(CustomLogger.logCount == 1)
        
        CustomLogger.logCount = 0
        CustomLogger.logLevel = .info
        logger.d { () -> String in
            return "Log Message"
        }
        XCTAssertTrue(CustomLogger.logCount == 0)
    }
}

// MARK: - DefaultLogger Tests

extension LoggerTests {
    
    func testLog_UseOSLog() {
        let logger = DefaultLogger()
        logger.i("Log Message")
        
        if #available(iOS 10.0, tvOS 10.0, *) {
            XCTAssertTrue(logger.osLogUsed)
        } else {
            XCTAssertFalse(logger.osLogUsed)
        }
    }
    
}

private class CustomLogger: OPTLogger {
    public static var logCount = 0
    private static var _logLevel: OptimizelyLogLevel?
    public static var logLevel: OptimizelyLogLevel {
        get {
            return _logLevel ?? .info
        }
        set (newLevel) {
            _logLevel = newLevel
        }
    }
    
    required public init() {
    }
    
    func log(level: OptimizelyLogLevel, message: String) {
        CustomLogger.logCount += 1
    }
}

