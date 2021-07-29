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
    
    func testDatafileUpdateConcurrent() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("empty_traffic_allocation")!
        try! optimizely.start(datafile: datafile)
        
        let result = OTUtils.runConcurrent(count: 100, timeoutInSecs: 60) { idx in
            for _ in 0..<100 {
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
    
    func testDatafileUpdateConcurrent_2() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("empty_traffic_allocation")!
        try! optimizely.start(datafile: datafile)
        
        let result = OTUtils.runConcurrent(count: 10, timeoutInSecs: 60) { idx in
            for _ in 0..<100 {
                let config = try! ProjectConfig(datafile: datafile)
                optimizely.config = config
                
                let logger = OPTLoggerFactory.getLogger()
                logger.e("e-level message")

                // verify log call not conflicted with concurrent config update
                _ = optimizely.isFeatureEnabled(featureKey: "feature_1", userId: "tester")
            }
            
            print("Testing: testDatafileUpdateConcurrent_2: \(idx)")
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

}
