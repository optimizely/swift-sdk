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

class MultiClientsTests: XCTestCase {
    let testSdkKeyBasename = "testSdkKey"
    var sdkKeys = [String]()

    override func setUp() {
        OTUtils.clearAllBinders()
        OTUtils.createDocumentDirectoryIfNotAvailable()
        OTUtils.clearAllTestStorage(including: testSdkKeyBasename)
    }

    override func tearDown() {
        OTUtils.clearAllTestStorage(including: testSdkKeyBasename)
    }

    func testMultiClients() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        sdkKeys = OTUtils.makeRandomSdkKeys(numThreads)

        let datafile = OTUtils.loadJSONDatafileString("decide_datafile")

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { thIdx, sdkKey in
            let datafileHandler = MockDatafileHandler(statusCode: 200, localResponseData: datafile)
            let eventDispatcher = DumpEventDispatcher(dataStoreName: "OPTEventQueue-\(sdkKey)",
                                                      timerInterval: 0)

            let client = OptimizelyClient(sdkKey: sdkKey,
                                          eventDispatcher: eventDispatcher,
                                          datafileHandler: datafileHandler,
                                          periodicDownloadInterval: 1,
                                          defaultLogLevel: .debug)
            
            let group = DispatchGroup()
            group.enter()
            
            client.start { result in
                let expectedDatafile = datafileHandler.getDatafile(sdkKey: sdkKey)

                switch result {
                case .success(let data):
                    let str = String(data: data, encoding: .utf8)
                    XCTAssert(str == expectedDatafile)
                default:
                    XCTAssert(false)
                }
                
                for i in 0..<numEventsPerThread {
                    let userId = String(i)
                    let user = client.createUserContext(userId: userId)
                    var decision = user.decide(key: "feature_2")
                    
                    XCTAssertEqual(decision.variationKey, "variation_with_traffic")
                    XCTAssertTrue(decision.enabled)
                    XCTAssertEqual(decision.ruleKey, "exp_no_audience")
                    XCTAssertEqual(decision.userContext, user)
                    XCTAssert(decision.reasons.isEmpty)
                    
                    decision = user.decide(key: "feature_3")
                    
                    XCTAssertNil(decision.variationKey)
                    XCTAssertFalse(decision.enabled)
                    XCTAssertNil(decision.ruleKey)
                    XCTAssertEqual(decision.userContext, user)
                    XCTAssert(decision.reasons.isEmpty)
                }
                
                eventDispatcher.close()
                sleep(1)
                XCTAssertEqual(eventDispatcher.totalEventsSent, 2 * numEventsPerThread)

                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

    func testMultiClients_sharedEventDispatcher() {
        let numThreads = 10
        let numEventsPerThread = 20
        
        sdkKeys = OTUtils.makeRandomSdkKeys(numThreads)

        let datafile = OTUtils.loadJSONDatafileString("decide_datafile")
        let sharedEventDispatcher = DumpEventDispatcher(timerInterval: 0)

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { thIdx, sdkKey in
            let datafileHandler = MockDatafileHandler(statusCode: 200, localResponseData: datafile)
            
            let client = OptimizelyClient(sdkKey: sdkKey,
                                          eventDispatcher: sharedEventDispatcher,
                                          datafileHandler: datafileHandler,
                                          periodicDownloadInterval: 1,
                                          defaultLogLevel: .debug)
            
            let group = DispatchGroup()
            group.enter()
            
            client.start { result in
                let expectedDatafile = datafileHandler.getDatafile(sdkKey: sdkKey)

                switch result {
                case .success(let data):
                    let str = String(data: data, encoding: .utf8)
                    XCTAssert(str == expectedDatafile)
                default:
                    XCTAssert(false)
                }
                
                for i in 0..<numEventsPerThread {
                    let userId = String(i)
                    let user = client.createUserContext(userId: userId)
                    var decision = user.decide(key: "feature_2")
                    
                    XCTAssertEqual(decision.variationKey, "variation_with_traffic")
                    XCTAssertTrue(decision.enabled)
                    XCTAssertEqual(decision.ruleKey, "exp_no_audience")
                    XCTAssertEqual(decision.userContext, user)
                    XCTAssert(decision.reasons.isEmpty)
                    
                    decision = user.decide(key: "feature_3")
                    
                    XCTAssertNil(decision.variationKey)
                    XCTAssertFalse(decision.enabled)
                    XCTAssertNil(decision.ruleKey)
                    XCTAssertEqual(decision.userContext, user)
                    XCTAssert(decision.reasons.isEmpty)
                }
                
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
        
        sharedEventDispatcher.close()
        sleep(1)
        XCTAssertEqual(sharedEventDispatcher.totalEventsSent, 2 * numThreads * numEventsPerThread)
    }

}
