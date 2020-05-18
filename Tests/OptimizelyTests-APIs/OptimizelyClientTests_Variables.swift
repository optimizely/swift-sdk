/****************************************************************************
 * Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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
    var kRolloutId = "rollout11"
    var kRolloutExperimentId = "rolloutExp11"
    var kRolloutExperimentId2 = "rolloutExp12"
    var kRolloutExperimentId3 = "rolloutExp13"
    
    let kRolloutVariableValueA = 40
    let kRolloutVariableValueB = 50
    let kRolloutVariableValueC = 60
    
    var kRolloutAudienceIdAge1 = "30"
    var kRolloutAudienceIdAge2 = "40"
    var kAttributesRolloutAge1Match: [String: Any] = ["age": 20]
    var kAttributesRolloutAge2Match: [String: Any] = ["age": 30]
    var kAttributesRolloutNotMatch: [String: Any] = ["age": 40]
    
    var kRolloutVariationKeyA = "rolloutA"
    var kRolloutVariationKeyB = "rolloutB"
    var kRolloutVariationKeyC = "rolloutC"
    
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
            "forcedVariations": [:]
        ]
    }
    var sampleFeatureFlagData: [String: Any] { return
        [
            "id": "553339214",
            "key": "house",
            "experimentIds": [kExperimentId],
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
    
    var sampleRolloutData: [String: Any] { return
        [
            "id": kRolloutId,
            "experiments": sampleRolloutExperimentData
        ]
    }
    
    var sampleRolloutExperimentData: [[String: Any]] { return
        [
            [
                "status": "Running",
                "id": kRolloutExperimentId,
                "key": "rolloutExp",
                "layerId": "10420273888",
                "trafficAllocation": [
                    [
                        "entityId": "10389700000",
                        "endOfRange": 10000
                    ]
                ],
                "audienceIds": [kRolloutAudienceIdAge1],
                "variations": [
                    [
                        "variables": [["id": kVariableId, "value": String(kRolloutVariableValueA)]],
                        "id": "10389700000",
                        "key": kRolloutVariationKeyA,
                        "featureEnabled": true
                    ]
                ],
                "forcedVariations": [:]
            ],
            [
                "status": "Running",
                "id": kRolloutExperimentId2,
                "key": "rolloutExp1",
                "layerId": "10420273889",
                "trafficAllocation": [
                    [
                        "entityId": "10389700000",
                        "endOfRange": 10000
                    ]
                ],
                "audienceIds": [kRolloutAudienceIdAge2],
                "variations": [
                    [
                        "variables": [["id": kVariableId, "value": String(kRolloutVariableValueB)]],
                        "id": "10389700000",
                        "key": kRolloutVariationKeyB,
                        "featureEnabled": true
                    ]
                ],
                "forcedVariations": [:]
            ],
            [
                "status": "Running",
                "id": kRolloutExperimentId3,
                "key": "rolloutExp2",
                "layerId": "10420273890",
                "trafficAllocation": [
                    [
                        "entityId": "10389700000",
                        "endOfRange": 10000
                    ]
                ],
                "audienceIds": [],
                "variations": [
                    [
                        "variables": [["id": kVariableId, "value": String(kRolloutVariableValueC)]],
                        "id": "10389700000",
                        "key": kRolloutVariationKeyC,
                        "featureEnabled": true
                    ]
                ],
                "forcedVariations": [:]
            ]
        ]
    }
    
    var sampleRolloutTypedAudiencesData: [[String: Any]] { return
        [
            [
                "id": kRolloutAudienceIdAge1,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "lt", "value": 30 ],
                "name": "age"
            ],
            [
                "id": kRolloutAudienceIdAge2,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "lt", "value": 40 ],
                "name": "age"
            ]
        ]
    }
    
    var optimizely: OptimizelyClient!
    var featureFlag: FeatureFlag!
    
    override func setUp() {
        super.setUp()
        
        optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                              clearUserProfileService: true)!
        
        featureFlag = try! OTUtils.model(from: sampleFeatureFlagData)
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

// MARK: - Test getFeatureVariableForFeatureRollout()

extension OptimizelyClientTests_Variables {
    
    func testFeatureVariableWhenBucketedToRollout() {
        optimizely.config!.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        optimizely.config!.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        optimizely.config!.project.featureFlags = [featureFlag]
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId, attributes: kAttributesRolloutAge1Match)
        XCTAssert(value == kRolloutVariableValueA)
    }
    
    func testFeatureVariableWhenBucketedToRolloutUsingSecondRule() {
        optimizely.config!.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        optimizely.config!.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        optimizely.config!.project.featureFlags = [featureFlag]
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId, attributes: kAttributesRolloutAge2Match)
        XCTAssert(value == kRolloutVariableValueB)
    }
    
    func testFeatureVariableWhenBucketedToRolloutUsingFallbackRule() {
        optimizely.config!.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        optimizely.config!.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        optimizely.config!.project.featureFlags = [featureFlag]
        optimizely.config!.project.rollouts[0].experiments[0].trafficAllocation[0].endOfRange = 0
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId, attributes: kAttributesRolloutAge1Match)
        XCTAssert(value == kRolloutVariableValueC)
    }
    
    func testFeatureVariableReturnsDefaultValueWhenFeatureDisabled() {
        optimizely.config!.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        optimizely.config!.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        optimizely.config!.project.featureFlags = [featureFlag]
        optimizely.config!.project.rollouts[0].experiments[0].variations[0].featureEnabled = false
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId, attributes: kAttributesRolloutAge1Match)
        XCTAssert(value == kVariableDefaultValue)
    }
    
    func testFeatureVariableReturnsDefaultValueWhenRolloutBucketingReturnsNil() {
        optimizely.config!.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        optimizely.config!.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        optimizely.config!.project.featureFlags = [featureFlag]
        optimizely.config!.project.rollouts[0].experiments = []
        
        let value = try! optimizely.getFeatureVariableInteger(featureKey: "house", variableKey: "window", userId: kUserId, attributes: kAttributesRolloutAge1Match)
        XCTAssert(value == kVariableDefaultValue)
    }
}
