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

    // MARK: - Re-initialization with Same SDK Key

    func test_cmab_reinitialization_same_sdkKey_updates_config() {
        let sdkKey = "test-sdk-key-reinit"

        // First initialization with 3 second timeout
        let config1 = CmabConfig(cacheSize: 10, cacheTimeoutInSecs: 3,
                                predictionEndpoint: "https://endpoint1.com/%@")
        var optimizely = OptimizelyClient(sdkKey: sdkKey, cmabConfig: config1)
        var cmabService = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        var cmabCache = cmabService.cmabCache
        var cmabClient = cmabService.cmabClient as! DefaultCmabClient

        XCTAssertEqual(10, cmabCache.maxSize, "First init: cache size should be 10")
        XCTAssertEqual(3, cmabCache.timeoutInSecs, "First init: cache timeout should be 3")
        XCTAssertEqual("https://endpoint1.com/%@", cmabClient.predictionEndpoint, "First init: should use endpoint1")

        // Re-initialize with SAME sdkKey but different config (5 second timeout)
        let config2 = CmabConfig(cacheSize: 50, cacheTimeoutInSecs: 5,
                                predictionEndpoint: "https://endpoint2.com/%@")
        optimizely = OptimizelyClient(sdkKey: sdkKey, cmabConfig: config2)
        cmabService = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        cmabCache = cmabService.cmabCache
        cmabClient = cmabService.cmabClient as! DefaultCmabClient

        XCTAssertEqual(50, cmabCache.maxSize, "Second init: cache size should be updated to 50")
        XCTAssertEqual(5, cmabCache.timeoutInSecs, "Second init: cache timeout should be updated to 5")
        XCTAssertEqual("https://endpoint2.com/%@", cmabClient.predictionEndpoint, "Second init: endpoint should be updated")
    }

    func test_cmab_different_sdkKeys_maintain_separate_configs() {
        // Initialize first client with sdkKey1
        let sdkKey1 = "test-sdk-key-1"
        let config1 = CmabConfig(cacheSize: 10, cacheTimeoutInSecs: 100)
        let client1 = OptimizelyClient(sdkKey: sdkKey1, cmabConfig: config1)
        let cmabService1 = ((client1.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        let cmabCache1 = cmabService1.cmabCache

        // Initialize second client with sdkKey2
        let sdkKey2 = "test-sdk-key-2"
        let config2 = CmabConfig(cacheSize: 50, cacheTimeoutInSecs: 500)
        let client2 = OptimizelyClient(sdkKey: sdkKey2, cmabConfig: config2)
        let cmabService2 = ((client2.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService)
        let cmabCache2 = cmabService2.cmabCache

        // Verify both clients maintain their own configs independently
        XCTAssertEqual(10, cmabCache1.maxSize, "Client 1 should have cache size 10")
        XCTAssertEqual(100, cmabCache1.timeoutInSecs, "Client 1 should have timeout 100")
        XCTAssertEqual(50, cmabCache2.maxSize, "Client 2 should have cache size 50")
        XCTAssertEqual(500, cmabCache2.timeoutInSecs, "Client 2 should have timeout 500")
    }
}
