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
        XCTAssertTrue(config.includedHoldouts.isEmpty)
        XCTAssertTrue(config.excludedHoldouts.isEmpty)
    }
    
    func testHoldoutMap() {
        let holdout0: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        let holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedFlags)
        let holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExcludedFlags)
        
        let allHoldouts =  [holdout0, holdout1, holdout2]
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        XCTAssertEqual(holdoutConfig.holdoutIdMap["11111"]?.includedFlags, [])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["11111"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutConfig.holdoutIdMap["55555"]?.includedFlags, ["4444", "5555"])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["55555"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutConfig.holdoutIdMap["3333"]?.includedFlags, [])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["3333"]?.excludedFlags, ["8888", "9999"])
        
        XCTAssertEqual(holdoutConfig.global, [holdout0, holdout2])
        
        XCTAssertEqual(holdoutConfig.includedHoldouts["4444"], [holdout1])
        XCTAssertEqual(holdoutConfig.excludedHoldouts["8888"], [holdout2])

    }

    func testExperimentHoldoutsMap() {
        var holdout0: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExperiments)
        holdout0.id = "exp_holdout_1"

        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout1.id = "global_holdout"

        let allHoldouts = [holdout0, holdout1]
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)

        // Verify experimentHoldoutsMap is populated correctly
        XCTAssertEqual(holdoutConfig.experimentHoldoutsMap["1681267"], [holdout0])
        XCTAssertEqual(holdoutConfig.experimentHoldoutsMap["1681268"], [holdout0])

        // Global holdout should not appear in experimentHoldoutsMap
        XCTAssertNil(holdoutConfig.experimentHoldoutsMap[holdout1.id])
    }

    func testGetHoldoutById() {
        var holdout0: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout0.id = "00000"
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedFlags)
        holdout1.id = "11111"
        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExcludedFlags)
        holdout2.id = "22222"
        
        let allHoldouts =  [holdout0, holdout1, holdout2]
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        XCTAssertEqual(holdoutConfig.getHoldout(id: "00000"), holdout0)
        XCTAssertEqual(holdoutConfig.getHoldout(id: "11111"), holdout1)
        XCTAssertEqual(holdoutConfig.getHoldout(id: "22222"), holdout2)
        
    }
    
    func testHoldoutOrdering_globalThenIncluded() {
        var global1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global1.id = "g1"
        
        var global2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global2.id = "g2"
        
        var included: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        included.id = "i1"
        included.includedFlags = ["f"]
        
        var config = HoldoutConfig(allholdouts: [included, global1, global2])
        
        let result = config.getHoldoutForFlag(id: "f").map(\.id)
        XCTAssertEqual(result, ["g1", "g2", "i1"])
    }
    
    func testHoldoutOrdering_with_Both_IncludedAndExcludedFlags() {
        let flag1 = "11111"
        let flag2 = "22222"
        let flag3 = "33333"
        let flag4 = "44444"
        
        var inc: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        inc.id = "i1"
        inc.includedFlags = [flag1]
        
        var exc: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        exc.id = "e1"
        exc.excludedFlags = [flag2]
        
        var gh1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        gh1.id = "gh1"
        gh1.includedFlags = []
        gh1.excludedFlags = []
        
        var gh2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        gh2.id = "gh2"
        gh2.includedFlags = []
        gh2.excludedFlags = []
        
        
        let allHoldouts =  [inc, exc, gh1, gh2]
        var holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag1), [exc, gh1, gh2, inc])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag2), [gh1, gh2])
        
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag3), [exc, gh1, gh2])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag4), [exc, gh1, gh2])
        
    }
    
    func testExcludedHoldout_shouldNotAppearInGlobalForFlag() {
        var global: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global.id = "global"
        
        var excluded: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        excluded.id = "excluded"
        excluded.excludedFlags = ["f"]
        
        var config = HoldoutConfig(allholdouts: [global, excluded])
        
        let result = config.getHoldoutForFlag(id: "f").map(\.id)
        XCTAssertEqual(result, ["global"]) // excluded should not appear
    }
    
    func testGetHoldoutForFlag_shouldUseCacheOnSecondCall() {
        var ho1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        ho1.id = "h1"
        ho1.includedFlags = ["f1"]
        
        var config = HoldoutConfig(allholdouts: [ho1])
        
        // Initially no cache
        XCTAssertEqual(config.flagHoldoutsMap.count, 0)
        
        let _ = config.getHoldoutForFlag(id: "f1")
        XCTAssertEqual(config.flagHoldoutsMap.count, 1)
        
        let cache_v = config.getHoldoutForFlag(id: "f1")
        XCTAssertEqual(config.flagHoldoutsMap.count, 1)
        XCTAssertEqual(cache_v, config.flagHoldoutsMap["f1"])
    }

    func testGetHoldoutsForExperiment_singleHoldout() {
        var holdout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExperiments)
        holdout.id = "holdout_1"

        let config = HoldoutConfig(allholdouts: [holdout])

        // Verify getHoldoutsForExperiment returns correct holdout for both experiments
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "1681267"), [holdout])
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "1681268"), [holdout])
    }

    func testGetHoldoutsForExperiment_multipleHoldouts() {
        // Create multiple holdouts targeting same experiment
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout1.id = "holdout_1"
        holdout1.experiments = ["exp1"]

        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout2.id = "holdout_2"
        holdout2.experiments = ["exp1"]

        var holdout3: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout3.id = "holdout_3"
        holdout3.experiments = ["exp1"]

        let config = HoldoutConfig(allholdouts: [holdout1, holdout2, holdout3])

        // Verify all are returned in correct order
        let result = config.getHoldoutsForExperiment(experimentId: "exp1")
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].id, "holdout_1")
        XCTAssertEqual(result[1].id, "holdout_2")
        XCTAssertEqual(result[2].id, "holdout_3")
    }

    func testGetHoldoutsForExperiment_nonExistentExperiment() {
        var holdout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExperiments)

        let config = HoldoutConfig(allholdouts: [holdout])

        // Verify returns empty array for non-existent experiment
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "non_existent"), [])
    }

    func testExperimentMapping_oneHoldoutMultipleExperiments() {
        var holdout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout.id = "holdout_1"
        holdout.experiments = ["exp1", "exp2", "exp3"]

        let config = HoldoutConfig(allholdouts: [holdout])

        // Verify holdout appears in map for all three experiments
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp1"), [holdout])
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp2"), [holdout])
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp3"), [holdout])
    }

    func testExperimentMapping_multipleHoldoutsOneExperiment() {
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout1.id = "holdout_1"
        holdout1.experiments = ["exp_shared"]

        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout2.id = "holdout_2"
        holdout2.experiments = ["exp_shared"]

        var holdout3: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout3.id = "holdout_3"
        holdout3.experiments = ["exp_shared"]

        let config = HoldoutConfig(allholdouts: [holdout1, holdout2, holdout3])

        // Verify all appear in the array for that experiment
        let result = config.getHoldoutsForExperiment(experimentId: "exp_shared")
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains(holdout1))
        XCTAssertTrue(result.contains(holdout2))
        XCTAssertTrue(result.contains(holdout3))
    }

    func testUpdateHoldoutMapping_rebuildsExperimentMap() {
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout1.id = "holdout_1"
        holdout1.experiments = ["exp1"]

        var config = HoldoutConfig(allholdouts: [holdout1])

        // Verify initial state
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp1"), [holdout1])
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp2"), [])

        // Modify allHoldouts (triggers updateHoldoutMapping via didSet)
        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout2.id = "holdout_2"
        holdout2.experiments = ["exp2"]

        config.allHoldouts = [holdout1, holdout2]

        // Verify experimentHoldoutsMap is rebuilt correctly
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp1"), [holdout1])
        XCTAssertEqual(config.getHoldoutsForExperiment(experimentId: "exp2"), [holdout2])
    }

    func testLocalHoldouts_dontInterfereWithFlagMapping() {
        // Create mix of flag-level and experiment-level holdouts
        var flagHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        flagHoldout.id = "flag_holdout"
        flagHoldout.includedFlags = ["flag1"]

        var expHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        expHoldout.id = "exp_holdout"
        expHoldout.experiments = ["exp1"]

        var globalHoldout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        globalHoldout.id = "global_holdout"

        var config = HoldoutConfig(allholdouts: [flagHoldout, expHoldout, globalHoldout])

        // Verify flag mapping still works correctly
        let flagResult = config.getHoldoutForFlag(id: "flag1")
        XCTAssertTrue(flagResult.contains(globalHoldout))
        XCTAssertTrue(flagResult.contains(flagHoldout))
        XCTAssertFalse(flagResult.contains(expHoldout)) // Experiment holdout should not appear in flag mapping

        // Verify experiment mapping works independently
        let expResult = config.getHoldoutsForExperiment(experimentId: "exp1")
        XCTAssertEqual(expResult, [expHoldout])
        XCTAssertFalse(expResult.contains(flagHoldout))
        XCTAssertFalse(expResult.contains(globalHoldout))
    }

}
