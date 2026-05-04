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
        let config = HoldoutConfig(allholdouts: [])

        XCTAssertTrue(config.holdoutIdMap.isEmpty)
        XCTAssertTrue(config.global.isEmpty)
        XCTAssertTrue(config.ruleHoldoutsMap.isEmpty)
    }

    func testHoldoutMap() {
        let globalHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        let localHoldout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        let localHoldout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithDifferentRules)

        let allHoldouts = [globalHoldout, localHoldout1, localHoldout2]
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)

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

        let allHoldouts = [holdout0, holdout1, holdout2]
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)

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

        let config = HoldoutConfig(allholdouts: [local, global1, global2])

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

        let config = HoldoutConfig(allholdouts: [local1, local2, global])

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

        let config = HoldoutConfig(allholdouts: [local1, local2, local3])

        let sharedRuleHoldouts = config.getHoldoutsForRule(ruleId: "shared_rule")
        XCTAssertEqual(sharedRuleHoldouts.count, 3)
        XCTAssertTrue(sharedRuleHoldouts.contains(local1))
        XCTAssertTrue(sharedRuleHoldouts.contains(local2))
        XCTAssertTrue(sharedRuleHoldouts.contains(local3))
    }

    func testUpdateHoldoutMappingTriggeredOnAllHoldoutsChange() {
        var config = HoldoutConfig(allholdouts: [])
        XCTAssertTrue(config.global.isEmpty)
        XCTAssertTrue(config.ruleHoldoutsMap.isEmpty)

        // When allHoldouts changes, updateHoldoutMapping() should be called automatically
        var global: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global.id = "g1"

        var local: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedRules)
        local.id = "l1"
        local.includedRules = ["rule1"]

        config.allHoldouts = [global, local]

        // Verify maps were updated
        XCTAssertEqual(config.global.count, 1)
        XCTAssertEqual(config.ruleHoldoutsMap["rule1"]?.count, 1)
    }
}
