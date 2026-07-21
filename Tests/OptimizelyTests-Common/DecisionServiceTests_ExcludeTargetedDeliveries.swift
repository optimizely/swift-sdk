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

class DecisionServiceTests_ExcludeTargetedDeliveries: XCTestCase {

    var optimizely: OptimizelyClient!
    var config: ProjectConfig!

    let userId = "test_user"
    let flagKey = "feature_1"
    let experimentRuleId = "10390977673"
    let deliveryRuleId = "3332020515"

    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "9999900010",
            "key": "holdout_test_key",
            "trafficAllocation": [
                ["entityId": "9999900020", "endOfRange": 5000]
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
        optimizely = OTUtils.createOptimizely(datafileName: "decide_datafile",
                                             clearUserProfileService: true)
        config = optimizely.config!
    }

    // MARK: - excludeTargetedDeliveries = false (default)

    func testExcludeTargetedDeliveriesFalse_HoldoutApplesToTDRule() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        holdout.excludeTargetedDeliveries = false
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        var experiment = config.getExperiment(id: experimentRuleId)!
        experiment.type = .targetedDelivery
        config.project.experiments = [experiment]

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.variationKey, "holdout_variation_key")
        XCTAssertFalse(decision.enabled)
    }

    // MARK: - excludeTargetedDeliveries = true with TD rule

    func testExcludeTargetedDeliveriesTrue_TDRule_HoldoutSkipped() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        holdout.excludeTargetedDeliveries = true
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        var experiment = config.getExperiment(id: experimentRuleId)!
        experiment.type = .targetedDelivery
        config.project.experiments = [experiment]

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key")
    }

    // MARK: - excludeTargetedDeliveries = true with AB rule

    func testExcludeTargetedDeliveriesTrue_ABRule_HoldoutStillApplies() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        holdout.excludeTargetedDeliveries = true
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        var experiment = config.getExperiment(id: experimentRuleId)!
        experiment.type = .ab
        config.project.experiments = [experiment]

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.variationKey, "holdout_variation_key")
        XCTAssertFalse(decision.enabled)
    }

    // MARK: - Backward compatibility (field missing from JSON)

    func testExcludeTargetedDeliveries_MissingFromJSON_DefaultsFalse() {
        var holdoutData = sampleHoldout
        holdoutData.removeValue(forKey: "excludeTargetedDeliveries")
        holdoutData["includedRules"] = [experimentRuleId]
        let holdout = try! OTUtils.model(from: holdoutData) as Holdout

        XCTAssertFalse(holdout.excludeTargetedDeliveries)
    }

    func testExcludeTargetedDeliveries_MissingFromJSON_HoldoutAppliesNormally() {
        var holdoutData = sampleHoldout
        holdoutData.removeValue(forKey: "excludeTargetedDeliveries")
        holdoutData["includedRules"] = [experimentRuleId]
        let holdout = try! OTUtils.model(from: holdoutData) as Holdout
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        var experiment = config.getExperiment(id: experimentRuleId)!
        experiment.type = .targetedDelivery
        config.project.experiments = [experiment]

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.variationKey, "holdout_variation_key")
        XCTAssertFalse(decision.enabled)
    }

    // MARK: - Global holdout with excludeTargetedDeliveries true and TD rule

    func testGlobalHoldout_ExcludeTargetedDeliveriesTrue_TDRule_HoldoutSkippedForTD() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = nil
        holdout.excludeTargetedDeliveries = true
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [holdout], localHoldouts: [])

        var experiment = config.getExperiment(id: experimentRuleId)!
        experiment.type = .targetedDelivery
        config.project.experiments = [experiment]

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key")
    }

    // MARK: - Local holdout with excludeTargetedDeliveries true and TD delivery rule

    func testLocalHoldout_ExcludeTargetedDeliveriesTrue_DeliveryTDRule_HoldoutSkipped() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [deliveryRuleId]
        holdout.excludeTargetedDeliveries = true
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        if var rollout = config.getRollout(id: config.getFeatureFlag(key: flagKey)!.rolloutId) {
            if rollout.experiments.count > 0 {
                rollout.experiments[0].type = .targetedDelivery
                config.project.rollouts = [rollout]
            }
        }

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)
        let decision = user.decide(key: flagKey)

        XCTAssertNotEqual(decision.variationKey, "holdout_variation_key")
    }

    // MARK: - Forced decision beats 100% traffic local holdout

    func testForcedDecisionBeats100PercentLocalHoldout_ExcludeTargetedDeliveriesTrue() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        holdout.excludeTargetedDeliveries = true
        holdout.trafficAllocation = [TrafficAllocation(entityId: "9999900020", endOfRange: 10000)]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)

        let context = OptimizelyDecisionContext(flagKey: flagKey, ruleKey: nil)
        let forcedDecision = OptimizelyForcedDecision(variationKey: "a")
        user.setForcedDecision(context: context, decision: forcedDecision)

        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.variationKey, "a", "Forced decision should take precedence over 100% traffic local holdout")
    }

    func testForcedDecisionBeats100PercentLocalHoldout_ExcludeTargetedDeliveriesFalse() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedRules = [experimentRuleId]
        holdout.excludeTargetedDeliveries = false
        holdout.trafficAllocation = [TrafficAllocation(entityId: "9999900020", endOfRange: 10000)]
        config.holdoutConfig = HoldoutConfig(globalHoldouts: [], localHoldouts: [holdout])

        let mockBucketer = MockBucketer(mockBucketValue: 2500)
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: mockBucketer)
        optimizely.decisionService = mockDecisionService

        let user = optimizely.createUserContext(userId: userId)

        let context = OptimizelyDecisionContext(flagKey: flagKey, ruleKey: nil)
        let forcedDecision = OptimizelyForcedDecision(variationKey: "a")
        user.setForcedDecision(context: context, decision: forcedDecision)

        let decision = user.decide(key: flagKey)

        XCTAssertEqual(decision.variationKey, "a", "Forced decision should take precedence over 100% traffic local holdout")
    }
}
