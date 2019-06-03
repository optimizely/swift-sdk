//
/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/
    

import XCTest

class ProjectConfigTests: XCTestCase {


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
}
