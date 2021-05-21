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

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { thIdx, sdkKey in
            let useDecideDatafile = thIdx % 2 == 0
            
            let datafile = self.selectDatafile(useDecideDatafile)
            let datafileHandler = MockDatafileHandler(statusCode: 200, localResponseData: datafile)
            let eventDispatcher = DumpEventDispatcher(dataStoreName: "OPTEventQueue-\(sdkKey)", timerInterval: 0)

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
                    self.verifyDecisionsForDecideDatafile(userId: String(i), client: client, useDecideDatafile: useDecideDatafile)
                }
                
                eventDispatcher.close()
                sleep(1)
                XCTAssertEqual(eventDispatcher.totalEventsSent, 4 * numEventsPerThread)  // 4 events for each verifyDecisionsForDecideDatafile() call

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
        let sharedEventDispatcher = DumpEventDispatcher(timerInterval: 0)

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { thIdx, sdkKey in
            let useDecideDatafile = thIdx % 2 == 0
            
            let datafile = self.selectDatafile(useDecideDatafile)
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
                    self.verifyDecisionsForDecideDatafile(userId: String(i), client: client, useDecideDatafile: useDecideDatafile)
                }
                
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
        
        sharedEventDispatcher.close()
        sleep(1)
        XCTAssertEqual(sharedEventDispatcher.totalEventsSent, 4 * numThreads * numEventsPerThread)
    }

    // Utils
    
    func selectDatafile(_ useDecideDatafile: Bool) -> String? {
        let datafileName = useDecideDatafile ? "decide_datafile" : "api_datafile"
        return OTUtils.loadJSONDatafileString(datafileName)
    }
    
    func verifyDecisionsForDecideDatafile(userId: String, client: OptimizelyClient, useDecideDatafile: Bool) {
        let user = client.createUserContext(userId: userId)
        
        var decision: OptimizelyDecision
        if useDecideDatafile {
            decision = user.decide(key: "feature_2")
            
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
            
            // legacy APIs
            
            XCTAssertTrue(client.isFeatureEnabled(featureKey: "feature_2", userId: userId))
            XCTAssertFalse(client.isFeatureEnabled(featureKey: "feature_3", userId: userId))
        } else {
            decision = user.decide(key: "feature_1")
            
            XCTAssertEqual(decision.variationKey, "a")
            XCTAssertTrue(decision.enabled)
            XCTAssertEqual(decision.ruleKey, "exp_with_audience")
            XCTAssertEqual(decision.userContext, user)
            XCTAssert(decision.reasons.isEmpty)
            
            decision = user.decide(key: "feature_2")
            
            XCTAssertEqual(decision.variationKey, "variation_with_traffic")
            XCTAssertFalse(decision.enabled)
            XCTAssertEqual(decision.ruleKey, "exp_no_audience")
            XCTAssertEqual(decision.userContext, user)
            XCTAssert(decision.reasons.isEmpty)

            // legacy APIs
            
            XCTAssertTrue(client.isFeatureEnabled(featureKey: "feature_1", userId: userId))
            XCTAssertFalse(client.isFeatureEnabled(featureKey: "feature_2", userId: userId))
        }
    }

}
