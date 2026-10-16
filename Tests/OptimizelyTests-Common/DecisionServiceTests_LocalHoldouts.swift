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
    var eventDispatcher: MockEventDispatcher!

    let userId = "test_user"
    let flagKey = "feature_1"
    let experimentRuleId = "10390977673"  // From decide_datafile
    let deliveryRuleId = "3332020515"     // From decide_datafile rollout
    let everyoneElseRuleKey = "18322080788"
    let everyoneElseVariationKey = "18257766532"

    // variation id and trafficAllocation entityId must be numeric strings.
    // Holdout id uses numeric too for fixture uniformity. Keys are arbitrary.
    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "9999900010",
            "key": "holdout_test_key",
            "trafficAllocation": [
                ["entityId": "9999900020", "endOfRange": 5000] // 50% traffic
            ],
            "audienceIds": [],
            "variations": [
                [
                    "variables": [],
                    "id": "9999900020",
                    "key": "holdout_variation_key",
                    "featureEnabled": false
                ]
            ]
        ]
    }

    override func setUp() {
        super.setUp()

        // Load a real datafile for testing
        eventDispatcher = MockEventDispatcher()
        optimizely = OTUtils.createOptimizely(datafileName: "decide_datafile",
                                             clearUserProfileService: true,
                                             eventDispatcher: eventDispatcher)
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
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [holdout], localHoldouts: [])

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
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [holdout], localHoldouts: [])

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
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        // Mock bucketer to ensure user buckets into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey, options: [.includeReasons])

        assertHeldOutThenServedByEveryoneElse(decision)
    }

    func testLocalHoldout_ExperimentRule_UserNotBucketed() {
        // Test that when user misses local holdout, normal experiment evaluation continues
        // Expected: Local holdout checked, user not bucketed, normal experiment logic runs

        // Create local holdout targeting experiment rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

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
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

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
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        // Mock bucketer to ensure user buckets into holdout
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey, options: [.includeReasons])

        assertHeldOutThenServedByEveryoneElse(decision)
    }

    func testLocalHoldout_DeliveryRule_UserNotBucketed() {
        // Test that when user misses local holdout, normal delivery rule evaluation continues
        // Expected: Local holdout checked, user not bucketed, normal delivery logic runs

        // Create local holdout targeting delivery rule
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [deliveryRuleId]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

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
        holdout2.trafficAllocation[0].entityId = "holdout_2_var_id"

        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout1, holdout2])

        // Mock bucketer to ensure user buckets into both
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)

        let decision = mockDecisionService.getVariationForFeature(config: config,
                                                                  featureFlag: config.getFeatureFlag(key: flagKey)!,
                                                                  user: optimizely.createUserContext(userId: userId)).result

        XCTAssertEqual(decision?.holdoutDecisions.map { $0.experiment.key }, ["holdout_1"], "Only the first matching holdout is recorded for the rule")
        XCTAssertEqual(decision?.holdoutDecisions.first?.variation.key, "holdout_1_variation")
        XCTAssertEqual(decision?.experiment?.key, everyoneElseRuleKey)
    }

    func testMultipleLocalHoldouts_DifferentRules_EachEvaluated() {
        // Test that local holdouts targeting different rules are each evaluated independently
        // Expected: Each rule checks its own local holdouts

        // Create two holdouts targeting different rules
        var holdout1 = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout1.includedRules = [experimentRuleId]

        var holdout2 = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout2.id = "holdout_2"
        holdout2.key = "holdout_2"
        holdout2.includedRules = [deliveryRuleId]
        holdout2.variations[0].id = "holdout_2_var_id"
        holdout2.trafficAllocation[0].entityId = "holdout_2_var_id"

        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout1, holdout2])

        // Mock bucketer
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)

        let decision = mockDecisionService.getVariationForFeature(config: config,
                                                                  featureFlag: config.getFeatureFlag(key: flagKey)!,
                                                                  user: optimizely.createUserContext(userId: userId)).result

        XCTAssertEqual(decision?.holdoutDecisions.map { $0.experiment.id }, [holdout1.id, "holdout_2"], "Each rule records its own holdout hit, in rule order")
        XCTAssertEqual(decision?.experiment?.key, everyoneElseRuleKey)
        XCTAssertEqual(decision?.variation?.key, everyoneElseVariationKey)
        XCTAssertEqual(decision?.source, Constants.DecisionSource.rollout.rawValue)
    }

    // MARK: - Cross-Flag Local Holdouts

    func testLocalHoldout_CrossFlag_OnlyTargetedRulesAffected() {
        // Test that a local holdout targeting rules from multiple flags only affects those specific rules
        // Expected: Only the targeted rule in this flag is affected, other rules work normally

        // Create local holdout targeting specific rule in feature_1
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]  // Only targets experiment in feature_1
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        // Mock bucketer
        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)

        // Test feature_1 (should be affected)
        let decision1 = user.decide(key: "feature_1", options: [.includeReasons])
        assertHeldOutThenServedByEveryoneElse(decision1)

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

        config.holdoutConfig = HoldoutConfig(globalHoldouts: [globalHoldout], localHoldouts: [localHoldout])

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
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

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

        let config = HoldoutConfig(globalHoldouts: [], localHoldouts: [])
        let result = config.getHoldoutsForRule(ruleId: "nonexistent_rule")

        XCTAssertTrue(result.isEmpty, "Non-existent rule should return empty array")
    }

    func testLocalHoldout_InactiveStatus_NotEvaluated() {
        // Test that local holdouts with status != running are not evaluated
        // Expected: Only running holdouts are checked

        // Create inactive holdout
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.status = .draft  // Not running
        holdout.includedRules = [experimentRuleId]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

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

        // Create holdout with empty array
        var holdoutData = sampleHoldout
        holdoutData["includedRules"] = []  // Empty array, NOT nil
        var holdout = try! OTUtils.model(from: holdoutData) as Holdout

        // Empty array means local holdout with no rules targeted (effectively inactive)
        XCTAssertFalse(holdout.isGlobal, "Empty includedRules array should NOT be global")

        // Set to nil
        holdout.includedRules = nil
        XCTAssertTrue(holdout.isGlobal, "Nil includedRules should be global")
    }

    // MARK: - Held-out rule continues to later rules

    func testLocalHoldout_HitOnExperimentRule_NextRuleServesAndHoldoutEventSent() {
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [experimentRuleId])])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId, attributes: ["gender": "f", "country": "US"])
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, deliveryRuleId)
        XCTAssertEqual(decision.variationKey, "3324490633")
        XCTAssertTrue(decision.enabled)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.metaData.ruleType, Constants.DecisionSource.rollout.rawValue)
        XCTAssertEqual(events.first?.metaData.ruleKey, deliveryRuleId)
        assertHoldoutEvent(events.last)
    }

    func testLocalHoldout_TwoExperimentRules_HeldOutOfFirstServedBySecond() {
        var flag = config.getFeatureFlag(key: flagKey)!
        flag.experimentIds = [experimentRuleId, "10420810910"]
        config.project.featureFlags = config.project.featureFlags.map { $0.key == flagKey ? flag : $0 }
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [experimentRuleId])])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId, attributes: ["gender": "f"])
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, "exp_no_audience")
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertTrue(decision.enabled)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.metaData.ruleType, Constants.DecisionSource.featureTest.rawValue)
        XCTAssertEqual(events.first?.metaData.ruleKey, "exp_no_audience")
        assertHoldoutEvent(events.last)
    }

    func testLocalHoldout_HitOnDeliveryRule_ContinuesToNextDeliveryRuleNotEveryoneElse() {
        var rollout = config.getRollout(id: config.getFeatureFlag(key: flagKey)!.rolloutId)!
        rollout.experiments[1].trafficAllocation[0].endOfRange = 10000
        config.project.rollouts = [rollout]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [deliveryRuleId])])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId, attributes: ["country": "US", "browser": "safari"])
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, "3332020494")
        XCTAssertEqual(decision.variationKey, "3324490562")
        XCTAssertTrue(decision.enabled)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.first?.metaData.ruleKey, "3332020494")
        assertHoldoutEvent(events.last)
    }

    func testLocalHoldout_OneHoldoutTargetingTwoRules_SendsTwoHoldoutEvents() {
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [experimentRuleId, deliveryRuleId])])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId, attributes: ["gender": "f", "country": "US"])
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, everyoneElseRuleKey)
        XCTAssertEqual(decision.variationKey, everyoneElseVariationKey)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.first?.metaData.ruleKey, everyoneElseRuleKey)
        let holdoutEvents = Array(events.dropFirst())
        XCTAssertEqual(holdoutEvents.count, 2)
        holdoutEvents.forEach { assertHoldoutEvent($0) }
    }

    func testLocalHoldouts_HitsOnSeveralRules_SendOneHoldoutEventPerHit() {
        let first = localHoldout(rules: [experimentRuleId])
        let second = localHoldout(rules: [deliveryRuleId], id: "9999900030", key: "holdout_test_key_2", variationId: "9999900040", variationKey: "holdout_variation_key_2")
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [first, second])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId, attributes: ["gender": "f", "country": "US"])
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, everyoneElseRuleKey)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 3)
        assertHoldoutEvent(events.dropFirst().first)
        assertHoldoutEvent(events.last, holdoutId: "9999900030", ruleKey: "holdout_test_key_2", variationId: "9999900040", variationKey: "holdout_variation_key_2")
    }

    func testLocalHoldout_HitThenNoRuleServes_DecisionUnchangedAndHoldoutEventsSent() {
        let allRules = [experimentRuleId, deliveryRuleId, "3332020494", everyoneElseRuleKey]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: allRules)])
        useMockBucketer(2500)

        let decision = optimizely.createUserContext(userId: userId).decide(key: flagKey)

        XCTAssertNil(decision.variationKey)
        XCTAssertNil(decision.ruleKey)
        XCTAssertFalse(decision.enabled)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 5)
        XCTAssertEqual(events.first?.metaData.ruleType, Constants.DecisionSource.rollout.rawValue)
        XCTAssertEqual(events.first?.metaData.ruleKey, "")
        XCTAssertEqual(events.first?.metaData.variationKey, "")
        let holdoutEvents = Array(events.dropFirst())
        XCTAssertEqual(holdoutEvents.count, 4)
        holdoutEvents.forEach { assertHoldoutEvent($0) }
    }

    func testLocalHoldout_HitOnDeliveryRule_SendFlagDecisionsOff_HoldoutEventStillSent() {
        config.project.sendFlagDecisions = false
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [deliveryRuleId])])
        useMockBucketer(2500)

        let decision = optimizely.createUserContext(userId: userId).decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, everyoneElseRuleKey)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 1)
        assertHoldoutEvent(events.first)
    }

    func testLocalHoldout_DisableDecisionEvent_SuppressesHoldoutEvents() {
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [experimentRuleId, deliveryRuleId])])
        useMockBucketer(2500)

        let decision = optimizely.createUserContext(userId: userId).decide(key: flagKey, options: [.disableDecisionEvent])

        XCTAssertEqual(decision.ruleKey, everyoneElseRuleKey)
        XCTAssertTrue(dispatchedDecisions().isEmpty)
    }

    func testRuleForcedDecision_ExperimentRule_BeatsFullTrafficLocalHoldout() {
        var holdout = localHoldout(rules: [experimentRuleId])
        holdout.trafficAllocation[0].endOfRange = 10000
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: flagKey, ruleKey: "exp_with_audience"),
                                   decision: OptimizelyForcedDecision(variationKey: "b"))
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, "exp_with_audience")
        XCTAssertEqual(decision.variationKey, "b")
        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.metaData.ruleKey, "exp_with_audience")
        XCTAssertFalse(events.contains { $0.metaData.ruleType == Constants.DecisionSource.holdout.rawValue })
    }

    func testRuleForcedDecision_DeliveryRule_BeatsFullTrafficLocalHoldout() {
        var holdout = localHoldout(rules: [deliveryRuleId])
        holdout.trafficAllocation[0].endOfRange = 10000
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: flagKey, ruleKey: deliveryRuleId),
                                   decision: OptimizelyForcedDecision(variationKey: "3324490633"))
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, deliveryRuleId)
        XCTAssertEqual(decision.variationKey, "3324490633")
        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.metaData.ruleKey, deliveryRuleId)
        XCTAssertFalse(events.contains { $0.metaData.ruleType == Constants.DecisionSource.holdout.rawValue })
    }

    func testStoredGlobalHoldoutPlusLocalHoldoutOnDeliveryRule_LaterRuleServesAndBothHoldoutEventsSent() {
        var global = localHoldout(rules: [], id: "9999900050", key: "global_holdout_key", variationId: "9999900060", variationKey: "global_variation_key")
        global.includedRules = nil
        global.excludeTargetedDeliveries = true
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [global], localHoldouts: [localHoldout(rules: [deliveryRuleId])])
        useMockBucketer(2500)

        let user = optimizely.createUserContext(userId: userId, attributes: ["country": "US"])
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.ruleKey, everyoneElseRuleKey)
        XCTAssertEqual(decision.variationKey, everyoneElseVariationKey)
        XCTAssertTrue(decision.enabled)

        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 3)
        XCTAssertEqual(events.first?.metaData.ruleType, Constants.DecisionSource.rollout.rawValue)
        XCTAssertEqual(events.first?.metaData.ruleKey, everyoneElseRuleKey)
        assertHoldoutEvent(events.dropFirst().first, holdoutId: "9999900050", ruleKey: "global_holdout_key", variationId: "9999900060", variationKey: "global_variation_key")
        assertHoldoutEvent(events.last)
    }

    // MARK: - Legacy APIs

    func testLegacyIsFeatureEnabled_LocalHoldoutHit_SkipsRuleWithoutHoldoutEvent() {
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: [experimentRuleId])])
        useMockBucketer(2500)

        let enabled = optimizely.isFeatureEnabled(featureKey: flagKey, userId: userId, attributes: ["gender": "f", "country": "US"])

        XCTAssertTrue(enabled)
        let events = dispatchedDecisions()
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.metaData.ruleType, Constants.DecisionSource.rollout.rawValue)
        XCTAssertEqual(events.first?.metaData.ruleKey, deliveryRuleId)
    }

    func testLegacyIsFeatureEnabled_AllRulesHeldOut_NoEventSent() {
        config.project.sendFlagDecisions = false
        let allRules = [experimentRuleId, deliveryRuleId, "3332020494", everyoneElseRuleKey]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [localHoldout(rules: allRules)])
        useMockBucketer(2500)

        XCTAssertFalse(optimizely.isFeatureEnabled(featureKey: flagKey, userId: userId))
        XCTAssertTrue(dispatchedDecisions().isEmpty)
    }

    // MARK: - Helpers

    private func localHoldout(rules: [String],
                              id: String = "9999900010",
                              key: String = "holdout_test_key",
                              variationId: String = "9999900020",
                              variationKey: String = "holdout_variation_key") -> Holdout {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.id = id
        holdout.key = key
        holdout.variations[0].id = variationId
        holdout.variations[0].key = variationKey
        holdout.trafficAllocation[0].entityId = variationId
        holdout.includedRules = rules
        return holdout
    }

    private func useMockBucketer(_ bucketValue: Int) {
        optimizely.decisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(),
                                                            bucketer: MockBucketer(mockBucketValue: bucketValue))
    }

    private func dispatchedDecisions() -> [Decision] {
        optimizely.eventLock.sync {}
        return eventDispatcher.events.map {
            try! JSONDecoder().decode(BatchEvent.self, from: $0.body).visitors[0].snapshots[0].decisions![0]
        }
    }

    private func assertHoldoutEvent(_ decision: Decision?,
                                    holdoutId: String = "9999900010",
                                    ruleKey: String = "holdout_test_key",
                                    variationId: String = "9999900020",
                                    variationKey: String = "holdout_variation_key",
                                    file: StaticString = #filePath,
                                    line: UInt = #line) {
        XCTAssertEqual(decision?.metaData.ruleType, Constants.DecisionSource.holdout.rawValue, file: file, line: line)
        XCTAssertEqual(decision?.metaData.ruleKey, ruleKey, file: file, line: line)
        XCTAssertEqual(decision?.metaData.variationKey, variationKey, file: file, line: line)
        XCTAssertEqual(decision?.metaData.flagKey, flagKey, file: file, line: line)
        XCTAssertEqual(decision?.metaData.enabled, false, file: file, line: line)
        XCTAssertEqual(decision?.experimentID, holdoutId, file: file, line: line)
        XCTAssertEqual(decision?.variationID, variationId, file: file, line: line)
    }

    private func assertHeldOutThenServedByEveryoneElse(_ decision: OptimizelyDecision, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoVariationInHoldout(userId, "holdout_test_key", "holdout_variation_key").reason), file: file, line: line)
        XCTAssertEqual(decision.ruleKey, everyoneElseRuleKey, file: file, line: line)
        XCTAssertEqual(decision.variationKey, everyoneElseVariationKey, file: file, line: line)
        XCTAssertTrue(decision.enabled, file: file, line: line)
    }
}
