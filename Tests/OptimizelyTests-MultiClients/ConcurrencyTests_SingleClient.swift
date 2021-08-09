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

class ConcurrencyTests_SingleClient: XCTestCase {
    
    override func setUp() {
        super.setUp()
        HandlerRegistryService.shared.binders.property?.removeAll()
    }

    func testDatafileUpdateConcurrent() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("empty_traffic_allocation")!
        try! optimizely.start(datafile: datafile)
        
        let numThreads = 50
        let numRepeats = 50
        // these may be too much - test crashes with resources issue?
        //let numThreads = 100
        //let numRepeats = 100
        
        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 180) { idx in
            for _ in 0..<numRepeats {
                let config = try! ProjectConfig(datafile: datafile)
                optimizely.config = config
                
                // verify log call not conflicted with concurrent config update
                _ = optimizely.isFeatureEnabled(featureKey: "feature_1", userId: "tester")
                _ = try? optimizely.activate(experimentKey: "exp_no_audience", userId: "tester")
            }
            
            print("Testing: testDatafileUpdateConcurrent: \(idx)")
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    // OPTLogger.getLogger() should be called with lazy mode or after HandlerRegistryService is completely set for logger.
    // This test validates that the logger for each type is created properly after the custom logger is registered successfully.
    func testLoggerCreatedProperlyOnClientInitialization() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                          logger: MockLogger())
        let datafile = OTUtils.loadJSONDatafile("empty_traffic_allocation")!
        try! optimizely.start(datafile: datafile)
        
        let message = OptimizelyError.invalidJSONVariable
        MockLogger.expectedLog = message.localizedDescription
      
        MockLogger.logFound = false
        optimizely.logger.i(message)
        XCTAssert(MockLogger.logFound)

        MockLogger.logFound = false
        (optimizely.datafileHandler as! DefaultDatafileHandler).logger.i(message)
        XCTAssert(MockLogger.logFound)
        
        MockLogger.logFound = false
        (optimizely.eventDispatcher as! DefaultEventDispatcher).logger.i(message)
        XCTAssert(MockLogger.logFound)
        
        MockLogger.logFound = false
        (optimizely.decisionService as! DefaultDecisionService).logger.i(message)
        XCTAssert(MockLogger.logFound)
        
        MockLogger.logFound = false
        ((optimizely.decisionService as! DefaultDecisionService).bucketer as! DefaultBucketer).logger.i(message)
        XCTAssert(MockLogger.logFound)
        
        MockLogger.logFound = false
        optimizely.createUserContext(userId: "tester").logger.i(message)
        XCTAssert(MockLogger.logFound)
        
        MockLogger.logFound = false
        optimizely.config!.logger.i(message)
        XCTAssert(MockLogger.logFound)

        MockLogger.logFound = false
        optimizely.config!.project.logger.i(message)
        XCTAssert(MockLogger.logFound)
    }

}
