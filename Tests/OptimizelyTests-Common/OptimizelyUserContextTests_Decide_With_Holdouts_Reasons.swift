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

class OptimizelyUserContextTests_Decide_With_Holdouts_Reasons: XCTestCase {
    let kUserId = "tester"
    var optimizely: OptimizelyClient!
    
    var kAttributesCountryMatch: [String: Any] = ["country": "US"]
    var kAttributesCountryNotMatch: [String: Any] = ["country": "ca"]
    
    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "id_holdout",
            "key": "key_holdout",
            "trafficAllocation": [
                ["entityId": "id_holdout_variation", "endOfRange": 500]
            ],
            "audienceIds": [],
            "variations": [
                [
                    "variables": [],
                    "id": "id_holdout_variation",
                    "key": "key_holdout_variation"
                ]
            ],
            "includedFlags": [],
            "excludedFlags": []
        ]
    }
    
    override func setUp() {
        super.setUp()
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      userProfileService: OTUtils.createClearUserProfileService())
        
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("decide_datafile")!)
    }
    
    /// Test when user is bucketed into the global holdout
    func testDecideReasons_userBucketedIntoGlobalHoldout() {
        let featureKey = "feature_1"
        
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let user = optimizely.createUserContext(userId: kUserId)
        // Call decide with reasons
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        // Assertions
        XCTAssertEqual(decision.flagKey, "feature_1", "Expected flagKey to be 'feature_1'")
        XCTAssertEqual(decision.variationKey, "key_holdout_variation", "Expected variationKey to be 'key_holdout_variation'")
        XCTAssertFalse(decision.enabled, "Feature should be disabled in holdout")
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoVariationInHoldout(kUserId, "key_holdout", "key_holdout_variation").reason))
    }
    
    /// Test when user is bucketed into the included flags holdout for feature_1
    func testDecideReasons_userBucketedIntoIncludedHoldout() {
        let featureKey = "feature_1"
        let featureId = "4482920077"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedFlags = [featureId]
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let user = optimizely.createUserContext(userId: kUserId)
        // Call decide with reasons
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        // Assertions
        XCTAssertEqual(decision.flagKey, "feature_1", "Expected flagKey to be 'feature_1'")
        XCTAssertEqual(decision.variationKey, "key_holdout_variation", "Expected variationKey to be 'key_holdout_variation'")
        XCTAssertFalse(decision.enabled, "Feature should be disabled in holdout")
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoVariationInHoldout(kUserId, "key_holdout", "key_holdout_variation").reason))
    }
    
    /// Test when user is not bucketed into any holdout for feature_2 (excluded)
    func testDecideReasons_userNotBucketedIntoExcludedHoldout() {
        // Global holdout with 5% traffice
        let holdout1 = try! OTUtils.model(from: sampleHoldout) as Holdout
        
        let featureKey_2 = "feature_2"
        let featureId_2 = "4482920078"
        
        var holdout2 = holdout1
        holdout2.id = "id_holdout_2"
        holdout2.key = "key_holdout_2"
        
        // Global holdout with 10% traffice (featureId_2 excluded)
        holdout2.trafficAllocation[0].endOfRange = 1000
        holdout2.excludedFlags = [featureId_2]
        
        // Bucket valud outside global holdout range but inside second holdout range
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 600))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout1, holdout2]
        
        let user = optimizely.createUserContext(userId: kUserId)
        // Call decide with reasons
        let decision = user.decide(key: featureKey_2, options: [.includeReasons])
        
        // Assertions
        XCTAssertEqual(decision.flagKey, "feature_2", "Expected flagKey to be 'feature_2'")
        XCTAssert(decision.reasons.contains(LogMessage.userNotBucketedIntoHoldoutVariation(kUserId).reason))
    }
    
    /// Test when holdout is not running
    func testDecideReasons_holdoutNotRunning() {
        let featureKey = "feature_1"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.status = .draft
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let user = optimizely.createUserContext(userId: kUserId)
        
        // Call decide with reasons
        let decision = user.decide(key: featureKey, options: [.includeReasons])
    
        /// Doesn't get holdout decision, because holdout isn't running
        /// Get decision for feature flag 1
        XCTAssertEqual(decision.flagKey, "feature_1", "Expected flagKey to be 'feature_1'")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertTrue(decision.enabled)
        XCTAssert(decision.reasons.contains(LogMessage.holdoutNotRunning("key_holdout").reason))
    }
    
    
    /// Test when user  meets audience conditions for holdout
    func testDecideReasons_userDoesMeetConditionsForHoldout() {
        let featureKey = "feature_1"
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        //  Audience "13389130056" requires "country" = "US"
        holdout.audienceIds = ["13389130056"]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout]
        
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        // Call decide with reasons
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        
        // Assertions
        XCTAssertEqual(decision.flagKey, "feature_1", "Expected flagKey to be 'feature_1'")
        XCTAssertEqual(decision.variationKey, "key_holdout_variation", "Expected variationKey to be 'key_holdout_variation'")
        XCTAssertFalse(decision.enabled, "Feature should be disabled in holdout")
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoVariationInHoldout(kUserId, "key_holdout", "key_holdout_variation").reason))
        XCTAssert(decision.reasons.contains(LogMessage.userMeetsConditionsForHoldout(kUserId, "key_holdout").reason))
    }
    
    /// Test when user does not meet audience conditions for holdout
    func testDecideReasons_userDoesntMeetConditionsForHoldout() {
        let featureKey = "feature_1"
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        //  Audience "13389130056" requires "country" = "US"
        holdout.audienceIds = ["13389130056"]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout]
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryNotMatch)
        // Call decide with reasons
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        
        XCTAssertEqual(decision.flagKey, "feature_1", "Expected flagKey to be 'feature_1'")
        XCTAssertNotEqual(decision.variationKey, "key_holdout_variation", "Expected variationKey not to be 'key_holdout_variation'")
        XCTAssertFalse(decision.reasons.contains(LogMessage.userBucketedIntoVariationInHoldout(kUserId, "key_holdout", "key_holdout_variation").reason))
        XCTAssert(decision.reasons.contains(LogMessage.userDoesntMeetConditionsForHoldout(kUserId, "key_holdout").reason))
    }
}
