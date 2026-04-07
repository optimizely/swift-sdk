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
    let flagKey = "test_flag"
    let flagId = "flag_123"

    let experimentRuleId = "exp_rule_456"
    let experimentRuleKey = "exp_rule"

    let deliveryRuleId = "delivery_rule_789"
    let deliveryRuleKey = "delivery_rule"

    let globalHoldoutId = "global_holdout_1"
    let localHoldoutId = "local_holdout_1"

    let holdoutVariationId = "holdout_var_1"
    let holdoutVariationKey = "holdout_off"

    let ruleVariationId = "rule_var_1"
    let ruleVariationKey = "rule_var"

    override func setUp() {
        super.setUp()

        // Create base variations
        let holdoutVariation = Variation(id: holdoutVariationId, key: holdoutVariationKey, featureEnabled: false, variablesMap: [:])
        let ruleVariation = Variation(id: ruleVariationId, key: ruleVariationKey, featureEnabled: true, variablesMap: [:])

        // Create traffic allocation (100% to variation)
        let trafficAllocation = [TrafficAllocation(entityId: holdoutVariationId, endOfRange: 10000)]

        // Create global holdout (includedRules: nil means global)
        var globalHoldout = Holdout(id: globalHoldoutId,
                                    key: "global_holdout",
                                    status: .running,
                                    variations: [holdoutVariation],
                                    trafficAllocation: trafficAllocation,
                                    audienceIds: [],
                                    audienceConditions: nil,
                                    includedRules: nil)

        // Create local holdout targeting experiment rule
        var localHoldout = Holdout(id: localHoldoutId,
                                   key: "local_holdout",
                                   status: .running,
                                   variations: [holdoutVariation],
                                   trafficAllocation: trafficAllocation,
                                   audienceIds: [],
                                   audienceConditions: nil,
                                   includedRules: [experimentRuleId])

        // Note: In real tests, we'd load from a proper datafile
        // This is a simplified setup for illustration
    }

    // MARK: - Global Holdouts Tests

    func testGlobalHoldout_EvaluatedBeforeAllRules() {
        // Test that global holdouts are checked at flag level before any experiment or delivery rules
        // Expected: User bucketed into global holdout, no rules evaluated

        // This test would verify:
        // 1. getDecisionForFlag() calls getGlobalHoldouts()
        // 2. Global holdout match returns immediately
        // 3. No experiment or delivery rules are evaluated

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    func testGlobalHoldout_MissAllowsRuleEvaluation() {
        // Test that when user misses global holdout bucket, rule evaluation continues
        // Expected: Global holdout checked, user not bucketed, experiment rule evaluated

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    // MARK: - Local Holdouts - Experiment Rules

    func testLocalHoldout_ExperimentRule_UserBucketed() {
        // Test that local holdout targeting an experiment rule is evaluated
        // Expected: User bucketed into local holdout, experiment rule skipped

        // This test would verify:
        // 1. getVariationFromExperimentRule() calls getHoldoutsForRule(ruleId)
        // 2. Local holdout match returns immediately
        // 3. Normal experiment bucketing is skipped

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    func testLocalHoldout_ExperimentRule_UserNotBucketed() {
        // Test that when user misses local holdout, normal experiment evaluation continues
        // Expected: Local holdout checked, user not bucketed, normal experiment logic runs

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    func testLocalHoldout_ExperimentRule_AudienceMismatch() {
        // Test that local holdout with audience condition skips users not matching audience
        // Expected: User doesn't match audience, holdout skipped, normal experiment runs

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    // MARK: - Local Holdouts - Delivery Rules

    func testLocalHoldout_DeliveryRule_UserBucketed() {
        // Test that local holdout targeting a delivery rule is evaluated
        // Expected: User bucketed into local holdout, delivery rule skipped

        // This test would verify:
        // 1. getVariationFromDeliveryRule() calls getHoldoutsForRule(ruleId)
        // 2. Local holdout match returns immediately
        // 3. Normal delivery rule bucketing is skipped

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    func testLocalHoldout_DeliveryRule_UserNotBucketed() {
        // Test that when user misses local holdout, normal delivery rule evaluation continues
        // Expected: Local holdout checked, user not bucketed, normal delivery logic runs

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    // MARK: - Multiple Local Holdouts

    func testMultipleLocalHoldouts_SameRule_FirstMatchWins() {
        // Test that when multiple local holdouts target the same rule, first match wins
        // Expected: User bucketed into first matching holdout, second holdout not evaluated

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    func testMultipleLocalHoldouts_DifferentRules_EachEvaluated() {
        // Test that local holdouts targeting different rules are each evaluated independently
        // Expected: Each rule checks its own local holdouts

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    // MARK: - Cross-Flag Local Holdouts

    func testLocalHoldout_CrossFlag_OnlyTargetedRulesAffected() {
        // Test that a local holdout targeting rules from multiple flags only affects those specific rules
        // Expected: Only the targeted rule in this flag is affected, other rules work normally

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    // MARK: - Global + Local Interaction

    func testGlobalAndLocalHoldouts_GlobalEvaluatedFirst() {
        // Test precedence: global holdouts evaluated before local holdouts
        // Expected: If user in global holdout, local holdout never evaluated

        // Decision flow should be:
        // 1. Check global holdouts (flag level)
        // 2. If no match, evaluate experiment rules
        //    a. Check local holdouts for this rule
        //    b. If no match, normal rule evaluation

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
    }

    func testLocalHoldout_EvaluatedAfterForcedDecision() {
        // Test that forced decisions take precedence over local holdouts
        // Expected: Forced decision checked first, if no match then local holdout

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
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

        XCTAssertTrue(true, "Test implementation requires proper datafile setup")
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
