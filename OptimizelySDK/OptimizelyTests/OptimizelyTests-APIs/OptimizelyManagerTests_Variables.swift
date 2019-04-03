//
//  OptimizelyManagerTests_Variables.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Jae Kim on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Variables: XCTestCase {
    
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
    
    var optimizely: OptimizelyManager!
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
