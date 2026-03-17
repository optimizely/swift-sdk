//
// Copyright 2024, Optimizely, Inc. and contributors
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

class FeatureRolloutTests: XCTestCase {

    // MARK: - Helpers

    /// Creates an experiment dictionary with the given id, key, and optional type.
    private func makeExperiment(id: String, key: String, type: String? = nil,
                                variations: [[String: Any]]? = nil,
                                trafficAllocation: [[String: Any]]? = nil) -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "key": key,
            "status": "Running",
            "layerId": "layer_\(id)",
            "variations": variations ?? [["id": "var_\(id)", "key": "var_key_\(id)", "featureEnabled": true, "variables": []]],
            "trafficAllocation": trafficAllocation ?? [["entityId": "var_\(id)", "endOfRange": 5000]],
            "audienceIds": [],
            "forcedVariations": [:]
        ]
        if let type = type {
            data["type"] = type
        }
        return data
    }

    /// Creates a rollout dictionary with the given id and experiments.
    private func makeRollout(id: String, experiments: [[String: Any]]) -> [String: Any] {
        return ["id": id, "experiments": experiments]
    }

    /// Creates a feature flag dictionary.
    private func makeFeatureFlag(id: String, key: String, experimentIds: [String],
                                  rolloutId: String) -> [String: Any] {
        return [
            "id": id,
            "key": key,
            "experimentIds": experimentIds,
            "rolloutId": rolloutId,
            "variables": []
        ]
    }

    /// Creates a minimal project dictionary and returns a ProjectConfig.
    private func makeProjectConfig(experiments: [[String: Any]],
                                    featureFlags: [[String: Any]],
                                    rollouts: [[String: Any]]) throws -> ProjectConfig {
        let projectData: [String: Any] = [
            "version": "4",
            "projectId": "test_project",
            "experiments": experiments,
            "audiences": [],
            "groups": [],
            "attributes": [],
            "accountId": "123456",
            "events": [],
            "revision": "1",
            "anonymizeIP": true,
            "rollouts": rollouts,
            "featureFlags": featureFlags,
            "botFiltering": false,
            "sendFlagDecisions": true
        ]
        let data = try JSONSerialization.data(withJSONObject: projectData)
        return try ProjectConfig(datafile: data)
    }

    // MARK: - Test 1: Backward compatibility

    func testExperimentWithoutTypeFieldHasNilType() {
        // Old datafiles do not have a "type" field on experiments.
        let data = makeExperiment(id: "exp_1", key: "exp_key_1")
        let model: Experiment = try! OTUtils.model(from: data)

        XCTAssertNil(model.type, "Experiments without a type field should have type == nil")
    }

    // MARK: - Test 2: Core injection

    func testFeatureRolloutExperimentGetsEveryoneElseVariationInjected() throws {
        // A feature rollout experiment (type="fr") should get the everyone-else
        // variation appended, along with a traffic allocation entry at endOfRange 10000.
        let frExperiment = makeExperiment(id: "fr_exp", key: "fr_exp_key", type: "fr")

        let everyoneElseVariation: [String: Any] = [
            "id": "ee_var_id", "key": "ee_var_key", "featureEnabled": false, "variables": []
        ]
        let everyoneElseRule = makeExperiment(id: "ee_rule", key: "ee_rule_key",
                                              variations: [everyoneElseVariation])
        let rollout = makeRollout(id: "rollout_1", experiments: [everyoneElseRule])

        let flag = makeFeatureFlag(id: "flag_1", key: "flag_key_1",
                                    experimentIds: ["fr_exp"], rolloutId: "rollout_1")

        let config = try makeProjectConfig(experiments: [frExperiment],
                                            featureFlags: [flag],
                                            rollouts: [rollout])

        let experiment = config.getExperiment(key: "fr_exp_key")!

        // The original variation + injected everyone-else variation
        XCTAssertEqual(experiment.variations.count, 2,
                       "Feature rollout experiment should have 2 variations after injection")
        XCTAssertEqual(experiment.variations.last?.id, "ee_var_id",
                       "Last variation should be the everyone-else variation")

        // Traffic allocation should include the injected entry
        let lastAllocation = experiment.trafficAllocation.last!
        XCTAssertEqual(lastAllocation.entityId, "ee_var_id")
        XCTAssertEqual(lastAllocation.endOfRange, 10000)
    }

    // MARK: - Test 3: Variation maps updated

    func testFlagVariationsMapContainsInjectedVariation() throws {
        // The flagVariationsMap (used by decisions) must include the injected variation.
        let frExperiment = makeExperiment(id: "fr_exp", key: "fr_exp_key", type: "fr")

        let everyoneElseVariation: [String: Any] = [
            "id": "ee_var_id", "key": "ee_var_key", "featureEnabled": false, "variables": []
        ]
        let everyoneElseRule = makeExperiment(id: "ee_rule", key: "ee_rule_key",
                                              variations: [everyoneElseVariation])
        let rollout = makeRollout(id: "rollout_1", experiments: [everyoneElseRule])

        let flag = makeFeatureFlag(id: "flag_1", key: "flag_key_1",
                                    experimentIds: ["fr_exp"], rolloutId: "rollout_1")

        let config = try makeProjectConfig(experiments: [frExperiment],
                                            featureFlags: [flag],
                                            rollouts: [rollout])

        let flagVariations = config.flagVariationsMap["flag_key_1"]!
        let hasInjectedVariation = flagVariations.contains { $0.id == "ee_var_id" }
        XCTAssertTrue(hasInjectedVariation,
                      "flagVariationsMap must contain the injected everyone-else variation")

        // experimentKeyMap and experimentIdMap should also reflect the injection
        let expByKey = config.getExperiment(key: "fr_exp_key")!
        let expById = config.getExperiment(id: "fr_exp")!
        XCTAssertEqual(expByKey.variations.count, 2)
        XCTAssertEqual(expById.variations.count, 2)
    }

    // MARK: - Test 4: Non-rollout experiments unchanged

    func testNonFeatureRolloutExperimentsAreNotModified() throws {
        // Experiments with type "ab", "mab", "cmab", "td", or nil should not
        // be modified by the injection logic.
        let abExperiment = makeExperiment(id: "ab_exp", key: "ab_key", type: "ab")
        let mabExperiment = makeExperiment(id: "mab_exp", key: "mab_key", type: "mab")
        let tdExperiment = makeExperiment(id: "td_exp", key: "td_key", type: "td")
        let noTypeExperiment = makeExperiment(id: "no_type_exp", key: "no_type_key")

        let everyoneElseVariation: [String: Any] = [
            "id": "ee_var_id", "key": "ee_var_key", "featureEnabled": false, "variables": []
        ]
        let everyoneElseRule = makeExperiment(id: "ee_rule", key: "ee_rule_key",
                                              variations: [everyoneElseVariation])
        let rollout = makeRollout(id: "rollout_1", experiments: [everyoneElseRule])

        let flag = makeFeatureFlag(id: "flag_1", key: "flag_key_1",
                                    experimentIds: ["ab_exp", "mab_exp", "td_exp", "no_type_exp"],
                                    rolloutId: "rollout_1")

        let config = try makeProjectConfig(
            experiments: [abExperiment, mabExperiment, tdExperiment, noTypeExperiment],
            featureFlags: [flag],
            rollouts: [rollout])

        // Each experiment should still have exactly 1 variation (no injection)
        XCTAssertEqual(config.getExperiment(key: "ab_key")!.variations.count, 1)
        XCTAssertEqual(config.getExperiment(key: "mab_key")!.variations.count, 1)
        XCTAssertEqual(config.getExperiment(key: "td_key")!.variations.count, 1)
        XCTAssertEqual(config.getExperiment(key: "no_type_key")!.variations.count, 1)
    }

    // MARK: - Test 5: No rollout edge case

    func testFeatureRolloutWithEmptyRolloutIdDoesNotCrash() throws {
        // If the flag has an empty rolloutId, injection should be silently skipped.
        let frExperiment = makeExperiment(id: "fr_exp", key: "fr_exp_key", type: "fr")

        let flag = makeFeatureFlag(id: "flag_1", key: "flag_key_1",
                                    experimentIds: ["fr_exp"], rolloutId: "")

        let config = try makeProjectConfig(experiments: [frExperiment],
                                            featureFlags: [flag],
                                            rollouts: [])

        let experiment = config.getExperiment(key: "fr_exp_key")!
        XCTAssertEqual(experiment.variations.count, 1,
                       "Experiment should keep original variations when rollout cannot be resolved")
    }

    func testFeatureRolloutWithEmptyRolloutExperimentsDoesNotCrash() throws {
        // If the rollout has no experiments, injection should be silently skipped.
        let frExperiment = makeExperiment(id: "fr_exp", key: "fr_exp_key", type: "fr")

        let rollout = makeRollout(id: "rollout_1", experiments: [])

        let flag = makeFeatureFlag(id: "flag_1", key: "flag_key_1",
                                    experimentIds: ["fr_exp"], rolloutId: "rollout_1")

        let config = try makeProjectConfig(experiments: [frExperiment],
                                            featureFlags: [flag],
                                            rollouts: [rollout])

        let experiment = config.getExperiment(key: "fr_exp_key")!
        XCTAssertEqual(experiment.variations.count, 1,
                       "Experiment should keep original variations when rollout has no experiments")
    }

    func testFeatureRolloutWithNoVariationsInRolloutRuleDoesNotCrash() throws {
        // If the everyone-else rule has no variations, injection should be silently skipped.
        let frExperiment = makeExperiment(id: "fr_exp", key: "fr_exp_key", type: "fr")

        let emptyRule = makeExperiment(id: "ee_rule", key: "ee_rule_key", variations: [])
        let rollout = makeRollout(id: "rollout_1", experiments: [emptyRule])

        let flag = makeFeatureFlag(id: "flag_1", key: "flag_key_1",
                                    experimentIds: ["fr_exp"], rolloutId: "rollout_1")

        let config = try makeProjectConfig(experiments: [frExperiment],
                                            featureFlags: [flag],
                                            rollouts: [rollout])

        let experiment = config.getExperiment(key: "fr_exp_key")!
        XCTAssertEqual(experiment.variations.count, 1,
                       "Experiment should keep original variations when everyone-else rule has no variations")
    }

    // MARK: - Test 6: Type field parsed correctly

    func testExperimentTypeFieldIsParsedCorrectly() {
        let types: [(String, Experiment.ExperimentType)] = [
            ("ab", .ab),
            ("mab", .mab),
            ("cmab", .cmab),
            ("td", .targetedDelivery),
            ("fr", .featureRollout)
        ]

        for (rawValue, expectedType) in types {
            var data = makeExperiment(id: "exp_\(rawValue)", key: "exp_key_\(rawValue)")
            data["type"] = rawValue
            let model: Experiment = try! OTUtils.model(from: data)
            XCTAssertEqual(model.type, expectedType,
                           "Experiment type '\(rawValue)' should be parsed as \(expectedType)")
        }
    }

    func testExperimentIsFeatureRolloutProperty() {
        var frData = makeExperiment(id: "fr_1", key: "fr_key_1")
        frData["type"] = "fr"
        let frModel: Experiment = try! OTUtils.model(from: frData)
        XCTAssertTrue(frModel.isFeatureRollout)

        var abData = makeExperiment(id: "ab_1", key: "ab_key_1")
        abData["type"] = "ab"
        let abModel: Experiment = try! OTUtils.model(from: abData)
        XCTAssertFalse(abModel.isFeatureRollout)

        let noTypeData = makeExperiment(id: "none_1", key: "none_key_1")
        let noTypeModel: Experiment = try! OTUtils.model(from: noTypeData)
        XCTAssertFalse(noTypeModel.isFeatureRollout)
    }
}
