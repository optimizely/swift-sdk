//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class ProjectConfigTests: XCTestCase {

    var datafile: Data!
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!

    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
        
        self.config = optimizely.config
    }

    func testExperimentFeatureMapIsBuiltFromProject() {

        // setup {featureFlag, experiments} n-to-n mapping
        
        var exp0 = ExperimentTests.sampleData
        var exp1 = ExperimentTests.sampleData
        var exp2 = ExperimentTests.sampleData
        var exp3 = ExperimentTests.sampleData
        var exp4 = ExperimentTests.sampleData
        exp0["id"] = "1000"
        exp1["id"] = "1001"
        exp2["id"] = "1002"
        exp3["id"] = "1003"
        exp4["id"] = "1004"
        
        var feature0 = FeatureFlagTests.sampleData
        var feature1 = FeatureFlagTests.sampleData
        var feature2 = FeatureFlagTests.sampleData
        feature0["id"] = "2000"
        feature1["id"] = "2001"
        feature2["id"] = "2002"
        
        feature0["experimentIds"] = ["1000"]
        feature1["experimentIds"] = ["1000", "1001", "1002"]
        feature2["experimentIds"] = ["1000", "1003", "1004"]

        var projectData = ProjectTests.sampleData
        projectData["experiments"] = [exp0, exp1, exp2, exp3, exp4]
        projectData["featureFlags"] = [feature0, feature1, feature2]
        
        // check experimentFeatureMap extracted properly
        
        let model: Project = try! OTUtils.model(from: projectData)
        let projectConfig = ProjectConfig()
        projectConfig.project = model
        
        let featureMap = projectConfig.experimentFeatureMap
        print(featureMap)
        
        XCTAssertEqual(featureMap["1000"], ["2000", "2001", "2002"])
        XCTAssertEqual(featureMap["1001"], ["2001"])
        XCTAssertEqual(featureMap["1002"], ["2001"])
        XCTAssertEqual(featureMap["1003"], ["2002"])
        XCTAssertEqual(featureMap["1004"], ["2002"])
    }
    
    func testHoldoutIdMapIsBuiltFromProject() {
        var exp0 = ExperimentTests.sampleData
        var exp1 = ExperimentTests.sampleData
        var exp2 = ExperimentTests.sampleData
        var exp3 = ExperimentTests.sampleData
        var exp4 = ExperimentTests.sampleData
        exp0["id"] = "1000"
        exp1["id"] = "1001"
        exp2["id"] = "1002"
        exp3["id"] = "1003"
        exp4["id"] = "1004"
       
        
        var holdout0 = HoldoutTests.sampleData
        var holdout1 = HoldoutTests.sampleData
        var holdout2 = HoldoutTests.sampleData
        var holdout3 = HoldoutTests.sampleData
        var holdout4 = HoldoutTests.sampleData
        holdout0["id"] = "3000" // Global holdout (no included or excluded flags)
        holdout1["id"] = "3001" // Global holdout (no included or excluded flags)
        holdout2["id"] = "3002" // Global holdout (no included or excluded flags)
        holdout3["id"] = "3003" // Included flagids ["2000", "2002"]
        holdout4["id"] = "3004" // Excluded flagids ["2001"]
        
        holdout3["includedFlags"] = ["2000", "2002"]
        holdout4["excludedFlags"] = ["2001"]
        
        var feature0 = FeatureFlagTests.sampleData
        var feature1 = FeatureFlagTests.sampleData
        var feature2 = FeatureFlagTests.sampleData
        var feature3 = FeatureFlagTests.sampleData
        
        feature0["id"] = "2000"
        feature0["key"] = "key_2000"
        
        feature1["id"] = "2001"
        feature1["key"] = "key_2001"
        
        feature2["id"] = "2002"
        feature2["key"] = "key_2002"
        
        feature3["id"] = "2003"
        feature3["key"] = "key_2003"
        
        feature0["experimentIds"] = ["1000"]
        feature1["experimentIds"] = ["1000", "1001", "1002"]
        feature2["experimentIds"] = ["1000", "1003", "1004"]
        feature3["experimentIds"] = ["1000", "1003", "1004"]
        
        var projectData = ProjectTests.sampleData
        projectData["experiments"] = [exp0, exp1, exp2, exp3, exp4]
        projectData["featureFlags"] = [feature0, feature1, feature2, feature3]
        projectData["holdouts"] = [holdout0, holdout1, holdout2, holdout3, holdout4]
        
        // check experimentFeatureMap extracted properly
        
        let model: Project = try! OTUtils.model(from: projectData)
        let projectConfig = ProjectConfig()
        projectConfig.project = model
        
        let holdoutIdMap = projectConfig.holdoutIdMap
        
        XCTAssertEqual(holdoutIdMap["3000"]?.includedFlags, [])
        XCTAssertEqual(holdoutIdMap["3000"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutIdMap["3001"]?.includedFlags, [])
        XCTAssertEqual(holdoutIdMap["3001"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutIdMap["3002"]?.includedFlags, [])
        XCTAssertEqual(holdoutIdMap["3002"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutIdMap["3003"]?.includedFlags, ["2000", "2002"])
        XCTAssertEqual(holdoutIdMap["3003"]?.excludedFlags, [])
        
        
        XCTAssertEqual(holdoutIdMap["3004"]?.includedFlags, [])
        XCTAssertEqual(holdoutIdMap["3004"]?.excludedFlags, ["2001"])

        let featureFlagKeyMap = projectConfig.featureFlagKeyMap
        
        /// Test Global holdout + included
        XCTAssertEqual(featureFlagKeyMap["key_2000"]?.holdoutIds, ["3000", "3001", "3002", "3003", "3004"])
        XCTAssertEqual(featureFlagKeyMap["key_2002"]?.holdoutIds, ["3000", "3001", "3002", "3003", "3004"])
        
        /// Test Global holdout - excluded
        XCTAssertEqual(featureFlagKeyMap["key_2001"]?.holdoutIds, ["3000", "3001", "3002"])
        
        /// Test Global holdout
        XCTAssertEqual(featureFlagKeyMap["key_2003"]?.holdoutIds, ["3000", "3001", "3002", "3004"])
    }
    
    func testFlagVariations() {
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        let optimizely = OptimizelyClient(sdkKey: "12345",
                                          userProfileService: OTUtils.createClearUserProfileService())
        try! optimizely.start(datafile: datafile)
        let allVariationsForFlag = optimizely.config!.flagVariationsMap
        
        let variations1 = allVariationsForFlag["feature_1"]!.map{ $0.key }
        XCTAssertEqual(variations1, ["a", "b", "3324490633", "3324490562", "18257766532"])
        
        let variations2 = allVariationsForFlag["feature_2"]!.map{ $0.key }
        XCTAssertEqual(variations2, ["variation_with_traffic", "variation_no_traffic"])

        let variations3 = allVariationsForFlag["feature_3"]!.map{ $0.key }
        XCTAssertEqual(variations3, [])
    }
    
    func testAllSegments() {
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        let optimizely = OptimizelyClient(sdkKey: "12345",
                                          userProfileService: OTUtils.createClearUserProfileService())
        try! optimizely.start(datafile: datafile)
        let segments = optimizely.config!.allSegments
        XCTAssertEqual(3, segments.count, "redundant items should be filtered out")
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(segments))
        XCTAssertEqual("W4WzcEs-ABgXorzY7h1LCQ", optimizely.config!.publicKeyForODP)
        XCTAssertEqual("https://api.zaius.com", optimizely.config!.hostForODP)
    }
    
}

// MARK: - Others

extension ProjectConfigTests {
    
    func testGetForcedVariation_InvalidExperimentKey() {
        let variationKey = config.getForcedVariation(experimentKey: "invalid_key", userId: "user").result
        XCTAssertNil(variationKey)
    }
    
    func testGetForcedVariation_InvalidVariationKey() {
        let experimentKey = "exp_with_audience"
        let userId = "user"

        // set forced variation for "variation a"
        let status = config.setForcedVariation(experimentKey: experimentKey, userId: userId, variationKey: "a")
        XCTAssert(status)

        // remove "variation a" from experiment
        var experiment = config.getExperiment(key: experimentKey)!
        experiment.variations = experiment.variations.filter{ $0.key == "b" }

        config.experimentKeyMap[experimentKey] = experiment
        
        // forced variation finds variation which is not valid any more
        let variationKey = config.getForcedVariation(experimentKey: experimentKey, userId: userId).result
        XCTAssertNil(variationKey)
    }

    func testSetForcedVariation_InvalidExperimentKey() {
        let result = config.setForcedVariation(experimentKey: "invalid_key", userId: "user", variationKey: "a")
        XCTAssertFalse(result)
    }
    
    func testSetForcedVariation_EmptyVariationKey() {
        let result = config.setForcedVariation(experimentKey: "exp_with_audience", userId: "user", variationKey: " ")
        XCTAssertFalse(result)
    }

    func testSetForcedVariation_InvalidVariationKey() {
        let result = config.setForcedVariation(experimentKey: "exp_with_audience", userId: "user", variationKey: "invalid_key")
        XCTAssertFalse(result)
    }
    
    func testSetForcedVariation_ExistingUser() {
        let experimentKey = "exp_with_audience"
        let userId = "user"

        var result = config.setForcedVariation(experimentKey: experimentKey, userId: userId, variationKey: "a")
        XCTAssert(result)
        var variation = config.getForcedVariation(experimentKey: experimentKey, userId: userId).result!
        XCTAssertEqual(variation.key, "a")

        result = config.setForcedVariation(experimentKey: experimentKey, userId: userId, variationKey: "b")
        XCTAssert(result)
        variation = config.getForcedVariation(experimentKey: experimentKey, userId: userId).result!
        XCTAssertEqual(variation.key, "b")
    }

}
