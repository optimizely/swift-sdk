//
// Copyright 2022, Optimizely, Inc. and contributors 
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
import XCTest

class OptimizelyClientTests_Cmab_Config: XCTestCase {
    
    var optimizely: OptimizelyClient!
    
    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
    }
    
    override func tearDown() {
        Utils.sdkVersion = OPTIMIZELYSDKVERSION
        Utils.swiftSdkClientName = "swift-sdk"
    }
    
    // MARK: - ODP configuration
    
    func test_config_default()  {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let cmabService = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        let cmabCache = cmabService.cmabCache
        let cmabClient = cmabService.cmabClient as! DefaultCmabClient
        XCTAssertEqual(100, cmabCache.maxSize)
        XCTAssertEqual(30 * 60, cmabCache.timeoutInSecs)
        XCTAssertEqual("https://prediction.cmab.optimizely.com/predict/%@", cmabClient.predictionEndpoint)
    }
    
    func test_cmab_custom_config()  {
        var cmabConfig = CmabConfig(cacheSize: 50, cacheTimeoutInSecs: 120)
        var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, cmabConfig: cmabConfig)
        var cmabService = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        var cmabCache = cmabService.cmabCache
        var cmabClient = cmabService.cmabClient as! DefaultCmabClient
        XCTAssertEqual(50, cmabCache.maxSize)
        XCTAssertEqual(120, cmabCache.timeoutInSecs)
        XCTAssertEqual("https://prediction.cmab.optimizely.com/predict/rule_123", cmabClient.getUrl(ruleId: "rule_123")?.absoluteString)
        
        cmabConfig = CmabConfig(cacheSize: 50, cacheTimeoutInSecs: -10, predictionEndpoint: "http://demo.cmab.com/%@/predict")
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, cmabConfig: cmabConfig)
        cmabService = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        cmabCache = cmabService.cmabCache
        cmabClient = cmabService.cmabClient as! DefaultCmabClient
        XCTAssertEqual(50, cmabCache.maxSize)
        XCTAssertEqual(1800, cmabCache.timeoutInSecs)
        XCTAssertEqual("http://demo.cmab.com/rule_1234/predict", cmabClient.getUrl(ruleId: "rule_1234")?.absoluteString)
        
        cmabConfig = CmabConfig(predictionEndpoint: "http://fowardslash.com/predict/%@/v1/")
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, cmabConfig: cmabConfig)
        cmabService = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        cmabCache = cmabService.cmabCache
        cmabClient = cmabService.cmabClient as! DefaultCmabClient
        XCTAssertEqual(100, cmabCache.maxSize)
        XCTAssertEqual(1800, cmabCache.timeoutInSecs)
        XCTAssertEqual("http://fowardslash.com/predict/rule-12345/v1/", cmabClient.getUrl(ruleId: "rule-12345")?.absoluteString)
    }
}
