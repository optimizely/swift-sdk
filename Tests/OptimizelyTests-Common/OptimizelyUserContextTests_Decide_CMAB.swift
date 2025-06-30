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

import XCTest

class OptimizelyUserContextTests_Decide_CMAB: XCTestCase {
    
    let kUserId = "tester"
    
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var eventDispatcher = MockEventDispatcher()
    var decisionService: DefaultDecisionService!
    fileprivate var mockCmabService: MockCmabService!
    
    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        mockCmabService = MockCmabService()
        decisionService = DefaultDecisionService(userProfileService: DefaultUserProfileService(), cmabService: mockCmabService)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        optimizely.decisionService = decisionService
        self.config = self.optimizely.config
        try! optimizely.start(datafile: datafile)
    }
    
    override func tearDown() {
        optimizely = nil
        mockCmabService = nil
        decisionService = nil
    }
    
    func testDecideAsync_withCmabExperiment() {
        let expectation = XCTestExpectation(description: "CMAB decision completed")
        // Set up the CMAB experiment
        let cmab: Cmab = try! OTUtils.model(from: ["trafficAllocation": 10000, "attributeIds": ["10389729780"]])
        var experiments = optimizely.config!.project.experiments
        experiments[0].cmab = cmab
        optimizely.config?.project.experiments = experiments
        mockCmabService.variationId = "10389729780" // corresponds to variation "a"
        
        // Create user with attributes that match CMAB experiment
        let user = optimizely.createUserContext(
            userId: kUserId,
            attributes: ["gender": "f", "age": 25]
        )
        
        // Run the decision
        user.decideAsync(key: "feature_1") { decision in
            // Verify decision
            XCTAssertEqual(decision.variationKey, "a", "Expected variation key 'a' but got \(String(describing: decision.variationKey))")
            XCTAssertTrue(decision.enabled, "Expected feature to be enabled but was disabled")
            XCTAssertEqual(decision.ruleKey, "exp_with_audience", "Expected rule id 'exp_with_audience' but got \(String(describing: decision.ruleKey))")
            
            // Verify CMAB service was called
            XCTAssertTrue(self.mockCmabService.decisionCalled, "CMAB decision service was not called")
            XCTAssertEqual(self.mockCmabService.lastRuleId, "10390977673", "Expected CMAB rule id '10390977673' but got \(String(describing: self.mockCmabService.lastRuleId))")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5) // Increased timeout for reliability
    }
    
    func testDecideAsync_multipleCmabExperiments() {
        let expectation = XCTestExpectation(description: "CMAB decision completed")
        
        // Set up multiple CMAB experiments
        // First experiment with zero traffic allocation - user won't be bucketed into this experiment
        let cmab1: Cmab = try! OTUtils.model(from: ["trafficAllocation": 0, "attributeIds": ["10389729780"]])
        // Second experiment with full traffic allocation - user should be bucketed into this experiment
        let cmab2: Cmab = try! OTUtils.model(from: ["trafficAllocation": 10000, "attributeIds": ["10418551353"]])
        
        // Update project configuration with CMAB experiments
        var experiments = optimizely.config!.project.experiments
        experiments[0].cmab = cmab1
        experiments[1].cmab = cmab2
        optimizely.config?.project.experiments = experiments
        
        // Configure mock CMAB service to return specific variation
        mockCmabService.variationId = "10418551353" // corresponds to variation "a"
        
        // Define feature keys to test with
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKeys = [featureKey1, featureKey2]
        
        // Pre-fetch expected variable values for validation
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        
        // Create test user context with attributes
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        
        // Test multiple decisions with decideAsync
        user.decideAsync(keys: featureKeys, options: [.ignoreUserProfileService]) { decisions in
            
            // Verify correct number of decisions were returned
            XCTAssertEqual(decisions.count, 2)
            
            // Verify CMAB service was called the correct number of times
            XCTAssertEqual(self.mockCmabService.decisionCallCount, 1)
            
            // Verify first feature decision matches expected values
            XCTAssertNotNil(decisions[featureKey1])
            XCTAssertEqual(decisions[featureKey1]!, OptimizelyDecision(
                variationKey: "18257766532",
                enabled: true,
                variables: variablesExpected1,
                ruleKey: "18322080788",
                flagKey: featureKey1,
                userContext: user,
                reasons: []
            ))
            
            // Verify second feature decision matches expected values
            XCTAssertNotNil(decisions[featureKey2])
            XCTAssertEqual(decisions[featureKey2]!, OptimizelyDecision(
                variationKey: "variation_with_traffic",
                enabled: true,
                variables: variablesExpected2,
                ruleKey: "exp_no_audience",
                flagKey: featureKey2,
                userContext: user,
                reasons: []
            ))

            // Verify CMAB service was correctly called with the expected parameters
            XCTAssertTrue(self.mockCmabService.decisionCalled, "CMAB decision service was not called")
            XCTAssertEqual(self.mockCmabService.lastRuleId, "10420810910", "Expected CMAB rule id '10390977673' but got \(String(describing: self.mockCmabService.lastRuleId))")
            
            expectation.fulfill()
        }
        
        // Wait for async operations to complete
        wait(for: [expectation], timeout: 5) // Increased timeout for reliability
    }
    
    func testDecideAsync_cmabWithCaching() {
        let expectation1 = XCTestExpectation(description: "First CMAB decision")
        let expectation2 = XCTestExpectation(description: "Second CMAB decision")
        
        // Set up the CMAB experiment
        let cmab: Cmab = try! OTUtils.model(from: ["trafficAllocation": 10000, "attributeIds": ["10389729780"]])
        var experiments = optimizely.config!.project.experiments
        experiments[0].cmab = cmab
        optimizely.config?.project.experiments = experiments
        mockCmabService.variationId = "10389729780" // corresponds to variation "a"
        
        // Create user with attributes that match CMAB experiment
        let user = optimizely.createUserContext(
            userId: kUserId,
            attributes: ["gender": "f", "age": 25]
        )
        
        // First decision
        user.decideAsync(key: "feature_1") { decision in
            XCTAssertEqual(decision.variationKey, "a")
            XCTAssertEqual(self.mockCmabService.decisionCallCount, 1)
            expectation1.fulfill()
            
            // Second decision (should use cache)
            user.decideAsync(key: "feature_1") { decision in
                XCTAssertEqual(decision.variationKey, "a")
                // Call count should still be 1 (cached)
                XCTAssertEqual(self.mockCmabService.decisionCallCount, 1)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 1)
    }
    // FixMe: Need to fix the test case
//    func testDecideAsync_cmabWithIgnoreCache() {
//        let expectation = XCTestExpectation(description: "CMAB ignore cache")
//        // Set up the CMAB experiment
//        let cmab: Cmab = try! OTUtils.model(from: ["trafficAllocation": 10000, "attributeIds": ["10389729780"]])
//        var experiments = optimizely.config!.project.experiments
//        experiments[0].cmab = cmab
//        optimizely.config?.project.experiments = experiments
//        mockCmabService.variationId = "10389729780" // corresponds to variation "a"
//        
//        // Create user with attributes that match CMAB experiment
//        let user = optimizely.createUserContext(
//            userId: kUserId,
//            attributes: ["gender": "f", "age": 25]
//        )
//        
//        // Make decision with ignoreCmabCache option
//        user.decideAsync(
//            key: "feature_1",
//            options: [.ignoreCmabCache, .ignoreUserProfileService]
//        ) { decision in
//            XCTAssertEqual(decision.variationKey, "a")
//            XCTAssertTrue(self.mockCmabService.decisionCalled)
//            XCTAssertTrue(self.mockCmabService.ignoreCacheUsed)
//            expectation.fulfill()
//        }
//        
//        wait(for: [expectation], timeout: 1)
//    }
 
    
    
    func testDecideAsync_cmabError() {
        let expectation = XCTestExpectation(description: "CMAB error handling")
        // Set up the CMAB experiment
        let cmab: Cmab = try! OTUtils.model(from: ["trafficAllocation": 10000, "attributeIds": ["10389729780"]])
        var experiments = optimizely.config!.project.experiments
        experiments[0].cmab = cmab
        optimizely.config?.project.experiments = experiments
        mockCmabService.variationId = "10389729780" // corresponds to variation "a"
        mockCmabService.error = CmabClientError.fetchFailed("Test error")
        
        // Create user with attributes that match CMAB experiment
        let user = optimizely.createUserContext(
            userId: kUserId,
            attributes: ["gender": "f", "age": 25]
        )
        
        user.decideAsync(key: "feature_1", options: [.ignoreUserProfileService, .includeReasons]) { decision in
            XCTAssertTrue(decision.reasons.contains(LogMessage.cmabFetchFailed("exp_with_audience").reason))
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
}


fileprivate class MockCmabService: DefaultCmabService {
    var variationId: String?
    var error: Error?
    var decisionCalled = false
    var decisionCallCount = 0
    var lastRuleId: String?
    var ignoreCacheUsed = false
    
    init() {
        super.init(cmabClient: DefaultCmabClient(), cmabCache: LruCache(size: 10, timeoutInSecs: 10))
    }
    
    override func getDecision(config: ProjectConfig, userContext: OptimizelyUserContext, ruleId: String, options: [OptimizelyDecideOption]) -> Result<CmabDecision, any Error> {
        decisionCalled = true
        decisionCallCount += 1
        lastRuleId = ruleId
        ignoreCacheUsed = options.contains(.ignoreCmabCache)
        
        if let error = error {
            return .failure(error)
        }
        
        if let variationId = variationId {
            return .success(CmabDecision(
                variationId: variationId,
                cmabUUID: "test-uuid"
            ))
        }
        
        return .failure(CmabClientError.fetchFailed("No variation set"))
    }
}
