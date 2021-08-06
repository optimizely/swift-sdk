//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

class DecisionServiceTests_Features: XCTestCase {
    
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    
    var kUserId = "12345"
    var kExperimentKey = "countryExperiment"
    var kExperimentId = "country11"
    var kRolloutId = "rollout11"
    var kRolloutExperimentId = "rolloutExp11"
    var kRolloutExperimentId2 = "rolloutExp12"
    var kRolloutExperimentId3 = "rolloutExp13"

    var kVariationKeyA = "a"
    var kVariationKeyB = "b"
    var kVariationKeyC = "c"
    var kVariationKeyD = "d"
    
    var kAudienceIdCountry = "10"
    var kAudienceIdAge = "20"
    var kAudienceIdInvalid = "9999999"
    
    var kRolloutVariationKeyA = "rolloutA"
    var kRolloutVariationKeyB = "rolloutB"
    var kRolloutVariationKeyC = "rolloutC"
    
    var kRolloutAudienceIdAge1 = "30"
    var kRolloutAudienceIdAge2 = "40"
    
    var kAttributesCountryMatch: [String: Any] = ["country": "us"]
    var kAttributesCountryNotMatch: [String: Any] = ["country": "ca"]
    var kAttributesAgeMatch: [String: Any] = ["age": 30]
    var kAttributesAgeNotMatch: [String: Any] = ["age": 10]
    var kAttributesEmpty: [String: Any] = [:]
    var kAttributesRolloutAge1Match: [String: Any] = ["age": 20]
    var kAttributesRolloutAge2Match: [String: Any] = ["age": 30]
    var kAttributesRolloutNotMatch: [String: Any] = ["age": 40]
    
    var experiment: Experiment!
    var variation: Variation!
    var featureFlag: FeatureFlag!
    var result: Bool!
    
    // MARK: - Sample datafile data
    
    let emptyExperimentData: [String: Any] = [
        "id": "11111",
        "key": "empty",
        "status": "Running",
        "layerId": "22222",
        "variations": [],
        "trafficAllocation": [],
        "audienceIds": [],
        "forcedVariations": [:]]
    
    var sampleExperimentData: [String: Any] { return
        [
            "status": "Running",
            "id": kExperimentId,
            "key": kExperimentKey,
            "layerId": "10420273888",
            "trafficAllocation": [
                [
                    "entityId": "16456523121",
                    "endOfRange": 10000
                ]
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                [
                    "variables": [],
                    "id": "10389729780",
                    "key": kVariationKeyA
                ],
                [
                    "variables": [],
                    "id": "10416523121",
                    "key": kVariationKeyB
                ],
                [
                    "variables": [],
                    "id": "13456523121",
                    "key": kVariationKeyC
                ],
                [
                    "variables": [],
                    "id": "16456523121",
                    "key": kVariationKeyD
                ]
            ],
            "forcedVariations": [:]
        ]
    }
    
    var sampleTypedAudiencesData: [[String: Any]] { return
        [
            [
                "id": kAudienceIdCountry,
                "conditions": [ "type": "custom_attribute", "name": "country", "match": "exact", "value": "us" ],
                "name": "country"
            ],
            [
                "id": kAudienceIdAge,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "gt", "value": 17 ],
                "name": "age"
            ]
        ]
    }
    
    var sampleFeatureFlagData: [String: Any] { return
        [
            "id": "553339214",
            "key": "house",
            "experimentIds": [kExperimentId],
            "rolloutId": "",
            "variables": []
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
                        "variables": [],
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
                        "variables": [],
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
                        "variables": [],
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
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                   clearUserProfileService: true)
        self.config = self.optimizely.config!
        self.decisionService = (optimizely.decisionService as! DefaultDecisionService)
        
        // project config
        
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdCountry]
        self.config.project.experiments = [experiment]
        
        featureFlag = try! OTUtils.model(from: sampleFeatureFlagData)
        self.config.project.featureFlags = [featureFlag]
    }
    
}

// MARK: - Test getVariationForFeatureExperiment()

extension DecisionServiceTests_Features {
    
    func testGetVariationForFeatureExperimentWhenMatched() {
        let pair = self.decisionService.getVariationForFeatureExperiment(config: config,
                                                                         featureFlag: featureFlag,
                                                                         userId: kUserId,
                                                                         attributes: kAttributesCountryMatch).result
        XCTAssert(pair?.experiment.key == kExperimentKey)
        XCTAssert(pair?.variation.key == kVariationKeyD)
        XCTAssert(pair?.source == Constants.DecisionSource.featureTest.rawValue)
    }
    
    func testGetVariationForFeatureExperimentWhenNotMatched() {
        let pair = self.decisionService.getVariationForFeatureExperiment(config: config,
                                                                         featureFlag: featureFlag,
                                                                         userId: kUserId,
                                                                         attributes: kAttributesCountryNotMatch).result
        XCTAssertNil(pair)
    }
    
    func testGetVariationForFeatureExperimentWhenNoExperimentFound() {
        featureFlag = try! OTUtils.model(from: sampleFeatureFlagData)
        featureFlag.experimentIds = ["99999"]   // not-existing experiment
        self.config.project.featureFlags = [featureFlag]
        
        let pair = self.decisionService.getVariationForFeatureExperiment(config: config,
                                                                         featureFlag: featureFlag,
                                                                         userId: kUserId,
                                                                         attributes: kAttributesCountryMatch).result
        XCTAssertNil(pair)
    }
    
}

