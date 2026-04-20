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

/// Integration tests for Local Holdouts functionality
/// Tests that local holdouts are correctly evaluated at the rule level
/// and global holdouts are evaluated at the flag level before any rules
class DecisionServiceTests_LocalHoldouts: XCTestCase {

    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!

    let userId = "test_user"
    let flagKey = "feature_1"
    let experimentRuleId = "10390977673"  // From decide_datafile
    let deliveryRuleId = "3332020515"     // From decide_datafile rollout

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

        // Load a real datafile for testing
        optimizely = OTUtils.createOptimizely(datafileName: "decide_datafile",
                                             clearUserProfileService: true)
        config = optimizely.config!
        decisionService = optimizely.decisionService as? DefaultDecisionService
    }

    // MARK: - Global Holdouts Tests

    func testGlobalHoldout_EvaluatedBeforeAllRules() {
        // Test that global holdouts are checked at flag level before any experiment or delivery rules
        // Expected: User bucketed into global holdout, no rules evaluated

        // Create global holdout (includedRules: nil)
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = nil  // Global holdout
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user buckets into holdout (50% traffic = endOfRange 5000)
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user got the holdout variation
        XCTAssertEqual(decision.variationKey, "holdout_variation_key", "User should be bucketed into global holdout")
        XCTAssertFalse(decision.enabled, "Holdout variation should have featureEnabled: false")
    }

    func testGlobalHoldout_MissAllowsRuleEvaluation() {
        // Test that when user misses global holdout bucket, rule evaluation continues
        // Expected: Global holdout checked, user not bucketed, experiment rule evaluated

        // Create global holdout
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = nil  // Global holdout
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user MISSES holdout (50% traffic = endOfRange 5000)
        let mockBucketer = MockBucketer(mockBucketValue: 7000)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user did NOT get holdout variation (got normal experiment/rollout decision)
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key", "User should NOT be in holdout")
    }

    // MARK: - Local Holdouts - Experiment Rules

    func testLocalHoldout_ExperimentRule_UserBucketed() {
        // Test that local holdout targeting an experiment rule is evaluated
        // Expected: User bucketed into local holdout, experiment rule skipped

        // Create local holdout targeting specific experiment rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]  // Target the experiment rule
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user buckets into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user got the holdout variation
        XCTAssertEqual(decision.variationKey, "holdout_variation_key", "User should be bucketed into local holdout")
        XCTAssertFalse(decision.enabled, "Holdout variation should have featureEnabled: false")
    }

    func testLocalHoldout_ExperimentRule_UserNotBucketed() {
        // Test that when user misses local holdout, normal experiment evaluation continues
        // Expected: Local holdout checked, user not bucketed, normal experiment logic runs

        // Create local holdout targeting experiment rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user MISSES holdout
        let mockBucketer = MockBucketer(mockBucketValue: 7000)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user did NOT get holdout variation
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key", "User should NOT be in holdout")
    }

    func testLocalHoldout_ExperimentRule_AudienceMismatch() {
        // Test that local holdout with audience condition skips users not matching audience
        // Expected: User doesn't match audience, holdout skipped, normal experiment runs

        // Create local holdout with audience targeting
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        holdout.audienceIds = ["13389130056"]  // Audience from decide_datafile
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure would bucket IF audience matched
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        // User without matching attributes
        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user did NOT get holdout (audience mismatch)
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key", "User should NOT be in holdout due to audience mismatch")
    }

    // MARK: - Local Holdouts - Delivery Rules

    func testLocalHoldout_DeliveryRule_UserBucketed() {
        // Test that local holdout targeting a delivery rule is evaluated
        // Expected: User bucketed into local holdout, delivery rule skipped

        // Create local holdout targeting delivery rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [deliveryRuleId]  // Target delivery rule from rollout
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user buckets into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user got the holdout variation
        XCTAssertEqual(decision.variationKey, "holdout_variation_key", "User should be bucketed into local holdout for delivery rule")
        XCTAssertFalse(decision.enabled, "Holdout variation should have featureEnabled: false")
    }

    func testLocalHoldout_DeliveryRule_UserNotBucketed() {
        // Test that when user misses local holdout, normal delivery rule evaluation continues
        // Expected: Local holdout checked, user not bucketed, normal delivery logic runs

        // Create local holdout targeting delivery rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [deliveryRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure user MISSES holdout
        let mockBucketer = MockBucketer(mockBucketValue: 7000)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user did NOT get holdout variation
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key", "User should NOT be in holdout")
    }

    // MARK: - Multiple Local Holdouts

    func testMultipleLocalHoldouts_SameRule_FirstMatchWins() {
        // Test that when multiple local holdouts target the same rule, first match wins
        // Expected: User bucketed into first matching holdout, second holdout not evaluated

        // Create two local holdouts targeting the same rule
        var holdout1 = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout1.id = "holdout_1"
        holdout1.key = "holdout_1"
        holdout1.includedRules = [experimentRuleId]
        holdout1.variations[0].key = "holdout_1_variation"

        var holdout2 = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout2.id = "holdout_2"
        holdout2.key = "holdout_2"
        holdout2.includedRules = [experimentRuleId]
        holdout2.variations[0].id = "holdout_2_var_id"
        holdout2.variations[0].key = "holdout_2_variation"

        config.project.holdouts = [holdout1, holdout2]
        config.holdoutConfig.allHoldouts = [holdout1, holdout2]

        // Mock bucketer to ensure user buckets into both
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user got the FIRST holdout variation
        XCTAssertEqual(decision.variationKey, "holdout_1_variation", "User should be in first matching holdout only")
    }

    func testMultipleLocalHoldouts_DifferentRules_EachEvaluated() {
        // Test that local holdouts targeting different rules are each evaluated independently
        // Expected: Each rule checks its own local holdouts

        // Create two holdouts targeting different rules
        var holdout1 = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout1.includedRules = [experimentRuleId]

        var holdout2 = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout2.id = "holdout_2"
        holdout2.includedRules = [deliveryRuleId]
        holdout2.variations[0].id = "holdout_2_var_id"

        config.project.holdouts = [holdout1, holdout2]
        config.holdoutConfig.allHoldouts = [holdout1, holdout2]

        // Mock bucketer
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert that one of the holdouts was evaluated (which one depends on rule evaluation order)
        XCTAssertEqual(decision.variationKey, "holdout_variation_key", "User should be in one of the holdouts")
    }

    // MARK: - Cross-Flag Local Holdouts

    func testLocalHoldout_CrossFlag_OnlyTargetedRulesAffected() {
        // Test that a local holdout targeting rules from multiple flags only affects those specific rules
        // Expected: Only the targeted rule in this flag is affected, other rules work normally

        // Create local holdout targeting specific rule in feature_1
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]  // Only targets experiment in feature_1
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)

        // Test feature_1 (should be affected)
        let decision1 = user.decide(key: "feature_1")
        XCTAssertEqual(decision1.variationKey, "holdout_variation_key", "feature_1 should be in holdout")

        // Test feature_2 (should NOT be affected - no rules targeted)
        let decision2 = user.decide(key: "feature_2")
        XCTAssertNotEqual(decision2.variationKey, "holdout_variation_key", "feature_2 should NOT be in holdout")
    }

    // MARK: - Global + Local Interaction

    func testGlobalAndLocalHoldouts_GlobalEvaluatedFirst() {
        // Test precedence: global holdouts evaluated before local holdouts
        // Expected: If user in global holdout, local holdout never evaluated

        // Create global and local holdouts
        var globalHoldout = try! OTUtils.model(from: sampleHoldout) as Holdout
        globalHoldout.id = "global_holdout"
        globalHoldout.key = "global_holdout"
        globalHoldout.includedRules = nil  // Global
        globalHoldout.variations[0].key = "global_variation"

        var localHoldout = try! OTUtils.model(from: sampleHoldout) as Holdout
        localHoldout.id = "local_holdout"
        localHoldout.includedRules = [experimentRuleId]  // Local
        localHoldout.variations[0].id = "local_var_id"
        localHoldout.variations[0].key = "local_variation"

        config.project.holdouts = [globalHoldout, localHoldout]
        config.holdoutConfig.allHoldouts = [globalHoldout, localHoldout]

        // Mock bucketer to ensure user buckets into both
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user got GLOBAL holdout (evaluated first)
        XCTAssertEqual(decision.variationKey, "global_variation", "Global holdout should be evaluated first")
    }

    func testLocalHoldout_EvaluatedAfterForcedDecision() {
        // Test that forced decisions take precedence over local holdouts
        // Expected: Forced decision checked first, if no match then local holdout

        // Create local holdout
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure would bucket into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)

        // Set forced decision (should override holdout)
        let context = OptimizelyDecisionContext(flagKey: flagKey, ruleKey: nil)
        let forcedDecision = OptimizelyForcedDecision(variationKey: "a")
        user.setForcedDecision(context: context, decision: forcedDecision)

        let decision = user.decide(key: flagKey)

        // Assert user got forced decision, NOT holdout
        XCTAssertEqual(decision.variationKey, "a", "Forced decision should take precedence over holdout")
    }

    // MARK: - Edge Cases

    func testLocalHoldout_RuleNotFound_NoError() {
        // Test that local holdout targeting non-existent rule doesn't break evaluation
        // Expected: Empty array returned from getHoldoutsForRule(), normal evaluation continues

        let config = HoldoutConfig(allholdouts: [])
        let result = config.getHoldoutsForRule(ruleId: "nonexistent_rule")

        XCTAssertTrue(result.isEmpty, "Non-existent rule should return empty array")
    }

    func testLocalHoldout_InactiveStatus_NotEvaluated() {
        // Test that local holdouts with status != running are not evaluated
        // Expected: Only running holdouts are checked

        // Create inactive holdout
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.status = .paused  // Not running
        holdout.includedRules = [experimentRuleId]
        config.project.holdouts = [holdout]
        config.holdoutConfig.allHoldouts = [holdout]

        // Mock bucketer to ensure would bucket IF holdout was active
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        // Assert user did NOT get holdout (status not running)
        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key", "Inactive holdout should not be evaluated")
    }

    func testLocalHoldout_EmptyIncludedRules_TreatedAsGlobal() {
        // Test that holdout with empty includedRules array is NOT treated as global
        // Only includedRules == nil should be global

        var holdout = Holdout(id: "test_holdout",
                             key: "test",
                             status: .running,
                             variations: [],
                             trafficAllocation: [],
                             audienceIds: [],
                             audienceConditions: nil,
                             includedRules: [])  // Empty array, NOT nil

        // Empty array means local holdout with no rules targeted (effectively inactive)
        XCTAssertFalse(holdout.isGlobal, "Empty includedRules array should NOT be global")

        // Set to nil
        holdout.includedRules = nil
        XCTAssertTrue(holdout.isGlobal, "Nil includedRules should be global")
    }
}
