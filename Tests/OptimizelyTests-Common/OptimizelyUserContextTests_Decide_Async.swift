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

class OptimizelyUserContextTests_Decide_Async: XCTestCase {
    
    let kUserId = "tester"
    
    var optimizely: OptimizelyClient!
    var eventDispatcher = MockEventDispatcher()
    var decisionService: DefaultDecisionService!
    var ups: OPTUserProfileService!
    
    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService()) 
        decisionService = (optimizely.decisionService as! DefaultDecisionService)
        ups = decisionService.userProfileService
        try! optimizely.start(datafile: datafile)
    }
    
    func testDecideAsync() {
        let expectation = XCTestExpectation(description: "Async decision completed")
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId)
        
        user.decideAsync(key: featureKey) { decision in
            XCTAssertEqual(decision.variationKey, "variation_with_traffic")
            XCTAssertTrue(decision.enabled)
            XCTAssertTrue(NSDictionary(dictionary: decision.variables.toMap()).isEqual(to: variablesExpected.toMap()))
            XCTAssertEqual(decision.ruleKey, "exp_no_audience")
            XCTAssertEqual(decision.flagKey, featureKey)
            XCTAssertEqual(decision.userContext, user)
            XCTAssert(decision.reasons.isEmpty)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
    
    func testDecideAsyncCompletionOrder() {
        let expectation = XCTestExpectation(description: "Async decision completed")
        let featureKey = "feature_2"
        let user = optimizely.createUserContext(userId: kUserId)
        var operationOrder: [String] = []
        
        operationOrder.append("before")
        
        user.decideAsync(key: featureKey) { decision in
            operationOrder.append("during")
            expectation.fulfill()
        }
        operationOrder.append("after")
        
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(operationOrder, ["before", "after", "during"])
    }
    
    func testDecideForKeys_twoFeaturesAsync() {
        // Create expectation
        let expectation = XCTestExpectation(description: "Multiple features decision completed")
        
        // Setup test data
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKeys = [featureKey1, featureKey2]
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        
        // Make async decision
        user.decideAsync(keys: featureKeys) { decisions in
            // Verify number of decisions
            XCTAssertEqual(decisions.count, 2)
            
            // Verify first feature decision
            XCTAssertNotNil(decisions[featureKey1])
            XCTAssertEqual(decisions[featureKey1]!, OptimizelyDecision(
                variationKey: "a",
                enabled: true,
                variables: variablesExpected1,
                ruleKey: "exp_with_audience",
                flagKey: featureKey1,
                userContext: user,
                reasons: []
            ))
            
            // Verify second feature decision
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
            
            expectation.fulfill()
        }
        
        // Wait for async operation to complete
        wait(for: [expectation], timeout: 1)
    }
    
    //MARK: - Decide All Async
    
    func testDecideAllAsync() {
        let expectation = XCTestExpectation(description: "All decisions completed")
        
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKey3 = "feature_3"
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON.createEmpty()
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        
        user.decideAllAsync { decisions in
            XCTAssertEqual(decisions.count, 3)
            
            XCTAssertNotNil(decisions[featureKey1])
            XCTAssertEqual(decisions[featureKey1]!, OptimizelyDecision(
                variationKey: "a",
                enabled: true,
                variables: variablesExpected1,
                ruleKey: "exp_with_audience",
                flagKey: featureKey1,
                userContext: user,
                reasons: []
            ))
            
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
            
            XCTAssertNotNil(decisions[featureKey3])
            XCTAssertEqual(decisions[featureKey3]!, OptimizelyDecision(
                variationKey: nil,
                enabled: false,
                variables: variablesExpected3,
                ruleKey: nil,
                flagKey: featureKey3,
                userContext: user,
                reasons: []
            ))
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDecideAllAsync_enabledOnly() {
        let expectation = XCTestExpectation(description: "Enabled flags decisions completed")
        
        let featureKey1 = "feature_1"
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        
        user.decideAllAsync(options: [.enabledFlagsOnly]) { decisions in
            XCTAssertEqual(decisions.count, 2)
            
            XCTAssertNotNil(decisions[featureKey1])
            XCTAssertEqual(decisions[featureKey1]!, OptimizelyDecision(
                variationKey: "a",
                enabled: true,
                variables: variablesExpected1,
                ruleKey: "exp_with_audience",
                flagKey: featureKey1,
                userContext: user,
                reasons: []
            ))
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}

extension OptimizelyUserContextTests_Decide_Async {
    
    func testDecideAsync_sdkNotReady() {
        let expectation = XCTestExpectation(description: "SDK not ready decision")
        let featureKey = "feature_1"
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        
        let user = optimizely.createUserContext(userId: kUserId)
        user.decideAsync(key: featureKey) { decision in
            XCTAssertNil(decision.variationKey)
            XCTAssertFalse(decision.enabled)
            XCTAssertTrue(decision.variables.isEmpty)
            XCTAssertNil(decision.ruleKey)
            XCTAssertEqual(decision.flagKey, featureKey)
            XCTAssertEqual(decision.userContext, user)
            
            XCTAssertEqual(decision.reasons.count, 1)
            XCTAssertEqual(decision.reasons.first, OptimizelyError.sdkNotReady.reason)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDecideAsync_sdkNotReady_optimizelyReleased() {
        let expectation = XCTestExpectation(description: "SDK released decision")
        let featureKey = "feature_1"
        
        var optimizelyClient: OptimizelyClient! = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        try! optimizelyClient.start(datafile: datafile)
        
        let user = optimizelyClient.createUserContext(userId: kUserId)
        
        // Release client to simulate weak reference becoming nil
        optimizelyClient = nil
        
        user.decideAsync(key: featureKey) { decision in
            XCTAssertNil(decision.variationKey)
            XCTAssertEqual(decision.reasons.count, 1)
            XCTAssertEqual(decision.reasons.first, OptimizelyError.sdkNotReady.reason)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDecideAsync_invalidFeatureKey() {
        let expectation = XCTestExpectation(description: "Invalid feature key decision")
        let featureKey = "invalid_key"
        
        let user = optimizely.createUserContext(userId: kUserId)
        
        user.decideAsync(key: featureKey) { decision in
            XCTAssertNil(decision.variationKey)
            XCTAssertFalse(decision.enabled)
            XCTAssertTrue(decision.variables.isEmpty)
            XCTAssertNil(decision.ruleKey)
            XCTAssertEqual(decision.reasons.count, 1)
            XCTAssertEqual(decision.reasons.first, OptimizelyError.featureKeyInvalid(featureKey).reason)
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    // MARK: - Decide For Keys Async
    
    func testDecideForKeysAsync_sdkNotReady() {
        let expectation = XCTestExpectation(description: "SDK not ready multiple decisions")
        let featureKeys = ["feature_1"]
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        
        let user = optimizely.createUserContext(userId: kUserId)
        user.decideAsync(keys: featureKeys) { decisions in
            XCTAssertEqual(decisions.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDecideForKeysAsync_sdkNotReady_optimizelyReleased() {
        let expectation = XCTestExpectation(description: "SDK released multiple decisions")
        let featureKeys = ["feature_1"]
        
        var optimizelyClient: OptimizelyClient! = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        try! optimizelyClient.start(datafile: datafile)
        
        let user = optimizelyClient.createUserContext(userId: kUserId)
        
        optimizelyClient = nil
        
        user.decideAsync(keys: featureKeys) { decisions in
            XCTAssertEqual(decisions.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
    
    func testDecideForKeysAsync_errorDecisionIncluded() {
        let expectation = XCTestExpectation(description: "Error decision included")
        let featureKey1 = "feature_2"
        let featureKey2 = "invalid_key"
        let featureKeys = [featureKey1, featureKey2]
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId)
        
        user.decideAsync(keys: featureKeys) { decisions in
            XCTAssertEqual(decisions.count, 2)
            
            XCTAssertEqual(decisions[featureKey1], OptimizelyDecision(
                variationKey: "variation_with_traffic",
                enabled: true,
                variables: variablesExpected1,
                ruleKey: "exp_no_audience",
                flagKey: featureKey1,
                userContext: user,
                reasons: []
            ))
            
            XCTAssertEqual(decisions[featureKey2], OptimizelyDecision.errorDecision(
                key: featureKey2,
                user: user,
                error: .featureKeyInvalid(featureKey2)
            ))
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}

extension OptimizelyUserContextTests_Decide_Async {
    // MARK: - Concurrent Tests
    
    func testDecideAsync_multipleConcurrentRequests() {
        let expectations = [
            XCTestExpectation(description: "First decision"),
            XCTestExpectation(description: "Second decision"),
            XCTestExpectation(description: "Third decision")
        ]
        
        let featureKeys = ["feature_1", "feature_2", "feature_3"]
        let user = optimizely.createUserContext(userId: kUserId)
        
        // Make concurrent requests
        for (index, key) in featureKeys.enumerated() {
            user.decideAsync(key: key) { _ in
                expectations[index].fulfill()
            }
        }
        
        wait(for: expectations, timeout: 1)
    }
    
    // MARK: - Memory Tests
    
    func testDecideAsync_memoryLeak() {
        let expectation = XCTestExpectation(description: "Memory leak check")
        weak var weakUser: OptimizelyUserContext?
        
        autoreleasepool {
            let user = optimizely.createUserContext(userId: kUserId)
            weakUser = user
            
            user.decideAsync(key: "feature_1") { _ in
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 1)
        XCTAssertNil(weakUser, "User context should be deallocated")
    }
    
    // MARK: - Edge Cases
    
    func testDecideAsync_emptyFeatureKey() {
        let expectation = XCTestExpectation(description: "Empty key decision")
        
        let user = optimizely.createUserContext(userId: kUserId)
        user.decideAsync(key: "") { decision in
            XCTAssertFalse(decision.enabled)
            XCTAssertEqual(decision.reasons.first, OptimizelyError.featureKeyInvalid("").reason)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1)
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension OptimizelyUserContextTests_Decide_Async {
    
    func testDecideAsyncAwait() async {
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(
            featureKey: featureKey,
            userId: kUserId
        )
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decision = await user.decideAsync(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertTrue(decision.enabled)
        XCTAssertTrue(NSDictionary(dictionary: decision.variables.toMap())
            .isEqual(to: variablesExpected.toMap()))
        XCTAssertEqual(decision.ruleKey, "exp_no_audience")
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
    func testDecideForKeysAsyncAwait() async {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKeys = [featureKey1, featureKey2]
        
        let user = optimizely.createUserContext(
            userId: kUserId,
            attributes: ["gender": "f"]
        )
        
        let decisions = await user.decideAsync(keys: featureKeys)
        XCTAssertEqual(decisions.count, 2)
        
        XCTAssertEqual(decisions[featureKey1]?.variationKey, "a")
        XCTAssertEqual(decisions[featureKey2]?.variationKey, "variation_with_traffic")
    }
    
    func testDecideAllAsyncAwait() async {
        let user = optimizely.createUserContext(
            userId: kUserId,
            attributes: ["gender": "f"]
        )
        
        let decisions = await user.decideAllAsync()
        XCTAssertEqual(decisions.count, 3)
        
        XCTAssertEqual(decisions["feature_1"]?.variationKey, "a")
        XCTAssertEqual(decisions["feature_2"]?.variationKey, "variation_with_traffic")
        XCTAssertNil(decisions["feature_3"]?.variationKey)
    }
    
    func testDecideAsyncAwait_sdkNotReady() async {
        self.optimizely = OptimizelyClient(sdkKey: "12345")
        let user = optimizely.createUserContext(userId: kUserId)
        
        let decision = await user.decideAsync(key: "feature_1")
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.reasons.first, OptimizelyError.sdkNotReady.reason)
    }
}

fileprivate class MockCmabService: DefaultCmabService {
    var variationId: String?
    var error: Error?
    var decisionCalled = false
    var decisionCallCount = 0
    var lastRuleKey: String?
    var ignoreCacheUsed = false
    
    init() {
        super.init(cmabClient: DefaultCmabClient(), cmabCache: CmabCache(size: 10, timeoutInSecs: 10))
    }
    
    override func getDecision(config: ProjectConfig, userContext: OptimizelyUserContext, ruleId: String, options: [OptimizelyDecideOption]) -> Result<CmabDecision, any Error> {
        decisionCalled = true
        decisionCallCount += 1
        lastRuleKey = ruleId
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

