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

class OptimizelyUserContextTests_Decide_Holdouts: XCTestCase {
    let kUserId = "tester"
    var optimizely: OptimizelyClient!
    var eventDispatcher = MockEventDispatcher()
    
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
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("decide_datafile")!)
    }
    
    func test_decide_with_global_holdout_audience_matched() {
        let featureKey = "feature_1"
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        //  Audience "13389130056" requires "country" = "US"
        holdout.audienceIds = ["13389130056"]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout]
        
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        // Call decide with reasons
        let decision = user.decide(key: featureKey)
        
        XCTAssert(decision == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                  enabled: false,
                                                  variables: variablesExpected,
                                                  ruleKey: "key_holdout",
                                                  flagKey: featureKey,
                                                  userContext: user,
                                                  reasons: []))
        

    }
    
    func test_decide_with_gloabl_holdout_audience_mis_matched() {
        let featureKey = "feature_2"
        let featureKeys = [featureKey]
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        //  Audience "13389130056" requires "country" = "US"
        holdout.audienceIds = ["13389130056"]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout]
        
        
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryNotMatch)
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[featureKey]!
        
        let expDecision = OptimizelyDecision(variationKey: "variation_with_traffic",
                                             enabled: true,
                                             variables: variablesExpected,
                                             ruleKey: "exp_no_audience",
                                             flagKey: featureKey,
                                             userContext: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
    func testDecide_ForNullVariation() {
        let featureKey = "feature_2"
        let featureKeys = [featureKey]
        var null_Variation_json = sampleHoldout
        null_Variation_json["variations"] = []
        
        let holdout = try! OTUtils.model(from: null_Variation_json) as Holdout
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout]
        
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryNotMatch)
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[featureKey]!
        
        let expDecision = OptimizelyDecision(variationKey: "variation_with_traffic",
                                             enabled: true,
                                             variables: variablesExpected,
                                             ruleKey: "exp_no_audience",
                                             flagKey: featureKey,
                                             userContext: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
    
    func testDecide_with_holdout_options_excludeVariables() {
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        
        let featureKey = "feature_1"
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey,options: [.excludeVariables])
        XCTAssertEqual(decision.variationKey, "key_holdout_variation")
        XCTAssertFalse(decision.enabled)
        XCTAssertTrue(decision.variables.isEmpty)
    }
    
    func testDecide_defaultDecideOption() {
        let featureKey = "feature_2"
        let feature_id = "4482920078"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedFlags = [feature_id]
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        var user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        var decision = user.decide(key: featureKey)
        
        XCTAssert(decision == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                 enabled: false,
                                                 variables: variablesExpected,
                                                 ruleKey: "key_holdout",
                                                 flagKey: featureKey,
                                                 userContext: user,
                                                 reasons: []))
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      defaultDecideOptions: [.excludeVariables])
        
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("decide_datafile")!)
        optimizely.config!.project.holdouts = [holdout]
        
        user = optimizely.createUserContext(userId: kUserId)
        decision = user.decide(key: featureKey)
        
        XCTAssertTrue(decision.variables.isEmpty)
        
    }
    
    func test_decide_with_holdout_included_flags() {
        let featureKey1 = "feature_1"
        let feature1_Id = "4482920077"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedFlags = [feature1_Id]
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId)
        
        let decision1 = user.decide(key: featureKey1)
        
        XCTAssert(decision1 == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected1,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
    }
    
    func test_decide_for_keys_with_holdout_included_flags() {
        let featureKey1 = "feature_1"
        let feature1_Id = "4482920077"
        let featureKey2 = "feature_2"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedFlags = [feature1_Id]
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId)
        
        let decisions = user.decide(keys: [featureKey1, featureKey2])
        
        XCTAssert(decisions.count == 2)

        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected1,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))

        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                ruleKey: "exp_no_audience",
                                                                flagKey: featureKey2,
                                                                userContext: user,
                                                                reasons: []))
    }
}

// MARK:- Decide All

