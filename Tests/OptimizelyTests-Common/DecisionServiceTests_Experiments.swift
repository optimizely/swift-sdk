/****************************************************************************
* Copyright 2019-2021, Optimizely, Inc. and contributors                   *
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

class MockLogger: OPTLogger {
    static var logFound = false
    static var expectedLog = ""
    private static var _logLevel: OptimizelyLogLevel?
    
    public static var logLevel: OptimizelyLogLevel {
        get {
            return _logLevel ?? .info
        }
        set (newLevel){
            if _logLevel == nil {
                _logLevel = newLevel
            }
        }
    }
    
    required public init() {
        MockLogger.logLevel = .info
    }
    
    open func log(level: OptimizelyLogLevel, message: String) {
        if  ("[Optimizely][Error] " + message) == MockLogger.expectedLog {
            MockLogger.logFound = true
        }
    }
}

class DecisionServiceTests_Experiments: XCTestCase {
    
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    var mockLogger = MockLogger()
    
    var kUserId = "12345"
    var kExperimentKey = "countryExperiment"
    var kExperimentId = "country11"
    
    var kVariationKeyA = "a"
    var kVariationKeyB = "b"
    var kVariationKeyC = "c"
    var kVariationKeyD = "d"
    
    var kAudienceIdCountry = "10"
    var kAudienceIdAge = "20"
    var kAudienceIdExactAge = "30"
    var kAudienceIdLtAge = "40"
    var kAudienceIdSubstringAge = "50"
    var kAudienceIdInvalid = "9999999"
    
    var kAudienceIdNilValue = "60"
    var kAudienceIdExactInvalidValue = "70"
    var kAudienceIdInvalidType = "80"
    var kAudienceIdGtInvalidValue = "90"
    var kAudienceIdInvalidMatchType = "100"
    var kAudienceIdLtInvalidValue = "110"
    var kAudienceIdSubstringInvalidValue = "120"
    var kAudienceIdInvalidName = "130"
    
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
                    "id": "10416523110",
                    "key": kVariationKeyB
                ],
                [
                    "variables": [],
                    "id": "13456523111",
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
            ],
            [
                "id": kAudienceIdExactAge,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "exact", "value": 17 ],
                "name": "age"
            ],
            [
                "id": kAudienceIdLtAge,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "lt", "value": 17 ],
                "name": "age"
            ],
            [
                "id": kAudienceIdSubstringAge,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "substring", "value": "twelve" ],
                "name": "age"
            ],
            [
                "id": kAudienceIdInvalidType,
                "conditions": [ "type": "", "name": "age", "match": "gt", "value": 17 ],
                "name": "age"
            ],
            [
                "id": kAudienceIdInvalidMatchType,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "", "value": 17 ],
                "name": "age"
            ],
            [
                "id": kAudienceIdInvalidName,
                "conditions": [ "type": "custom_attribute", "match": "gt", "value": 17 ],
                "name": "age"
            ],
            [
                "id": kAudienceIdNilValue,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "gt" ],
                "name": "age"
            ],
            [
                "id": kAudienceIdExactInvalidValue,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "exact", "value": ["invalid"] ],
                "name": "age"
            ],
            [
                "id": kAudienceIdGtInvalidValue,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "gt", "value": ["invalid"] ],
                "name": "age"
            ],
            [
                "id": kAudienceIdLtInvalidValue,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "lt", "value": ["invalid"] ],
                "name": "age"
            ],
            [
                "id": kAudienceIdSubstringInvalidValue,
                "conditions": [ "type": "custom_attribute", "name": "age", "match": "substring", "value": 151 ],
                "name": "age"
            ]
        ]
    }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        HandlerRegistryService.shared.binders.property?.removeAll()
        let binder: Binder = Binder<OPTLogger>(service: OPTLogger.self).to { () -> OPTLogger? in
            return self.mockLogger
        }
        HandlerRegistryService.shared.registerBinding(binder: binder)
        
        MockLogger.logFound = false
        MockLogger.expectedLog = ""
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                   clearUserProfileService: true,
                                                   logger: mockLogger)
        self.config = self.optimizely.config!
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
        
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
        XCTAssertNil(variation, "no matching audience should return nil")
        
        // (1) non-running experiement should return nil
        
        experiment.status = .paused
        self.config.project.experiments = [experiment]
        
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
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
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
        XCTAssert(variation!.key == kVariationKeyA, "local forcedVariation should override")
        
        // (3) remote whitelisting overrides
        
        // reset local forcedVariation
        _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                               userId: kUserId,
                                               variationKey: nil)
        
        // no local variation, so now remote variation works
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
        XCTAssert(variation!.key == kVariationKeyB, "remote forcedVariation should override")
        
        // reset remote forcedVariations as well
        experiment.forcedVariations = [:]
        self.config.project.experiments = [experiment]
        
        // (4) UserProfileService
        
        // UserProfileService data not updated for decisions by forcedVariations, so no change
        
        // (5) desicion + bucketing
        
        // no variation mapped for invalid audience id
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
        XCTAssertNil(variation, "no matching audience should return nil")
        
    }
    
    func testGetVariationStepsNoForcedVariationsAndNoUserProfile() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        let experiment: Experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        // (0) no forcedVariation + no UserProfileService (reset), no attributes -> decision returns nil
        
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesEmpty).result
        XCTAssertNil(variation, "bucketing should return nil")
        
        // (1) desicion + bucketing
        
        // no forced variations + no UserProfileService, so local decision + bucketing should return valid variation
        
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
        XCTAssert(variation!.key == kVariationKeyD, "bucketing should work")
        
        // (2) UserProfileService updated by previous decisions
        
        // no attributes, but UserProfile data by (1) will return valid variatin
        
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesEmpty).result
        XCTAssert(variation!.key == kVariationKeyD, "bucketing should work")
    }
    
    func testGetVariationWithInvalidRemoteForcedVariation() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = []  // empty audiences, so all pass
        
        // remote forcedVariation mapped to an invalid variation
        // decision should ignore this
        
        experiment.forcedVariations = [kUserId: "invalid_variation_key"]
        self.config.project.experiments = [experiment]
        
        // no local variation, so now remote variation works
        variation = self.decisionService.getVariation(config: config,
                                                      experiment: experiment,
                                                      userId: kUserId,
                                                      attributes: kAttributesCountryMatch).result
        XCTAssert(variation!.key == kVariationKeyD, "invalid forced variation should be skipped")
    }
    
}

// MARK: - Test doesMeetAudienceConditions()

extension DecisionServiceTests_Experiments {
    
    func testDoesMeetAudienceConditionsWithAudienceConditions() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        // (1) matching true
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = try! OTUtils.model(from: ["or", kAudienceIdCountry])
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result, "attribute should be matched to audienceConditions")
        
        // (2) matching false
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryNotMatch).result
        XCTAssertFalse(result, "attribute should be matched to audienceConditions")
        
        // (3) other attribute
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        XCTAssertFalse(result, "no matching attribute provided")
    }
    
    func testDoesMeetAudienceConditionsWithAudienceIds() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        // (1) matching true
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = nil
        experiment.audienceIds = [kAudienceIdCountry]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result, "attribute should be matched to audienceConditions")
        
        // (2) matching false
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryNotMatch).result
        XCTAssertFalse(result, "attribute should be matched to audienceConditions")
        
        // (3) other attribute
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        XCTAssertFalse(result, "no matching attribute provided")
    }
    
    func testDoesMeetAudienceConditionsWithAudienceConditionsEmptyArray() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = try! OTUtils.model(from: [])
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result, "empty conditions is true always")
    }
    
    func testDoesMeetAudienceConditionsWithAudienceIdsEmpty() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceConditions = nil
        experiment.audienceIds = []
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result, "empty conditions is true always")
    }
    
    func testDoesMeetAudienceConditionsWithCornerCases() {
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        
        // (1) leaf (not array) in "audienceConditions" still works ok
        
        // JSON does not support raw string, so wrap in array for decode
        var array: [ConditionHolder] = try! OTUtils.model(from: [kAudienceIdCountry])
        experiment.audienceConditions = array[0]
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result)
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesEmpty).result
        XCTAssertFalse(result)
        
        // (2) invalid string in "audienceConditions"
        array = try! OTUtils.model(from: ["and"])
        experiment.audienceConditions = array[0]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result)
        
        // (2) invalid string in "audienceConditions"
        experiment.audienceConditions = nil
        experiment.audienceIds = []
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        XCTAssert(result)
    }
    
}

// MARK: - Test doesMeetAudienceConditions() Error Logs

extension DecisionServiceTests_Experiments {
    
    func testDoesMeetAudienceConditionsWithInvalidType() {
        MockLogger.expectedLog = OptimizelyError.userAttributeInvalidType("{\"match\":\"gt\",\"value\":17,\"name\":\"age\",\"type\":\"\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdInvalidType]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithInvalidMatchType() {
        MockLogger.expectedLog = OptimizelyError.userAttributeInvalidMatch("{\"match\":\"\",\"value\":17,\"name\":\"age\",\"type\":\"custom_attribute\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdInvalidMatchType]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithInvalidName() {
        MockLogger.expectedLog = OptimizelyError.userAttributeInvalidName("{\"type\":\"custom_attribute\",\"match\":\"gt\",\"value\":17}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdInvalidName]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithMissingAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.missingAttributeValue("{\"match\":\"gt\",\"value\":17,\"name\":\"age\",\"type\":\"custom_attribute\"}", "age").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesCountryMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithNilUserAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.userAttributeNilValue("{\"name\":\"age\",\"type\":\"custom_attribute\",\"match\":\"gt\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdNilValue]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithNilAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.nilAttributeValue("{\"match\":\"gt\",\"value\":17,\"name\":\"age\",\"type\":\"custom_attribute\"}", "age").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: ["age": nil]).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithExactMatchAndInvalidValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidCondition("{\"match\":\"exact\",\"value\":{},\"name\":\"age\",\"type\":\"custom_attribute\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdExactInvalidValue]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithExactMatchAndInvalidAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidType("{\"match\":\"exact\",\"value\":\"us\",\"name\":\"country\",\"type\":\"custom_attribute\"}",["invalid"],"country").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdCountry]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: ["country": ["invalid"]]).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithExactMatchAndInfiniteAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeValueOutOfRange("{\"match\":\"exact\",\"value\":17,\"name\":\"age\",\"type\":\"custom_attribute\"}","age").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdExactAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: ["age": Double.infinity]).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithGreaterMatchAndInvalidValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidCondition("{\"match\":\"gt\",\"value\":{},\"name\":\"age\",\"type\":\"custom_attribute\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdGtInvalidValue]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithGreaterMatchAndInvalidAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidType("{\"match\":\"gt\",\"value\":17,\"name\":\"age\",\"type\":\"custom_attribute\"}", ["invalid"], "age").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: ["age": ["invalid"]]).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithLessMatchAndInvalidValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidCondition("{\"match\":\"lt\",\"value\":{},\"name\":\"age\",\"type\":\"custom_attribute\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdLtInvalidValue]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithLessMatchAndInvalidAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidType("{\"match\":\"lt\",\"value\":17,\"name\":\"age\",\"type\":\"custom_attribute\"}", ["invalid"], "age").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdLtAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: ["age": ["invalid"]]).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithSubstringMatchAndInvalidValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidCondition("{\"match\":\"substring\",\"value\":151,\"name\":\"age\",\"type\":\"custom_attribute\"}").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdSubstringInvalidValue]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: kAttributesAgeMatch).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
    }
    
    func testDoesMeetAudienceConditionsWithSubstringMatchAndInvalidAttributeValue() {
        MockLogger.expectedLog = OptimizelyError.evaluateAttributeInvalidType("{\"match\":\"substring\",\"value\":\"twelve\",\"name\":\"age\",\"type\":\"custom_attribute\"}", ["invalid"], "age").localizedDescription
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdSubstringAge]
        self.config.project.experiments = [experiment]
        
        result = self.decisionService.doesMeetAudienceConditions(config: config,
                                                                 experiment: experiment,
                                                                 userId: kUserId,
                                                                 attributes: ["age": ["invalid"]]).result
        
        XCTAssert(MockLogger.logFound)
        XCTAssertFalse(result)
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
