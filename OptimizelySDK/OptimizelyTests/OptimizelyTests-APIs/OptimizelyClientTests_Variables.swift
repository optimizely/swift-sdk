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

class OptimizelyClientTests_Variables: XCTestCase {
    
    let kVariableId = "1111"
    let kVariableDefaultValue = 20
    let kVariableValueA = 30
    
    let kUserId = "12345"
    let kExperimentId = "11111"
    
    var sampleExperimentData: [String: Any] { return
        [
            "status": "Running",
            "id": kExperimentId,
            "key": "43432134",
            "layerId": "10420273888",
            "trafficAllocation": [
                [
                    "entityId": "10389729780",
                    "endOfRange": 10000
                ]
            ],
            "audienceIds": [],
            "variations": [
                [
                    "variables": [
                        ["id": kVariableId, "value": String(kVariableValueA)]
                    ],
                    "id": "10389729780",
                    "key": "16456523121"
                ]
            ],
            "forcedVariations":[:]
        ]
    }
    var sampleFeatureFlagData: [String: Any] { return
        [
            "id": "553339214",
            "key": "house",
            "experimentIds":[kExperimentId],
            "rolloutId": "",
            "variables": [
                [
                    "defaultValue": String(kVariableDefaultValue),
                    "type": "integer",
                    "id": kVariableId,
                    "key": "window"
                ]
            ]
        ]
    }
    
    var optimizely: OptimizelyClient!
    var experiment: Experiment!
    var featureFlag: FeatureFlag!
    
    override func setUp() {
        super.setUp()
        
        optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                              clearUserProfileService: true)!
        
        let featureFlag: FeatureFlag = try! OTUtils.model(from: sampleFeatureFlagData)
        optimizely.config!.project.featureFlags = [featureFlag]
    }


    func testFeatureVariableWhenFeatureEnabled() {
        var experiment: Experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.variations[0].featureEnabled = true
        optimizely.config!.project.experiments = [experiment]
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId)
        
        XCTAssertEqual(value, kVariableValueA)
    }
    
    func testFeatureVariableWhenFeatureDisabled() {
        var experiment: Experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.variations[0].featureEnabled = false
        optimizely.config!.project.experiments = [experiment]
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId)
        
        XCTAssertEqual(value, kVariableDefaultValue)
    }

    func testFeatureVariableWhenFeatureEnabledNil() {
        var experiment: Experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.variations[0].featureEnabled = nil
        optimizely.config!.project.experiments = [experiment]
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId)
        
        XCTAssertEqual(value, kVariableDefaultValue)
    }

}
