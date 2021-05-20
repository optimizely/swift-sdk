//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

import XCTest

class LoggerTests: XCTestCase {

    let logger = TestLogger()
    
    func testOPTLogger_DefaultMethods() {
        // String messages
        
        let message = "Log Message"
        
        logger.e(message)
        verifyLogger(.error, message)
        logger.w(message)
        verifyLogger(.warning, message)
        logger.i(message)
        verifyLogger(.info, message)
        logger.d(message)
        verifyLogger(.debug, message)
        
        // LogMessage
        
        let logMessage = LogMessage.experimentNotRunning("key")
        
        logger.e(logMessage)
        verifyLogger(.error, logMessage.description)
        logger.w(logMessage)
        verifyLogger(.warning, logMessage.description)
        logger.i(logMessage)
        verifyLogger(.info, logMessage.description)
        logger.d(logMessage)
        verifyLogger(.debug, logMessage.description)

        // OptimizelyError
        
        let error = OptimizelyError.sdkNotReady
        let errorMessage = "(src) " + error.reason
        
        logger.e(error, source: "src")
        verifyLogger(.error, errorMessage)
        logger.w(error, source: "src")
        verifyLogger(.warning, errorMessage)
        logger.i(error, source: "src")
        verifyLogger(.info, errorMessage)
        logger.d(error, source: "src")
        verifyLogger(.debug, errorMessage)
    }

    func testOPTLogger_DebugLog() {
        TestLogger.logLevel = .debug
        logger.d { () -> String in
            return "message"
        }
        XCTAssertTrue(logger.logCount == 1)
        XCTAssertEqual(logger.getMessages(.debug), ["message"])
        logger.clearMessages()

        TestLogger.logLevel = .info
        logger.d { () -> String in
            return "message"
        }
        XCTAssertTrue(logger.logCount == 0)
    }

    // MARK: - DefaultLogger Tests

    func testDefaultLogger_DebugLevel() {
        let logger = TestDefaultLogger()
        DefaultLogger.setLogLevel(.debug)
        
        logger.e("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.w("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.i("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.d("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
    }
    
    func testDefaultLogger_InfoLevel() {
        let logger = TestDefaultLogger()
        DefaultLogger.setLogLevel(.info)

        logger.e("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.w("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.i("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.d("message")
        XCTAssert(logger.logCount == 0)
    }
    
    func testDefaultLogger_WarningLevel() {
        let logger = TestDefaultLogger()
        DefaultLogger.setLogLevel(.warning)

        logger.e("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.w("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.i("message")
        XCTAssert(logger.logCount == 0)
        logger.d("message")
        XCTAssert(logger.logCount == 0)
    }
 
    func testDefaultLogger_ErrorLevel() {
        let logger = TestDefaultLogger()
        DefaultLogger.setLogLevel(.error)

        logger.e("message")
        XCTAssert(logger.logCount > 0); logger.logCount = 0
        logger.w("message")
        XCTAssert(logger.logCount == 0)
        logger.i("message")
        XCTAssert(logger.logCount == 0)
        logger.d("message")
        XCTAssert(logger.logCount == 0)
    }

}

// MARK: - Utils

extension LoggerTests {

    func verifyLogger(_ logLevel: OptimizelyLogLevel, _ message: String) {
        XCTAssertTrue(logger.logCount == 1)
        XCTAssertEqual(logger.getMessages(logLevel), [message])
        logger.clearMessages()
    }
    
}

// MARK: - Mock Loggers

class TestLogger: OPTLogger {
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
        clearMessages()
    }
    
    func log(level: OptimizelyLogLevel, message: String) {
        logMessages[level.rawValue].append(message)
    }
    
    // Utils
    
    var logMessages = [[String]]()
    var logCount: Int {
        return logMessages.reduce(0) { $0 + $1.count }
    }
    
    func getMessages(_ level: OptimizelyLogLevel) -> [String] {
        return logMessages[level.rawValue]
    }
    
    func clearMessages() {
        logMessages = [[String]](repeating: [], count: OptimizelyLogLevel.debug.rawValue + 1)
    }
}

class TestDefaultLogger: DefaultLogger {
    var logCount = 0
    override func clog(level: OptimizelyLogLevel, message: String) {
        logCount += 1
    }
}


