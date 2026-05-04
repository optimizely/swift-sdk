//
// Copyright 2026, Optimizely, Inc. and contributors
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

/// Tests to verify FeatureGates.localHoldouts flag behavior
/// These tests do NOT inherit from BaseHoldoutTests to control the flag state directly
class FeatureGateTests_LocalHoldouts: XCTestCase {

    var optimizely: OptimizelyClient!
    var config: ProjectConfig!

    let userId = "test_user"
    let flagKey = "feature_1"
    let experimentRuleId = "10390977673"  // From decide_datafile
    let deliveryRuleId = "3332020515"     // From decide_datafile

    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "holdout_test_id",
            "key": "holdout_test_key",
            "trafficAllocation": [
                ["entityId": "holdout_variation_id", "endOfRange": 5000] // 50% traffic
            ],
            "audienceIds": [],
            "variations": [
                [
                    "variables": [],
                    "id": "holdout_variation_id",
                    "key": "holdout_variation_key",
                    "featureEnabled": false
                ]
            ]
        ]
    }

    override func setUp() {
        super.setUp()

        optimizely = OTUtils.createOptimizely(datafileName: "decide_datafile",
                                             clearUserProfileService: true)
        config = optimizely.config!
    }

    override func tearDown() {
        // Always reset flag to false to prevent test pollution
        FeatureGates.localHoldouts = false
        super.tearDown()
    }

    // MARK: - Flag OFF Tests (Local Holdouts Should Be Skipped)

    func testLocalHoldoutsSkippedWhenFlagOff_ExperimentRule() {
        // Setup: Flag is OFF
        FeatureGates.localHoldouts = false

        // Create local holdout targeting experiment rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user WOULD bucket into holdout if it were evaluated
        let mockBucketer = MockBucketer(mockBucketValue: 2500) // Within holdout range (0-5000)
        let mockDecisionService = DefaultDecisionService(
            userProfileService: OTUtils.createClearUserProfileService(),
            bucketer: mockBucketer
        )
        optimizely.decisionService = mockDecisionService

        // Execute decision
        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Verify: User did NOT get holdout variation (flag is off, so holdout skipped)
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key",
                          "Local holdout should be skipped when FeatureGates.localHoldouts = false")
        XCTAssertNotEqual(decision.ruleKey, "holdout_test_key",
                          "Should get experiment rule, not holdout")
    }

    func testLocalHoldoutsSkippedWhenFlagOff_DeliveryRule() {
        // Setup: Flag is OFF
        FeatureGates.localHoldouts = false

        // Create local holdout targeting delivery rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [deliveryRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user WOULD bucket into holdout if it were evaluated
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(
            userProfileService: OTUtils.createClearUserProfileService(),
            bucketer: mockBucketer
        )
        optimizely.decisionService = mockDecisionService

        // Execute decision
        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Verify: User did NOT get holdout variation
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key",
                          "Local holdout should be skipped when FeatureGates.localHoldouts = false")
        XCTAssertNotEqual(decision.ruleKey, "holdout_test_key",
                          "Should get delivery rule, not holdout")
    }

    // MARK: - Flag ON Tests (Local Holdouts Should Be Evaluated)

    func testLocalHoldoutsEvaluatedWhenFlagOn_ExperimentRule() {
        // Setup: Flag is ON
        FeatureGates.localHoldouts = true

        // Create local holdout targeting experiment rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to bucket user into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(
            userProfileService: OTUtils.createClearUserProfileService(),
            bucketer: mockBucketer
        )
        optimizely.decisionService = mockDecisionService

        // Execute decision
        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Verify: User DID get holdout variation (flag is on)
        XCTAssertEqual(decision.variationKey, "holdout_variation_key",
                       "Local holdout should be evaluated when FeatureGates.localHoldouts = true")
        XCTAssertEqual(decision.ruleKey, "holdout_test_key",
                       "Should get holdout, not experiment rule")
        XCTAssertFalse(decision.enabled, "Holdout variation has featureEnabled: false")
    }

    func testLocalHoldoutsEvaluatedWhenFlagOn_DeliveryRule() {
        // Setup: Flag is ON
        FeatureGates.localHoldouts = true

        // Create local holdout targeting delivery rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [deliveryRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to bucket user into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(
            userProfileService: OTUtils.createClearUserProfileService(),
            bucketer: mockBucketer
        )
        optimizely.decisionService = mockDecisionService

        // Execute decision
        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Verify: User DID get holdout variation (flag is on)
        XCTAssertEqual(decision.variationKey, "holdout_variation_key",
                       "Local holdout should be evaluated when FeatureGates.localHoldouts = true")
        XCTAssertEqual(decision.ruleKey, "holdout_test_key",
                       "Should get holdout, not delivery rule")
        XCTAssertFalse(decision.enabled, "Holdout variation has featureEnabled: false")
    }

    // MARK: - Global Holdouts (Flag State Should Not Matter)

    func testGlobalHoldoutsWorkRegardlessOfFlagState() {
        // Create global holdout (no includedRules)
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = nil  // Global holdout
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to bucket user into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(
            userProfileService: OTUtils.createClearUserProfileService(),
            bucketer: mockBucketer
        )
        optimizely.decisionService = mockDecisionService

        // Test with flag OFF
        FeatureGates.localHoldouts = false
        let user1 = optimizely.createUserContext(userId: userId)
        let decision1 = user1.decide(key: flagKey)

        XCTAssertEqual(decision1.variationKey, "holdout_variation_key",
                       "Global holdout should work when flag is OFF")
        XCTAssertEqual(decision1.ruleKey, "holdout_test_key",
                       "Should get global holdout regardless of flag state")

        // Test with flag ON
        FeatureGates.localHoldouts = true
        let user2 = optimizely.createUserContext(userId: userId + "_2")
        let decision2 = user2.decide(key: flagKey)

        XCTAssertEqual(decision2.variationKey, "holdout_variation_key",
                       "Global holdout should work when flag is ON")
        XCTAssertEqual(decision2.ruleKey, "holdout_test_key",
                       "Should get global holdout regardless of flag state")
    }
}
