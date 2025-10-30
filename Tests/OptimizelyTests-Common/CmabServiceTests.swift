//
// Copyright 2015, Optimizely, Inc. and contributors 
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

fileprivate class MockCmabClient: CmabClient {
    var fetchDecisionResult: Result<String, Error> = .success("variation-1")
    var fetchDecisionCalled = false
    var lastRuleId: String?
    var lastUserId: String?
    var lastAttributes: [String: Any?]?
    var lastCmabUUID: String?
    
    func fetchDecision(
        ruleId: String,
        userId: String,
        attributes: [String: Any?],
        cmabUUID: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        fetchDecisionCalled = true
        lastRuleId = ruleId
        lastUserId = userId
        lastAttributes = attributes
        lastCmabUUID = cmabUUID
        completion(fetchDecisionResult)
    }
    
    func reset() {
        fetchDecisionCalled = false
        lastRuleId = nil
        lastUserId = nil
        lastAttributes = nil
        lastCmabUUID = nil
    }
}

fileprivate class MockProjectConfig: ProjectConfig {
    override init() {
        super.init()
        let data: [String: Any] = ["id": "11111",
                                   "key": "empty",
                                   "status": "Running",
                                   "layerId": "22222",
                                   "variations": [],
                                   "trafficAllocation": [],
                                   "audienceIds": [],
                                   "forcedVariations": ["12345": "1234567890"]]
        
        let cmab = Cmab(trafficAllocation: 1000, attributeIds: ["attr1", "attr2"])
        
        var model1: Experiment = try! OTUtils.model(from: data)
        model1.id = "exp-123"
        model1.cmab = cmab
        
        var model2: Experiment = try! OTUtils.model(from: data)
        model2.id = "exp-124"
        
        allExperiments = [model1, model2]
        updateProjectDependentProps()
        
    }
    
    override func updateProjectDependentProps() {
        self.experimentKeyMap = {
            var map = [String: Experiment]()
            allExperiments.forEach { exp in
                map[exp.key] = exp
            }
            return map
        }()
        
        self.experimentIdMap = {
            var map = [String: Experiment]()
            allExperiments.forEach { map[$0.id] = $0 }
            return map
        }()

        let attribute1 = Attribute(id: "attr1", key: "age")
        let attribute2 = Attribute(id: "attr2", key: "location")
        
        attributeIdMap["attr1"] = attribute1
        attributeIdMap["attr2"] = attribute2
        attributeKeyMap["age"] = attribute1
        attributeIdMap["location"] = attribute2
    }
    
}

class MockUserContext: OptimizelyUserContext {
    convenience init(userId: String, attributes: [String: Any?]) {
        let client = OptimizelyClient(sdkKey: "sdk-key-123")
        self.init(optimizely: client, userId: userId, attributes: attributes)
    }
}


class DefaultCmabServiceTests: XCTestCase {
    fileprivate var cmabClient: MockCmabClient!
    fileprivate var config: MockProjectConfig!
    var cmabCache: CmabCache!
    var cmabService: DefaultCmabService!
    var userContext: OptimizelyUserContext!
    let userAttributes: [String: Any] = ["age": 25, "location": "San Francisco"]
    
    override func setUp() {
        super.setUp()
        config = MockProjectConfig()
        cmabClient = MockCmabClient()
        cmabCache = CmabCache(size: 10, timeoutInSecs: 10)
        cmabService = DefaultCmabService(cmabClient: cmabClient, cmabCache: cmabCache)
        // Set up user context
        userContext = MockUserContext(userId: "test-user", attributes: userAttributes)
    }
    
    override func tearDown() {
        cmabClient = nil
        cmabCache = nil
        cmabService = nil
        config = nil
        userContext = nil
        super.tearDown()
    }
    
