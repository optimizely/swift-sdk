//
//  DecisionServiceTests_Experiments.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/5/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DecisionServiceTests_Experiments: XCTestCase {

    var optimizely: OptimizelyManager!
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    var bucketer: OPTBucketer!
    
    var kUserId = "12345"
    var kExperimentKey = "countryExperiment"
    var kExperimentId = "country11"

    var kVariationKeyA = "a"
    var kVariationKeyB = "b"
    var kVariationKeyC = "c"
    var kVariationKeyD = "d"
    
    var kAudienceIdCountry = "10"
    var kAudienceIdAge = "20"
    var kAudienceIdInvalid = "9999999"

    var kAttributesCountryMatch: [String: Any] = ["country": "us"]
    var kAttributesCountryNotMatch: [String: Any] = ["country": "ca"]
    var kAttributesAgeMatch: [String: Any] = ["age": 30]
    var kAttributesAgeNotMatch: [String: Any] = ["age": 10]
    var kAttributesEmpty: [String: Any] = [:]

    var experiment: Experiment!
    var variation: Variation!
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
        "forcedVariations":[:],
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
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                  clearUserProfileService: true)
        self.config = self.optimizely.config!
        self.bucketer = optimizely.bucketer
        self.decisionService = (optimizely.decisionService as! DefaultDecisionService)
    }
    
}

// MARK: - Test getVariation()

extension DecisionServiceTests_Experiments {

    func testGetVariationStepsWithForcedVariations() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdInvalid]
        self.config.project.experiments = [experiment]

        // (0) initial - no variation mapped for invalid audience id
        
        variation = self.decisionService.getVariation(userId: kUserId,
                                                     experiment: experiment,
                                                     attributes: kAttributesCountryMatch)
        XCTAssertNil(variation, "no matching audience should return nil")
        
        // (1) non-running experiement should return nil
        
        experiment.status = .paused
        self.config.project.experiments = [experiment]
        
        variation = self.decisionService.getVariation(userId: kUserId,
                                                     experiment: experiment,
                                                     attributes: kAttributesCountryMatch)
        XCTAssertNil(variation, "not running experiments return nil")
        
        // recover to running state for following tests
        experiment.status = .running
        self.config.project.experiments = [experiment]

        // (2) local forcedVariation overrides
        
        // local forcedVariation
        _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                               userId: kUserId,
                                               variationKey: kVariationKeyA)
        
        // remote forcedVariation (different map for the same user)
        experiment.forcedVariations = [kUserId: kVariationKeyB]
        self.config.project.experiments = [experiment]

        // local forcedVariation wins
        variation = self.decisionService.getVariation(userId: kUserId,
                                                     experiment: experiment,
                                                     attributes: kAttributesCountryMatch)
        XCTAssert(variation!.key == kVariationKeyA, "local forcedVariation should override")
        
        // (3) remote whitelisting overrides
        
        // reset local forcedVariation
        _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                               userId: kUserId,
                                               variationKey: nil)
        
        // no local variation, so now remote variation works
        variation = self.decisionService.getVariation(userId: kUserId,
                                                             experiment: experiment,
                                                             attributes: kAttributesCountryMatch)
        XCTAssert(variation!.key == kVariationKeyB, "remote forcedVariation should override")
        
        // reset remote forcedVariations as well
        experiment.forcedVariations = [:]
        self.config.project.experiments = [experiment]
        
        // (4) UserProfileService
        
        // UserProfileService data not updated for decisions by forcedVariations, so no change

        // (5) desicion + bucketing
        

        // no variation mapped for invalid audience id
        variation = self.decisionService.getVariation(userId: kUserId,
                                                     experiment: experiment,
                                                     attributes: kAttributesCountryMatch)
        XCTAssertNil(variation, "no matching audience should return nil")

    }
    
    func testGetVariationStepsNoForcedVariationsAndNoUserProfile() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)

        let experiment: Experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        // (0) no forcedVariation + no UserProfileService (reset), no attributes -> decision returns nil
        
        variation = self.decisionService.getVariation(userId: kUserId,
                                                             experiment: experiment,
                                                             attributes: kAttributesEmpty)
        XCTAssertNil(variation, "bucketing should return nil")

        // (1) desicion + bucketing
        
        // no forced variations + no UserProfileService, so local decision + bucketing should return valid variation
        
        variation = self.decisionService.getVariation(userId: kUserId,
                                                             experiment: experiment,
                                                             attributes: kAttributesCountryMatch)
        XCTAssert(variation!.key == kVariationKeyD, "bucketing should work")
        
        // (2) UserProfileService updated by previous decisions
        
        // no attributes, but UserProfile data by (1) will return valid variatin
        
        variation = self.decisionService.getVariation(userId: kUserId,
                                                             experiment: experiment,
                                                             attributes: kAttributesEmpty)
        XCTAssert(variation!.key == kVariationKeyD, "bucketing should work")
    }
    
}