extension OptimizelyUserContextTests_Decide_Holdouts {
    func testDecideAll_with_global_holdout() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKey3 = "feature_3"
        
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON.createEmpty()
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll()
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected1,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected2,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey2,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected3,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey3,
                                                                userContext: user,
                                                                reasons: []))
    }
    
    func testDecideAll_with_holdout_included_flags() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let feature2_id = "4482920078"
        let featureKey3 = "feature_3"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedFlags = [feature2_id]
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON.createEmpty()
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll()
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "a",
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                ruleKey: "exp_with_audience",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected2,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey2,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: false,
                                                                variables: variablesExpected3,
                                                                ruleKey: nil,
                                                                flagKey: featureKey3,
                                                                userContext: user,
                                                                reasons: []))
    }
    
    func testDecideAll_with_holdout_excluded_flags() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let feature2_id = "4482920078"
        let featureKey3 = "feature_3"
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.excludedFlags = [feature2_id]
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON.createEmpty()
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll()
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected1,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                ruleKey: "exp_no_audience",
                                                                flagKey: featureKey2,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                enabled: false,
                                                                variables: variablesExpected3,
                                                                ruleKey: "key_holdout",
                                                                flagKey: featureKey3,
                                                                userContext: user,
                                                                reasons: []))
    }
    
    func testDecideAll_with_multiple_holdouts() {
        let feature1 = (key: "feature_1", id: "4482920077")
        let feature2 = (key: "feature_2", id: "4482920078")
        let feature3 = (key: "feature_3", id: "44829230000")
        
        /// Applicable to feature (1, 2, 3)
        let gHoldout = try! OTUtils.model(from: sampleHoldout) as Holdout
        
        var includedHoldout = gHoldout
        includedHoldout.id = "holdout_id_included"
        includedHoldout.key = "holdout_key_included"
        includedHoldout.trafficAllocation[0].endOfRange = 2000
        /// Applicable to feature 2
        includedHoldout.includedFlags = [feature2.id]
        
        var excludedHoldout = gHoldout
        excludedHoldout.id = "holdout_id_excluded"
        excludedHoldout.key = "holdout_key_excluded"
        /// Applicable to feature 3
        excludedHoldout.excludedFlags = [feature1.id, feature2.id]
        excludedHoldout.trafficAllocation[0].endOfRange = 2000
        
        optimizely.config!.project.holdouts = [gHoldout, includedHoldout, excludedHoldout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 1000))
        optimizely.decisionService = mockDecisionService
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: feature1.key, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: feature2.key, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON.createEmpty()
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll()
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[feature1.key]! == OptimizelyDecision(variationKey: "a",
                                                                 enabled: true,
                                                                 variables: variablesExpected1,
                                                                 ruleKey: "exp_with_audience",
                                                                 flagKey: feature1.key,
                                                                 userContext: user,
                                                                 reasons: []))
        XCTAssert(decisions[feature2.key]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                 enabled: false,
                                                                 variables: variablesExpected2,
                                                                 ruleKey: "holdout_key_included",
                                                                 flagKey: feature2.key,
                                                                 userContext: user,
                                                                 reasons: []))
        XCTAssert(decisions[feature3.key]! == OptimizelyDecision(variationKey: "key_holdout_variation",
                                                                 enabled: false,
                                                                 variables: variablesExpected3,
                                                                 ruleKey: "holdout_key_excluded",
                                                                 flagKey: feature3.key,
                                                                 userContext: user,
                                                                 reasons: []))
    }
    
    func testDecideAll_with_holdouts_options_enabledFlagsOnly() {
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll(options: [.enabledFlagsOnly])
        
        XCTAssert(decisions.count == 0)
    }
}

// MARK: - impression events

extension OptimizelyUserContextTests_Decide_Holdouts {
    func testDecide_sendImpression() {
        let featureKey = "feature_2"
        
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}
        
        XCTAssertEqual(decision.variationKey, "key_holdout_variation")
        XCTAssertFalse(decision.enabled)
        XCTAssertFalse(eventDispatcher.events.isEmpty)
        
        let eventSent = eventDispatcher.events.first!
        let event = try! JSONDecoder().decode(BatchEvent.self, from: eventSent.body)
        let eventDecision: Decision = event.visitors[0].snapshots[0].decisions![0]
        let metadata = eventDecision.metaData
        
        let desc = eventSent.description
        XCTAssert(desc.contains("campaign_activated"))
        
        XCTAssertEqual(eventDecision.experimentID, "id_holdout")
        XCTAssertEqual(eventDecision.variationID, "id_holdout_variation")
        
        XCTAssertEqual(metadata.flagKey, "feature_2")
        XCTAssertEqual(metadata.ruleKey, "key_holdout")
        XCTAssertEqual(metadata.ruleType, "holdout")
        XCTAssertEqual(metadata.variationKey, "key_holdout_variation")
        XCTAssertEqual(metadata.enabled, false)
    }
    
    func testDecideError_doNotSendImpression() {
        let featureKey = "invalid"   // invalid flag
        
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}
        
        XCTAssertNil(decision.variationKey)
        XCTAssertFalse(decision.enabled)
        XCTAssert(eventDispatcher.events.isEmpty)
    }
    
    func testDecide_sendImpression_with_disable_tracking() {
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
                
        let featureKey = "feature_2"
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey, options: [.disableDecisionEvent])
        XCTAssertEqual(decision.variationKey, "key_holdout_variation")
        XCTAssertFalse(decision.enabled)
        optimizely.eventLock.sync{}
        XCTAssert(eventDispatcher.events.isEmpty)
    }
    
    func testDecide_sendImpression_withSendFlagDecisionsOff() {
        let holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        optimizely.config!.project.holdouts = [holdout]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        
        optimizely.config?.project.sendFlagDecisions = false
        
        let featureKey = "feature_2"
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        XCTAssertEqual(decision.variationKey, "key_holdout_variation")
        XCTAssertFalse(decision.enabled)
        optimizely.eventLock.sync{}
        XCTAssertFalse(eventDispatcher.events.isEmpty)
    }
}