// MARK: - Test getVariationForFeatureRollout()

extension DecisionServiceTests_Features {
    
    func testGetVariationForFeatureRollout() {
        // rollout set
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let pair = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge1Match).result
        
        XCTAssert(pair?.experiment.id == kRolloutExperimentId)
        XCTAssert(pair?.variation.key == kRolloutVariationKeyA)
        XCTAssert(pair?.source == Constants.DecisionSource.rollout.rawValue)
    }
    
    func testGetVariationForFeatureRolloutEmpty() {
        let variation = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesEmpty).result
        XCTAssertNil(variation)
    }
    
    func testGetVariationForFeatureRolloutNotFound() {
        // rollout set
        self.config.project.rollouts = []
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let variation = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesEmpty).result
        XCTAssertNil(variation)
    }
    
    func testGetVariationForFeatureRolloutEmptyRules() {
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.rollouts[0].experiments = []
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let variation = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge1Match).result
        XCTAssertNil(variation)
    }
    
    func testGetVariationForFeatureRolloutFallbackRule() {
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        self.config.project.rollouts[0].experiments[0].trafficAllocation[0].endOfRange = 0
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let pair = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge1Match).result
        XCTAssert(pair?.experiment.id == kRolloutExperimentId3)
        XCTAssert(pair?.variation.key == kRolloutVariationKeyC)
        XCTAssert(pair?.source == Constants.DecisionSource.rollout.rawValue)
    }
    
    func testGetVariationForFeatureRolloutEvaluatesNextIfAudienceEvaluationFails() {
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let pair = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge2Match).result
        XCTAssert(pair?.experiment.id == kRolloutExperimentId2)
        XCTAssert(pair?.variation.key == kRolloutVariationKeyB)
        XCTAssert(pair?.source == Constants.DecisionSource.rollout.rawValue)
    }
    
    func testGetVariationForFeatureRolloutWithSameAudiencesReturnsFirstVariation() {
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.rollouts[0].experiments[1].audienceIds = [kRolloutAudienceIdAge1]
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let pair = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge1Match).result
        XCTAssert(pair?.experiment.id == kRolloutExperimentId)
        XCTAssert(pair?.variation.key == kRolloutVariationKeyA)
        XCTAssert(pair?.source == Constants.DecisionSource.rollout.rawValue)
    }
    
    func testGetVariationForFeatureRolloutReturnsNilIfAudienceEvaluationFailsForFallback() {
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        self.config.project.rollouts[0].experiments[0].audienceIds = [kRolloutAudienceIdAge2]
        self.config.project.rollouts[0].experiments[0].trafficAllocation[0].endOfRange = 0
        self.config.project.rollouts[0].experiments[2].audienceIds = [kRolloutAudienceIdAge1]
        let pair = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge2Match).result
        XCTAssertNil(pair)
    }
    
    func testGetVariationForFeatureRolloutReturnsNilIfBucketingFailsForFallback() {
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleRolloutTypedAudiencesData)
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        self.config.project.rollouts[0].experiments[0].trafficAllocation[0].endOfRange = 0
        self.config.project.rollouts[0].experiments[2].trafficAllocation[0].endOfRange = 0
        let pair = self.decisionService.getVariationForFeatureRollout(config: config,
                                                                           featureFlag: featureFlag,
                                                                           userId: kUserId,
                                                                           attributes: kAttributesRolloutAge1Match).result
        XCTAssertNil(pair?.variation)
    }
}

// MARK: - Test getVariationForFeatureERollout()

extension DecisionServiceTests_Features {
    
    func testGetVariationForFeatureWhenExperimentMatch() {
        let pair = self.decisionService.getVariationForFeature(config: config,
                                                               featureFlag: featureFlag,
                                                               userId: kUserId,
                                                               attributes: kAttributesCountryMatch).result
        XCTAssert(pair?.experiment.key == kExperimentKey)
        XCTAssert(pair?.variation.key == kVariationKeyD)
    }
    
    func testGetVariationForFeatureWhenExperimentNotMatchAndRolloutNotExist() {
        let pair = self.decisionService.getVariationForFeature(config: config,
                                                               featureFlag: featureFlag,
                                                               userId: kUserId,
                                                               attributes: kAttributesCountryNotMatch).result
        XCTAssertNil(pair)
    }
    
    func testGetVariationForFeatureWhenExperimentNotMatchAndRolloutExist() {
        // rollout set
        self.config.project.rollouts = [try! OTUtils.model(from: sampleRolloutData)]
        featureFlag.rolloutId = kRolloutId
        self.config.project.featureFlags = [featureFlag]
        
        let pair = self.decisionService.getVariationForFeature(config: config,
                                                               featureFlag: featureFlag,
                                                               userId: kUserId,
                                                               attributes: kAttributesCountryNotMatch).result
        XCTAssert(pair?.experiment.id == kRolloutExperimentId3)
        XCTAssert(pair?.variation.key == kRolloutVariationKeyC)
    }
    
}