// MARK: - Test getIsInExperiment()

extension DecisionServiceTests_Experiments {

    func testIsInExperimentWithAudienceConditions() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        // (1) matching true
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = try! OTUtils.model(from: ["or", kAudienceIdCountry])
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                                     userId: kUserId,
                                                                     attributes: kAttributesCountryMatch)
        XCTAssert(result, "attribute should be matched to audienceConditions")
        
        // (2) matching false
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                                     userId: kUserId,
                                                                     attributes: kAttributesCountryNotMatch)
        XCTAssertFalse(result, "attribute should be matched to audienceConditions")

        // (3) other attribute
        result = try? self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesAgeMatch)
        XCTAssertNil(result, "no matching attribute provided")
    }
    
    func testIsInExperimentWithAudienceIds() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        // (1) matching true
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = nil
        experiment.audienceIds = [kAudienceIdCountry]
        self.config.project.experiments = [experiment]
        
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                                     userId: kUserId,
                                                                     attributes: kAttributesCountryMatch)
        XCTAssert(result, "attribute should be matched to audienceConditions")
        
        // (2) matching false
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesCountryNotMatch)
        XCTAssertFalse(result, "attribute should be matched to audienceConditions")
        
        // (3) other attribute
        result = try? self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesAgeMatch)
        XCTAssertNil(result, "no matching attribute provided")
    }
    
    func testIsInExperimentWithAudienceConditionsEmptyArray() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = try! OTUtils.model(from: [])
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                              userId: kUserId,
                                                              attributes: kAttributesCountryMatch)
        XCTAssert(result, "empty conditions is true always")
    }
    
    func testIsInExperimentWithAudienceIdsEmpty() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = nil
        experiment.audienceIds = []
        self.config.project.experiments = [experiment]
        
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                              userId: kUserId,
                                                              attributes: kAttributesCountryMatch)
        XCTAssert(result, "empty conditions is true always")
    }

    func testIsInExperimentWithCornerCases() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        
        // (1) leaf (not array) in "audienceConditions" still works ok
        
        // JSON does not support raw string, so wrap in array for decode
        var array: [ConditionHolder] = try! OTUtils.model(from: [kAudienceIdCountry])
        experiment.audienceConditions = array[0]
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesCountryMatch)
        XCTAssert(result)
        
        result = try? self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesEmpty)
        XCTAssertNil(result)

        // (2) invalid string in "audienceConditions"
        array = try! OTUtils.model(from: ["and"])
        experiment.audienceConditions = array[0]
        self.config.project.experiments = [experiment]

        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesCountryMatch)
        XCTAssert(result)
        
        // (2) invalid string in "audienceConditions"
        experiment.audienceConditions = nil
        experiment.audienceIds = []
        self.config.project.experiments = [experiment]

        result = try! self.decisionService.isInExperiment(experiment: experiment,
                                                          userId: kUserId,
                                                          attributes: kAttributesCountryMatch)
        XCTAssert(result)
    }
    
}

// MARK: - Test getBucketingId()

extension DecisionServiceTests_Experiments {

    func testGetBucketingId() {
        var attributes: [String: Any]
        var bucketId: String
        var expBucketId: String
            
        attributes = kAttributesCountryMatch
        expBucketId = kUserId
        bucketId = self.decisionService.getBucketingId(userId: kUserId, attributes: attributes)
        XCTAssert(bucketId == expBucketId)
        
        attributes = ["$opt_bucketing_id": "99999"]
        expBucketId = "99999"
        bucketId = self.decisionService.getBucketingId(userId: kUserId, attributes: attributes)
        XCTAssert(bucketId == expBucketId)
    }
    
}