    func testHashAttributesDeterminism() {
        // Different order, same attributes
        let attributes1: [String: Any?] = ["c": 3, "a": 1, "b": 2]
        let attributes2: [String: Any?] = ["a": 1, "b": 2, "c": 3]
        
        // Access private method for testing
        let hash1 = cmabService.hashAttributes(attributes1)
        let hash2 = cmabService.hashAttributes(attributes2)
        
        XCTAssertEqual(hash1, hash2, "Hashes should be deterministic regardless of attribute order")
        
        // Different attributes should have different hashes
        let attributes3: [String: Any?] = ["a": 1, "b": 2, "c": 4]  // Changed value
        let hash3 = cmabService.hashAttributes(attributes3)
        
        XCTAssertNotEqual(hash1, hash3, "Different attributes should have different hashes")
    }
    
    func testFilterAttributes() {
        // Set up the user attributes that include both relevant and irrelevant ones
        let userAttributes: [String: Any?] = [
            "age": 25,
            "country": "USA",
            "irrelevant": "value"
        ]
        
        userContext = MockUserContext(userId: "test-user", attributes: userAttributes)
        
        let expectation = self.expectation(description: "fetchDecision")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [],
                                completion: { _ in
            // Check that only the relevant attributes were passed to the client
            XCTAssertEqual(self.cmabClient.lastAttributes?.count, 1) // Only 'age' is found in the config
            XCTAssertEqual(self.cmabClient.lastAttributes?["age"] as? Int, 25)
            XCTAssertNil(self.cmabClient.lastAttributes?["irrelevant"] ?? nil)
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testGetCacheKey() {
        let userId = "test-user"
        let ruleId = "exp-123"
        
        let cacheKey = cmabService.getCacheKey(userId: userId, ruleId: ruleId)
        
        XCTAssertEqual(cacheKey, "9-test-user-exp-123")
        
        // Test with a different user
        let cacheKey2 = cmabService.getCacheKey(userId: "other-user", ruleId: ruleId)
        
        XCTAssertEqual(cacheKey2, "10-other-user-exp-123")
    }
    
    
    func testFetchDecision() {
        let expectation = self.expectation(description: "fetchDecision")
        
        cmabClient.fetchDecisionResult = .success("variation-123")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [],
                                completion: { result in
            
            switch result {
                case .success(let decision):
                    XCTAssertEqual(decision.variationId, "variation-123")
                    XCTAssertEqual(self.cmabClient.lastRuleId, "exp-123")
                    XCTAssertEqual(self.cmabClient.lastUserId, "test-user")
                    // We expect only the 'age' attribute as that's what's configured in the experiment
                    XCTAssertEqual(self.cmabClient.lastAttributes?.count, 2)
                    XCTAssertEqual(self.cmabClient.lastAttributes?["age"] as? Int, 25)
                    XCTAssertEqual(self.cmabClient.lastAttributes?["location"] as? String, "San Francisco")
                    
                    // Verify it was cached
                    let cacheKey = "9-test-user-exp-123"
                    XCTAssertNotNil(self.cmabCache.lookup(key: cacheKey))
                    
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCachedDecision() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        
        let cacheValue = CmabCacheValue(attributesHash: attributesHash,
                                        variationId: "cached-variation",
                                        cmabUUID: "cached-uuid")
        
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        let expectation = self.expectation(description: "fetchDecision")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [],
                                completion: { result in
            
            switch result {
                case .success(let decision):
                    XCTAssertEqual(decision.variationId, "cached-variation")
                    XCTAssertEqual(decision.cmabUUID, "cached-uuid")
                    XCTAssertFalse(self.cmabClient.fetchDecisionCalled, "Should not call API when cache hit")
                    
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCacheInvalidationWithChangedAttributes() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(attributesHash: attributesHash,
                                        variationId: "cached-variation",
                                        cmabUUID: "cached-uuid")
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        // When attributes change, the hash should be different and the cache should be invalid
        userContext = MockUserContext(userId: "test-user", attributes: ["age": 25])
        
        let expectation = self.expectation(description: "fetchDecision")
        
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [],
                                completion: { result in
            
            switch result {
                case .success(let decision):
                    XCTAssertEqual(decision.variationId, "new-variation")
                    XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API when attributes change")
                    
                    // Verify cache was updated
                    let newCacheValue = self.cmabCache.lookup(key: cacheKey)
                    XCTAssertNotNil(newCacheValue)
                    XCTAssertEqual(newCacheValue?.variationId, "new-variation")
                    
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    
    func testIgnoreCmabCacheOption() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(attributesHash: attributesHash,
                                        variationId: "cached-variation",
                                        cmabUUID: "cached-uuid")
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        let expectation = self.expectation(description: "fetchDecision")
        
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [.ignoreCmabCache],
                                completion: { result in
            
            switch result {
                case .success(let decision):
                    XCTAssertEqual(decision.variationId, "new-variation")
                    XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should always call API when ignoreCmabCache option is set")
                    
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testResetCmabCacheOption() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(attributesHash: attributesHash,
                                        variationId: "cached-variation",
                                        cmabUUID: "cached-uuid")
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        // Also add another item to the cache to verify it's cleared too
        let otherCacheKey = "other-key"
        cmabCache.save(key: otherCacheKey, value: cacheValue)
        
        let expectation = self.expectation(description: "fetchDecision")
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [.resetCmabCache],
                                completion: { result in
            
            switch result {
                case .success(let decision):
                    XCTAssertEqual(decision.variationId, "new-variation")
                    XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API after resetting cache")
                    
                    // Verify the entire cache was reset
                    XCTAssertNil(self.cmabCache.lookup(key: otherCacheKey))
                    
                    // But the new decision should be cached
                    XCTAssertNotNil(self.cmabCache.lookup(key: cacheKey))
                    
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testInvalidateUserCmabCacheOption() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let userCacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(attributesHash: attributesHash,
                                        variationId: "cached-variation",
                                        cmabUUID: "cached-uuid")
        cmabCache.save(key: userCacheKey, value: cacheValue)
        
        // Also add another user to the cache to verify it's NOT cleared
        let otherUserCacheKey = "other-user-key"
        cmabCache.save(key: otherUserCacheKey, value: cacheValue)
        
        let expectation = self.expectation(description: "fetchDecision")
        
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [.invalidateUserCmabCache],
                                completion: { result in
            
            switch result {
                case .success(let decision):
                    XCTAssertEqual(decision.variationId, "new-variation")
                    XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API after invalidating user cache")
                    
                    // Verify only the specific user's cache was invalidated
                    XCTAssertNotNil(self.cmabCache.lookup(key: otherUserCacheKey), "Other users' cache should remain intact")
                    
                    // The new decision should be cached for the current user
                    XCTAssertNotNil(self.cmabCache.lookup(key: userCacheKey))
                    XCTAssertEqual(self.cmabCache.lookup(key: userCacheKey)?.variationId, "new-variation")
                    
                case .failure(let error):
                    XCTFail("Expected success but got error: \(error)")
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testFailedFetch() {
        let expectation = self.expectation(description: "fetchDecision")
        
        let testError = CmabClientError.fetchFailed("Test error")
        cmabClient.fetchDecisionResult = .failure(testError)
        
        cmabService.getDecision(config: config,
                                userContext: userContext,
                                ruleId: "exp-123",
                                options: [],
                                completion: { result in
            
            switch result {
                case .success:
                    XCTFail("Expected failure but got success")
                    
                case .failure(let error):
                    XCTAssertEqual((error as? CmabClientError)?.message, "Test error")
                    
                    // Verify no caching of failed results
                    let cacheKey = "9-test-user-exp-123"
                    XCTAssertNil(self.cmabCache.lookup(key: cacheKey))
            }
            
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 1.0)
    }
}

extension DefaultCmabServiceTests {
    func testSyncFetchDecision() {
        cmabClient.fetchDecisionResult = .success("variation-123")
        
        let result = cmabService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        )
        
        switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "variation-123")
                XCTAssertEqual(self.cmabClient.lastRuleId, "exp-123")
                XCTAssertEqual(self.cmabClient.lastUserId, "test-user")
                XCTAssertEqual(self.cmabClient.lastAttributes?.count, 2)
                XCTAssertEqual(self.cmabClient.lastAttributes?["age"] as? Int, 25)
                XCTAssertEqual(self.cmabClient.lastAttributes?["location"] as? String, "San Francisco")
                
                // Verify it was cached
                let cacheKey = "9-test-user-exp-123"
                XCTAssertNotNil(self.cmabCache.lookup(key: cacheKey))
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testSyncCachedDecision() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(
            attributesHash: attributesHash,
            variationId: "cached-variation",
            cmabUUID: "cached-uuid"
        )
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        let result = cmabService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        )
        
        switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "cached-variation")
                XCTAssertEqual(decision.cmabUUID, "cached-uuid")
                XCTAssertFalse(self.cmabClient.fetchDecisionCalled, "Should not call API when cache hit")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testSyncFailedFetch() {
        let testError = CmabClientError.fetchFailed("Test error")
        cmabClient.fetchDecisionResult = .failure(testError)
        
        let result = cmabService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        )
        
        switch result {
            case .success:
                XCTFail("Expected failure but got success")
                
            case .failure(let error):
                XCTAssertEqual((error as? CmabClientError)?.message, "Test error")
                
                // Verify no caching of failed results
                let cacheKey = "9-test-user-exp-123"
                XCTAssertNil(self.cmabCache.lookup(key: cacheKey))
        }
    }
    
    func testSyncIgnoreCmabCacheOption() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(
            attributesHash: attributesHash,
            variationId: "cached-variation",
            cmabUUID: "cached-uuid"
        )
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        let result = cmabService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: [.ignoreCmabCache]
        )
        
        switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "new-variation")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should always call API when ignoreCmabCache option is set")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testSyncResetCmabCacheOption() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let cacheKey = "9-test-user-exp-123"
        let cacheValue = CmabCacheValue(
            attributesHash: attributesHash,
            variationId: "cached-variation",
            cmabUUID: "cached-uuid"
        )
        cmabCache.save(key: cacheKey, value: cacheValue)
        
        // Also add another item to verify it's cleared
        let otherCacheKey = "other-key"
        cmabCache.save(key: otherCacheKey, value: cacheValue)
        
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        let result = cmabService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: [.resetCmabCache]
        )
        
        switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "new-variation")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API after resetting cache")
                
                // Verify the entire cache was reset
                XCTAssertNil(self.cmabCache.lookup(key: otherCacheKey))
                
                // But the new decision should be cached
                XCTAssertNotNil(self.cmabCache.lookup(key: cacheKey))
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testSyncInvalidateUserCmabCacheOption() {
        // First, put something in the cache
        let attributesHash = cmabService.hashAttributes(["age": 25, "location": "San Francisco"])
        let userCacheKey = "9-test-user-exp-123"
        let otherUserCacheKey = "other-user-key"
        
        let cacheValue = CmabCacheValue(
            attributesHash: attributesHash,
            variationId: "cached-variation",
            cmabUUID: "cached-uuid"
        )
        
        // Cache for both current user and another user
        cmabCache.save(key: userCacheKey, value: cacheValue)
        cmabCache.save(key: otherUserCacheKey, value: cacheValue)
        
        cmabClient.fetchDecisionResult = .success("new-variation")
        
        let result = cmabService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: [.invalidateUserCmabCache]
        )
        
        switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "new-variation")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API after invalidating user cache")
                
                // Verify only the specific user's cache was invalidated
                XCTAssertNotNil(self.cmabCache.lookup(key: otherUserCacheKey), "Other users' cache should remain intact")
                
                // The new decision should be cached for the current user
                XCTAssertNotNil(self.cmabCache.lookup(key: userCacheKey))
                XCTAssertEqual(self.cmabCache.lookup(key: userCacheKey)?.variationId, "new-variation")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
        }
    }
    
}

extension DefaultCmabServiceTests {
    
    func testCacheSizeZero() {
        // Create a cache with size 0 (no caching)
        let zeroCmabCache = CmabCache(size: 0, timeoutInSecs: 10)
        let zeroCacheService = DefaultCmabService(cmabClient: cmabClient, cmabCache: zeroCmabCache)
        
        cmabClient.fetchDecisionResult = .success("variation-first")
        
        let expectation1 = self.expectation(description: "first request")
        
        // First request
        zeroCacheService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        ) { result in
            switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "variation-first")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API on first request")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 1.0)
        
        // Reset and change the variation
        cmabClient.reset()
        cmabClient.fetchDecisionResult = .success("variation-second")
        
        let expectation2 = self.expectation(description: "second request")
        
        // Second request - should NOT use cache (size = 0)
        zeroCacheService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        ) { result in
            switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "variation-second")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API again when cache size is 0")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func testCacheTimeoutZero() {
        // Create a cache with timeout 0 (immediate expiration)
        let zeroTimeoutCache = CmabCache(size: 10, timeoutInSecs: 0)
        let zeroTimeoutService = DefaultCmabService(cmabClient: cmabClient, cmabCache: zeroTimeoutCache)
        
        cmabClient.fetchDecisionResult = .success("variation-first")
        
        let expectation1 = self.expectation(description: "first request")
        
        // First request
        zeroTimeoutService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        ) { result in
            switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "variation-first")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API on first request")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 1.0)
        
        // Reset and change the variation
        cmabClient.reset()
        cmabClient.fetchDecisionResult = .success("variation-second")
        
        // Small delay to ensure cache timeout
        Thread.sleep(forTimeInterval: 1.1)
        
        let expectation2 = self.expectation(description: "second request")
        
        // Second request - should NOT use cache (timeout = 0, cache expired)
        zeroTimeoutService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        ) { result in
            switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "variation-second")
                XCTAssertTrue(self.cmabClient.fetchDecisionCalled, "Should call API again when cache timeout is 0")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
    }
    
    func testCacheSizeZeroAndTimeoutZero() {
        // Create a cache with both size 0 and timeout 0 (completely disabled)
        let disabledCache = CmabCache(size: 0, timeoutInSecs: 0)
        let disabledCacheService = DefaultCmabService(cmabClient: cmabClient, cmabCache: disabledCache)
        
        cmabClient.fetchDecisionResult = .success("variation-1")
        
        let expectation1 = self.expectation(description: "first request")
        
        // First request
        disabledCacheService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        ) { result in
            switch result {
            case .success(let decision):
                XCTAssertEqual(decision.variationId, "variation-1")
                
            case .failure(let error):
                XCTFail("Expected success but got error: \(error)")
            }
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 1.0)
        
        let apiCallCount1 = cmabClient.fetchDecisionCalled ? 1 : 0
        
        // Reset and make multiple requests
        cmabClient.reset()
        cmabClient.fetchDecisionResult = .success("variation-2")
        
        let expectation2 = self.expectation(description: "second request")
        
        disabledCacheService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        ) { result in
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
        
        let apiCallCount2 = cmabClient.fetchDecisionCalled ? 1 : 0
        
        XCTAssertEqual(apiCallCount1, 1, "First request should call API")
        XCTAssertEqual(apiCallCount2, 1, "Second request should also call API (no caching)")
    }
    
    func testSyncCacheSizeZero() {
        // Create a cache with size 0
        let zeroCmabCache = CmabCache(size: 0, timeoutInSecs: 10)
        let zeroCacheService = DefaultCmabService(cmabClient: cmabClient, cmabCache: zeroCmabCache)
        
        cmabClient.fetchDecisionResult = .success("variation-first")
        
        // First request
        let result1 = zeroCacheService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        )
        
        switch result1 {
        case .success(let decision):
            XCTAssertEqual(decision.variationId, "variation-first")
            XCTAssertTrue(cmabClient.fetchDecisionCalled, "Should call API on first request")
            
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
        
        // Reset and change variation
        cmabClient.reset()
        cmabClient.fetchDecisionResult = .success("variation-second")
        
        // Second request - should NOT use cache
        let result2 = zeroCacheService.getDecision(
            config: config,
            userContext: userContext,
            ruleId: "exp-123",
            options: []
        )
        
        switch result2 {
        case .success(let decision):
            XCTAssertEqual(decision.variationId, "variation-second")
            XCTAssertTrue(cmabClient.fetchDecisionCalled, "Should call API again when cache size is 0")
            
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
}
