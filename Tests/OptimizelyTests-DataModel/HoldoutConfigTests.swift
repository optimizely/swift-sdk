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

class HoldoutConfigTests: XCTestCase {
    func testEmptyHoldouts_shouldHaveEmptyMaps() {
        let config = HoldoutConfig(globalHoldouts: [], localHoldouts: [])

        XCTAssertTrue(config.holdoutIdMap.isEmpty)
        XCTAssertTrue(config.global.isEmpty)
        XCTAssertTrue(config.ruleHoldoutsMap.isEmpty)
    }

    func testHoldoutMap() {
        let globalHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        let localHoldout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        let localHoldout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithDifferentRules)

        let holdoutConfig = HoldoutConfig(globalHoldouts: [globalHoldout], localHoldouts: [localHoldout1, localHoldout2])

        // Verify holdoutIdMap
        XCTAssertEqual(holdoutConfig.holdoutIdMap["11111"]?.includedRules, nil)
        XCTAssertEqual(holdoutConfig.holdoutIdMap["55555"]?.includedRules, ["4444", "5555"])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["3333"]?.includedRules, ["8888", "9999"])

        // Verify global holdouts
        XCTAssertEqual(holdoutConfig.global, [globalHoldout])

        // Verify ruleHoldoutsMap
        XCTAssertEqual(holdoutConfig.ruleHoldoutsMap["4444"], [localHoldout1])
        XCTAssertEqual(holdoutConfig.ruleHoldoutsMap["5555"], [localHoldout1])
        XCTAssertEqual(holdoutConfig.ruleHoldoutsMap["8888"], [localHoldout2])
        XCTAssertEqual(holdoutConfig.ruleHoldoutsMap["9999"], [localHoldout2])
    }

    func testGetHoldoutById() {
        var holdout0: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout0.id = "00000"
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        holdout1.id = "11111"
        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithDifferentRules)
        holdout2.id = "22222"

        let holdoutConfig = HoldoutConfig(globalHoldouts: [holdout0], localHoldouts: [holdout1, holdout2])

        XCTAssertEqual(holdoutConfig.getHoldout(id: "00000"), holdout0)
        XCTAssertEqual(holdoutConfig.getHoldout(id: "11111"), holdout1)
        XCTAssertEqual(holdoutConfig.getHoldout(id: "22222"), holdout2)
    }

    func testGetGlobalHoldouts() {
        var global1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global1.id = "g1"

        var global2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global2.id = "g2"

        var local: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local.id = "l1"

        let config = HoldoutConfig(globalHoldouts: [global1, global2], localHoldouts: [local])

        let result = config.getGlobalHoldouts()
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(global1))
        XCTAssertTrue(result.contains(global2))
        XCTAssertFalse(result.contains(local))
    }

    func testGetHoldoutsForRule() {
        var local1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local1.id = "l1"
        local1.includedRules = ["rule1", "rule2"]

        var local2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local2.id = "l2"
        local2.includedRules = ["rule2", "rule3"]

        var global: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global.id = "g1"

        let config = HoldoutConfig(globalHoldouts: [global], localHoldouts: [local1, local2])

        // Rule1 should only have local1
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule1"), [local1])

        // Rule2 should have both local1 and local2
        let rule2Holdouts = config.getHoldoutsForRule(ruleId: "rule2")
        XCTAssertEqual(rule2Holdouts.count, 2)
        XCTAssertTrue(rule2Holdouts.contains(local1))
        XCTAssertTrue(rule2Holdouts.contains(local2))

        // Rule3 should only have local2
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule3"), [local2])

        // Rule4 (not targeted by any holdout) should return empty
        XCTAssertTrue(config.getHoldoutsForRule(ruleId: "rule4").isEmpty)

        // Global holdouts should NOT appear in rule-specific lookups
        XCTAssertFalse(config.getHoldoutsForRule(ruleId: "rule1").contains(global))
    }

    func testIsGlobalProperty() {
        let globalHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        XCTAssertTrue(globalHoldout.isGlobal)

        let localHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        XCTAssertFalse(localHoldout.isGlobal)
    }

    func testMultipleHoldoutsTargetingSameRule() {
        var local1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local1.id = "l1"
        local1.includedRules = ["shared_rule"]

        var local2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local2.id = "l2"
        local2.includedRules = ["shared_rule"]

        var local3: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local3.id = "l3"
        local3.includedRules = ["shared_rule", "other_rule"]

        let config = HoldoutConfig(globalHoldouts: [], localHoldouts: [local1, local2, local3])

        let sharedRuleHoldouts = config.getHoldoutsForRule(ruleId: "shared_rule")
        XCTAssertEqual(sharedRuleHoldouts.count, 3)
        XCTAssertTrue(sharedRuleHoldouts.contains(local1))
        XCTAssertTrue(sharedRuleHoldouts.contains(local2))
        XCTAssertTrue(sharedRuleHoldouts.contains(local3))
    }

    func testUpdateHoldoutMappingTriggeredOnAllHoldoutsChange() {
        var config = HoldoutConfig(globalHoldouts: [], localHoldouts: [])
        XCTAssertTrue(config.global.isEmpty)
        XCTAssertTrue(config.ruleHoldoutsMap.isEmpty)

        var global: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global.id = "g1"

        var local: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local.id = "l1"
        local.includedRules = ["rule1"]

        config = HoldoutConfig(globalHoldouts: [global], localHoldouts: [local])

        // Verify maps were updated
        XCTAssertEqual(config.global.count, 1)
        XCTAssertEqual(config.ruleHoldoutsMap["rule1"]?.count, 1)
    }

    // MARK: - FSSDK-12760: localHoldouts section semantics

    /// Section-aware init: entries in the global section are classified as
    /// global regardless of any `includedRules` field on them.
    func testSectionAwareInit_globalSectionEntriesAreGlobal() {
        var globalWithStrayRules: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        globalWithStrayRules.id = "g_stray"
        globalWithStrayRules.includedRules = ["rule_should_be_ignored"]

        let config = HoldoutConfig(
            globalHoldouts: [globalWithStrayRules],
            localHoldouts: []
        )

        // Must be classified as global
        XCTAssertEqual(config.global.count, 1)
        XCTAssertEqual(config.global.first?.id, "g_stray")
        // `includedRules` must be stripped — section membership is the sole signal
        XCTAssertNil(config.global.first?.includedRules)
        XCTAssertTrue(config.global.first!.isGlobal)
        // The stray rule must NOT be registered in the rule map
        XCTAssertTrue(config.getHoldoutsForRule(ruleId: "rule_should_be_ignored").isEmpty)
        // Entity is still retrievable by id
        XCTAssertNotNil(config.getHoldout(id: "g_stray"))
    }

    /// Section-aware init: entries in the local section register under each
    /// rule in their `includedRules` list and never appear in `global`.
    func testSectionAwareInit_localSectionEntriesAreLocal() {
        var local: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local.id = "l1"
        local.includedRules = ["rule_x", "rule_y"]

        let config = HoldoutConfig(
            globalHoldouts: [],
            localHoldouts: [local]
        )

        XCTAssertTrue(config.global.isEmpty)
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule_x"), [local])
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule_y"), [local])
        XCTAssertTrue(config.getHoldoutsForRule(ruleId: "rule_z").isEmpty)
    }

    /// Local-section entries with `includedRules == nil` are invalid per spec.
    /// They must be excluded from every map and must NOT fall back to global.
    func testLocalSection_missingIncludedRules_isExcluded() {
        var invalid: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        invalid.id = "h_invalid"
        invalid.includedRules = nil  // missing — invalid for local section

        let config = HoldoutConfig(
            globalHoldouts: [],
            localHoldouts: [invalid]
        )

        // Not applied as global
        XCTAssertTrue(config.global.isEmpty)
        // Not applied as local for any rule
        XCTAssertTrue(config.getHoldoutsForRule(ruleId: "any_rule").isEmpty)
        // Not retrievable by id either
        XCTAssertNil(config.getHoldout(id: "h_invalid"))
    }

    /// Local-section entries with an empty `includedRules` list are invalid per
    /// spec (they target no rules). They must be excluded entirely.
    func testLocalSection_emptyIncludedRules_isExcluded() {
        var invalid: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        invalid.id = "h_empty"
        invalid.includedRules = []

        let config = HoldoutConfig(
            globalHoldouts: [],
            localHoldouts: [invalid]
        )

        XCTAssertTrue(config.global.isEmpty)
        XCTAssertTrue(config.getHoldoutsForRule(ruleId: "any_rule").isEmpty)
        XCTAssertNil(config.getHoldout(id: "h_empty"))
    }

    /// Both sections present: entries never cross over. Global stays global,
    /// local stays local, even when both sections share a rule id space.
    func testBothSections_partitionEnforced() {
        var g1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        g1.id = "g1"
        var g2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        g2.id = "g2"

        var l1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        l1.id = "l1"
        l1.includedRules = ["rule_a"]
        var l2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        l2.id = "l2"
        l2.includedRules = ["rule_b"]

        let config = HoldoutConfig(
            globalHoldouts: [g1, g2],
            localHoldouts: [l1, l2]
        )

        // Global section
        let globalIds = Set(config.getGlobalHoldouts().map { $0.id })
        XCTAssertEqual(globalIds, Set(["g1", "g2"]))

        // Local section — each rule resolves to its own holdout, never to a global one
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule_a").map { $0.id }, ["l1"])
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule_b").map { $0.id }, ["l2"])

        // Both sections are retrievable by id
        XCTAssertNotNil(config.getHoldout(id: "g1"))
        XCTAssertNotNil(config.getHoldout(id: "l1"))
    }

    /// Backward compatibility: when the datafile has no `localHoldouts` section
    /// (passed as an empty list), every entry in the `holdouts` section is
    /// treated as global — exactly matching pre-FSSDK-12760 behavior.
    func testBackwardCompat_noLocalHoldoutsSection() {
        var g1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        g1.id = "g1"

        let config = HoldoutConfig(
            globalHoldouts: [g1],
            localHoldouts: []
        )

        XCTAssertEqual(config.getGlobalHoldouts().count, 1)
        XCTAssertEqual(config.getGlobalHoldouts().first?.id, "g1")
        XCTAssertTrue(config.ruleHoldoutsMap.isEmpty)
    }

    /// Mixed-validity local section: valid entries are kept, invalid entries
    /// are excluded without affecting the valid ones.
    func testLocalSection_invalidEntriesDoNotAffectValidOnes() {
        var valid: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        valid.id = "valid"
        valid.includedRules = ["rule_x"]

        var invalidNil: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        invalidNil.id = "invalid_nil"
        invalidNil.includedRules = nil

        var invalidEmpty: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        invalidEmpty.id = "invalid_empty"
        invalidEmpty.includedRules = []

        let config = HoldoutConfig(
            globalHoldouts: [],
            localHoldouts: [valid, invalidNil, invalidEmpty]
        )

        // Only the valid local holdout is registered
        XCTAssertEqual(config.getHoldoutsForRule(ruleId: "rule_x").map { $0.id }, ["valid"])
        XCTAssertNotNil(config.getHoldout(id: "valid"))
        XCTAssertNil(config.getHoldout(id: "invalid_nil"))
        XCTAssertNil(config.getHoldout(id: "invalid_empty"))
        XCTAssertTrue(config.global.isEmpty)
    }
}
