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

import XCTest

class LoggerTests_MultiClients: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testConcurrentLogging() {
        OTUtils.bindLoggerForTest(.debug)
        let logger = OPTLoggerFactory.getLogger()

        let numThreads = 10
        let numEventsPerThread = 100
        
        let result = OTUtils.runConcurrent(count: numThreads) { item in
            for _ in 0..<numEventsPerThread {
                logger.e("error-level: \(item)")
                logger.w("warning-level: \(item)")
                logger.i("info-level: \(item)")
                logger.d("debug-level: \(item)")
                
                logger.e(.attributeFormatInvalid, source: String(item))
                logger.w(.attributeFormatInvalid, source: String(item))
                logger.i(.attributeFormatInvalid, source: String(item))
                logger.d(.attributeFormatInvalid, source: String(item))
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    func testConcurrentLogging_MultipleLoggerInstances() {

        let numThreads = 10
        let numEventsPerThread = 100

        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 300) { item in
            OTUtils.bindLoggerForTest(.debug)
            let logger = OPTLoggerFactory.getLogger()

            for _ in 0..<numEventsPerThread {
                logger.e("error-level: \(item)")
                logger.w("warning-level: \(item)")
                logger.i("info-level: \(item)")
                logger.d("debug-level: \(item)")
                
                logger.e(.attributeFormatInvalid, source: String(item))
                logger.w(.attributeFormatInvalid, source: String(item))
                logger.i(.attributeFormatInvalid, source: String(item))
                logger.d(.attributeFormatInvalid, source: String(item))
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

}
