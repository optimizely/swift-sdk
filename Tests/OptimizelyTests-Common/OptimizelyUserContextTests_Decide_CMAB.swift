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
        super.tearDown()
        // Reset mock service state
        mockCmabService?.reset()
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
            
            // Verify impression event
            self.optimizely.eventLock.sync {}
            
            guard let event = self.getFirstEventJSON(client: self.optimizely) else {
                XCTFail("No impression event found")
                expectation.fulfill()
                return
            }
            
            let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
            let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
            let decision = (snapshot["decisions"] as! Array<Dictionary<String, Any>>)[0]
            let metaData = decision["metadata"] as! Dictionary<String, Any>
            
            // Verify event metadata
            XCTAssertEqual(metaData["rule_type"] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(metaData["rule_key"] as! String, "exp_with_audience")
            XCTAssertEqual(metaData["flag_key"] as! String, "feature_1")
            XCTAssertEqual(metaData["variation_key"] as! String, "a")
            XCTAssertEqual(metaData["cmab_uuid"] as? String, "test-uuid")
            XCTAssertTrue(metaData["enabled"] as! Bool)
            
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
        user.decideAsync(keys: featureKeys) { decisions in
            
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
    
    func testDecideAsync_cmabIgnoreUPSCacheing() {
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
        
        
        user.decideAsync(key: "feature_1") { decision in
            XCTAssertEqual(decision.variationKey, "a")
            XCTAssertEqual(self.mockCmabService.decisionCallCount, 1)
            expectation1.fulfill()
            
            // Second decision, ignore UPS, fetch decision again
            user.decideAsync(key: "feature_1") { decision in
                XCTAssertEqual(decision.variationKey, "a")
                // Call count should be increased by 1
                XCTAssertEqual(self.mockCmabService.decisionCallCount, 2)
                expectation2.fulfill()
            }
        }
        
        wait(for: [expectation1, expectation2], timeout: 1)
    }
    
    func testDecideAsync_cmabCacheOptions() {
        let exp1 = XCTestExpectation(description: "First call")
        let exp2 = XCTestExpectation(description: "Second call")
        let exp3 = XCTestExpectation(description: "Third call")


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
        user.decideAsync(key: "feature_1", options: [.ignoreCmabCache]) { decision in
            XCTAssertEqual(decision.variationKey, "a")
            exp1.fulfill()
        }
        user.decideAsync(key: "feature_1", options: [.resetCmabCache]) { decision in
            XCTAssertEqual(decision.variationKey, "a")
            exp2.fulfill()
        }
        user.decideAsync(key: "feature_1", options: [.invalidateUserCmabCache]) { decision in
            XCTAssertEqual(decision.variationKey, "a")
            exp3.fulfill()
        }
        wait(for: [exp1, exp2, exp3], timeout: 1)

        // Ensure all queued decision work has completed before checking captured options
        // decideAsync uses optimizely.decisionQueue, so sync on it to ensure all tasks finish
        optimizely.decisionQueue.sync {}

        // Verify options were passed correctly for each call (thread-safe check after all async calls complete)
        XCTAssertEqual(self.mockCmabService.capturedOptions.count, 3, "Expected 3 calls to getDecision")
        XCTAssertTrue(self.mockCmabService.capturedOptions[0].contains(.ignoreCmabCache), "First call should have ignoreCmabCache option")
        XCTAssertTrue(self.mockCmabService.capturedOptions[1].contains(.resetCmabCache), "Second call should have resetCmabCache option")
        XCTAssertTrue(self.mockCmabService.capturedOptions[2].contains(.invalidateUserCmabCache), "Third call should have invalidateUserCmabCache option")
    }
 
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
        
        user.decideAsync(key: "feature_1", options: [.includeReasons]) { decision in
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
    var resetCacheCache = false
    var invalidateUserCmabCache = false

    // Thread-safe tracking of options for each call to avoid race conditions
    private let optionsLock = DispatchQueue(label: "MockCmabService.optionsLock")
    private var _capturedOptions: [[OptimizelyDecideOption]] = []
    var capturedOptions: [[OptimizelyDecideOption]] {
        optionsLock.sync {
            _capturedOptions
        }
    }

    init() {
        super.init(cmabClient: DefaultCmabClient(), cmabCache: CmabCache(size: 10, timeoutInSecs: 10))
    }

    func reset() {
        optionsLock.sync {
            self.variationId = nil
            self.error = nil
            self.decisionCalled = false
            self.decisionCallCount = 0
            self.lastRuleId = nil
            self.ignoreCacheUsed = false
            self.resetCacheCache = false
            self.invalidateUserCmabCache = false
            self._capturedOptions.removeAll()
        }
    }

    // Override both sync and async versions to ensure all call paths are tracked

    override func getDecision(config: ProjectConfig, userContext: OptimizelyUserContext, ruleId: String, options: [OptimizelyDecideOption]) -> Result<CmabDecision, any Error> {
        // Thread-safe state tracking
        optionsLock.sync {
            self.decisionCalled = true
            self.lastRuleId = ruleId
            self.ignoreCacheUsed = options.contains(.ignoreCmabCache)
            self.resetCacheCache = options.contains(.resetCmabCache)
            self.invalidateUserCmabCache = options.contains(.invalidateUserCmabCache)
            self.decisionCallCount += 1
            self._capturedOptions.append(options)
        }

        // Return mock error if set
        if let error = error {
            return .failure(error)
        }

        // Return mock decision if variationId is set
        if let variationId = variationId {
            return .success(CmabDecision(
                variationId: variationId,
                cmabUUID: "test-uuid"
            ))
        }

        // Otherwise return error
        return .failure(CmabClientError.fetchFailed("No variation set"))
    }

    override func getDecision(config: ProjectConfig, userContext: OptimizelyUserContext, ruleId: String, options: [OptimizelyDecideOption], completion: @escaping CmabDecisionCompletionHandler) {
        // Use sync version to maintain consistency
        let result = getDecision(config: config, userContext: userContext, ruleId: ruleId, options: options)
        completion(result)
    }
}

extension OptimizelyUserContextTests_Decide_CMAB {
    
    func getFirstEvent(dispatcher: MockEventDispatcher) -> EventForDispatch? {
        optimizely.eventLock.sync{}
        return dispatcher.events.first
    }
    
    func getFirstEventJSON(dispatcher: MockEventDispatcher) -> [String: Any]? {
        guard let event = getFirstEvent(dispatcher: dispatcher) else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
    func getFirstEventJSON(client: OptimizelyClient) -> [String: Any]? {
        guard let event = getFirstEvent(dispatcher: client.eventDispatcher as! MockEventDispatcher) else { return nil }
        
        let json = try! JSONSerialization.jsonObject(with: event.body, options: .allowFragments) as! [String: Any]
        return json
    }
    
    func getEventJSON(data: Data) -> [String: Any]? {
        let json = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
        return json
    }
    
}
