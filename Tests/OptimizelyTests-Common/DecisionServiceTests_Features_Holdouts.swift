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

class DecisionServiceTests_Features_Holdouts: XCTestCase {
    
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    
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
   
    var experiment: Experiment!
    var holdout: Holdout!
    var variation: Variation!
    var featureFlag: FeatureFlag!
    
    // MARK: - Sample datafile data
    
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
            ]
        ]
    }
    
    var sampleFeatureFlagData: [String: Any] { return
        [
            "id": "flag_id_1234",
            "key": "flag_key",
            "experimentIds": [kExperimentId],
            "rolloutId": "",
            "variables": []
        ]
    }
    
    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "holdout_4444444",
            "key": "holdout_key",
            "layerId": "10420273888",
            "trafficAllocation": [
                ["entityId": "holdout_variation_a11", "endOfRange": 1000] // 10% traffic allocation
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                [
                    "variables": [],
                    "id": "holdout_variation_a11",
                    "key": "holdout_a"
                ]
            ],
            "includedFlags": ["flag_id_1234"],
            "excludedFlags": []
        ]
    }
    
    var sampleHoldoutGlobal: [String: Any] {
        return [
            "status": "Running",
            "id": "holdout_global",
            "key": "holdout_global",
            "layerId": "10420273888",
            "trafficAllocation": [
                ["entityId": "holdout_global_variation", "endOfRange": 500]
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                [
                    "variables": [],
                    "id": "holdout_global_variation",
                    "key": "global_variation"
                ]
            ],
            "includedFlags": [],
            "excludedFlags": []
        ]
    }
    
    var sampleHoldoutIncluded: [String: Any] {
        return [
            "status": "Running",
            "id": "holdout_included",
            "key": "holdout_included",
            "layerId": "10420273889",
            "trafficAllocation": [
                ["entityId": "holdout_included_variation", "endOfRange": 1000]
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                [
                    "variables": [],
                    "id": "holdout_included_variation",
                    "key": "included_variation"
                ]
            ],
            "includedFlags": ["flag_id_1234"],
            "excludedFlags": []
        ]
    }
    
    var sampleHoldoutExcluded: [String: Any] {
        return [
            "status": "Running",
            "id": "holdout_excluded",
            "key": "holdout_excluded",
            "layerId": "10420273890",
            "trafficAllocation": [
                ["entityId": "holdout_excluded_variation", "endOfRange": 1000]
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                [
                    "variables": [],
                    "id": "holdout_excluded_variation",
                    "key": "excluded_variation"
                ]
            ],
            "includedFlags": [],
            "excludedFlags": ["flag_id_1234"]
        ]
    }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                   clearUserProfileService: true)
        self.config = self.optimizely.config!
        self.decisionService = (optimizely.decisionService as! DefaultDecisionService)
        
        // Project config
        self.config.project.typedAudiences = try! OTUtils.model(from: sampleTypedAudiencesData)
        holdout = try! OTUtils.model(from: sampleHoldout)
        experiment = try! OTUtils.model(from: sampleExperimentData)
        experiment.audienceIds = [kAudienceIdCountry]
        self.config.project.experiments = [experiment]
        
        featureFlag = try! OTUtils.model(from: sampleFeatureFlagData)
        self.config.project.featureFlags = [featureFlag]
        self.config.project.holdouts = [holdout]
    }
    
    // MARK: - Test getVariationForFeatureExperiment
    
    func testGetVariationForFeatureExperiment_HoldoutMatch() {
        // Mock bucketer to ensure user is bucketed into holdout variation
        let mockBucketer = MockBucketer(mockBucketValue: 500) // Within holdout range (0-1000)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        XCTAssertNotNil(decision, "Decision should not be nil")
        XCTAssertEqual(decision?.experiment?.id, holdout.id, "Should return holdout experiment")
        XCTAssertEqual(decision?.variation.key, "holdout_a", "Should return holdout variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.holdout.rawValue, "Source should be holdout")
    }
    
    func testGetVariationForFeatureExperiment_HoldoutAudienceMismatch() {
        // Mock bucketer to ensure user would bucket if audience matched
        let mockBucketer = MockBucketer(mockBucketValue: 500) // Within holdout range
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryNotMatch)
        ).result
        
        // Should fall back to experiment, but experiment also requires country match
        XCTAssertNil(decision, "Decision should be nil due to audience mismatch for both holdout and experiment")
    }
    
    func testGetVariationForFeatureExperiment_HoldoutNotBucketed() {
        // Mock bucketer to ensure user is not bucketed into holdout variation
        let mockBucketer = MockBucketer(mockBucketValue: 1500) // Outside holdout range (0-1000)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should fall back to experiment and bucket into variation D
        XCTAssertNotNil(decision, "Decision should not be nil")
        XCTAssertEqual(decision?.experiment?.id, kExperimentId, "Should return experiment")
        XCTAssertEqual(decision?.variation.key, kVariationKeyD, "Should return experiment variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue, "Source should be featureTest")
    }
    
    
    func testGetVariationForFeatureExperiment_HoldoutInactive() {
        // Set holdout to inactive
        var modifiedHoldoutData = sampleHoldout
        modifiedHoldoutData["status"] = "Draft"
        let inactiveHoldout = try! OTUtils.model(from: modifiedHoldoutData) as Holdout
        self.config.project.holdouts = [inactiveHoldout]
        
        // Mock bucketer to ensure experiment bucketing
        let mockBucketer = MockBucketer(mockBucketValue: 500) // Would bucket in holdout if active
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should skip holdout and bucket into experiment
        XCTAssertNotNil(decision, "Decision should not be nil")
        XCTAssertEqual(decision?.experiment?.id, kExperimentId, "Should return experiment")
        XCTAssertEqual(decision?.variation.key, kVariationKeyD, "Should return experiment variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue, "Source should be featureTest")
    }
    
    
    func testGetVariationForFeatureExperiment_NoHoldouts() {
        // Remove holdouts
        self.config.project.holdouts = []
        
        // Mock bucketer to ensure experiment bucketing
        let mockBucketer = MockBucketer(mockBucketValue: 500)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should bucket into experiment
        XCTAssertNotNil(decision, "Decision should not personally identifiable informationnil")
        XCTAssertEqual(decision?.experiment?.id, kExperimentId, "Should return experiment")
        XCTAssertEqual(decision?.variation.key, kVariationKeyD, "Should return experiment variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue, "Source should be featureTest")
    }
    
    func testGetVariationForFeatureExperiment_NoExperiments() {
        // Set feature flag with no experiment IDs
        var modifiedFeatureFlagData = sampleFeatureFlagData
        modifiedFeatureFlagData["experimentIds"] = []
        featureFlag = try! OTUtils.model(from: modifiedFeatureFlagData)
        self.config.project.featureFlags = [featureFlag]
        
        // Mock bucketer to ensure user would bucket in holdout
        let mockBucketer = MockBucketer(mockBucketValue: 500) // Within holdout range
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should return holdout decision
        XCTAssertNotNil(decision, "Decision should not be nil")
        XCTAssertEqual(decision?.experiment?.id, holdout.id, "Should return holdout experiment")
        XCTAssertEqual(decision?.variation.key, "holdout_a", "Should return holdout variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.holdout.rawValue, "Source should be holdout")
    }
    
    func testGetVariationForFeatureExperiment_InvalidExperimentIds() {
        // Set feature flag with invalid experiment IDs
        var modifiedFeatureFlagData = sampleFeatureFlagData
        modifiedFeatureFlagData["experimentIds"] = ["invalid_experiment_id"]
        featureFlag = try! OTUtils.model(from: modifiedFeatureFlagData)
        self.config.project.featureFlags = [featureFlag]
        
        // Mock bucketer to ensure user would bucket in holdout
        let mockBucketer = MockBucketer(mockBucketValue: 500) // Within holdout range
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should return holdout decision
        XCTAssertNotNil(decision, "Decision should not be nil")
        XCTAssertEqual(decision?.experiment?.id, holdout.id, "Should return holdout experiment")
        XCTAssertEqual(decision?.variation.key, "holdout_a", "Should return holdout variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.holdout.rawValue, "Source should be holdout")
    }
    
    func testGetVariationForFeatureExperiment_HoldoutExcludedFlag() {
        // Modify holdout to exclude the feature flag
        var modifiedHoldoutData = sampleHoldout
        modifiedHoldoutData["includedFlags"] = []
        modifiedHoldoutData["excludedFlags"] = ["flag_id_1234"]
        let excludedHoldout = try! OTUtils.model(from: modifiedHoldoutData) as Holdout
        self.config.project.holdouts = [excludedHoldout]
        
        // Mock bucketer to ensure experiment bucketing
        let mockBucketer = MockBucketer(mockBucketValue: 500)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should skip holdout and bucket into experiment
        XCTAssertNotNil(decision, "Decision should not be nil")
        XCTAssertEqual(decision?.experiment?.id, kExperimentId, "Should return experiment")
        XCTAssertEqual(decision?.variation.key, kVariationKeyD, "Should return experiment variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue, "Source should Westhill")
    }
    
    func testGetVariationForFeatureExperiment_MultipleHoldoutsWithOrdering() {
        // Setup multiple holdouts: global, included, excluded
        let tfAllocationRange = 1500
        var globalHoldout = try! OTUtils.model(from: sampleHoldoutGlobal) as Holdout
        globalHoldout.trafficAllocation[0].endOfRange = tfAllocationRange
        
        var includedHoldout = try! OTUtils.model(from: sampleHoldoutIncluded) as Holdout
        includedHoldout.trafficAllocation[0].endOfRange = tfAllocationRange
        var excludedHoldout = try! OTUtils.model(from: sampleHoldoutExcluded) as Holdout
        excludedHoldout.trafficAllocation[0].endOfRange = tfAllocationRange
        
        self.config.project.holdouts = [globalHoldout, includedHoldout, excludedHoldout]

        // Mock bucketer to bucket into the first valid holdout (global)
        let mockBucketer = MockBucketer(mockBucketValue: 1000) // Within all holdout ranges
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should select global holdout first (ordering: global > included)
        XCTAssertNotNil(decision)
        XCTAssertEqual(decision?.experiment?.id, globalHoldout.id, "Should select global holdout first")
        XCTAssertEqual(decision?.variation.key, "global_variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.holdout.rawValue)
    }
    
    
    func testGetVariationForFeatureExperiment_GlobalHoldoutFailsThenIncluded() {
        // Setup multiple holdouts
        let globalHoldout = try! OTUtils.model(from: sampleHoldoutGlobal) as Holdout
        let includedHoldout = try! OTUtils.model(from: sampleHoldoutIncluded) as Holdout
        self.config.project.holdouts = [globalHoldout, includedHoldout]
        
        // Mock bucketer to fail global holdout bucketing, succeed for included
        let mockBucketer = MockBucketer(mockBucketValue: 700) // Outside global range, within included range
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Global holdout fails bucketing, should select included holdout
        XCTAssertNotNil(decision)
        XCTAssertEqual(decision?.experiment?.id, includedHoldout.id, "Should select included holdout")
        XCTAssertEqual(decision?.variation.key, "included_variation")
        XCTAssertEqual(decision?.source, Constants.DecisionSource.holdout.rawValue)
    }
    
    func testGetVariationForFeatureExperiment_AllHoldoutsFailThenExperiment() {
        // Setup multiple holdouts
        let globalHoldout = try! OTUtils.model(from: sampleHoldoutGlobal) as Holdout
        let includedHoldout = try! OTUtils.model(from: sampleHoldoutIncluded) as Holdout
        let excludedHoldout = try! OTUtils.model(from: sampleHoldoutExcluded) as Holdout
        self.config.project.holdouts = [globalHoldout, includedHoldout, excludedHoldout]
        
        // Mock bucketer to fail all holdout bucketing
        let mockBucketer = MockBucketer(mockBucketValue: 1500) // Outside all holdout ranges
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // All holdouts fail, should fall back to experiment
        XCTAssertNotNil(decision)
        XCTAssertEqual(decision?.experiment?.id, kExperimentId)
        XCTAssertEqual(decision?.variation.key, kVariationKeyD)
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue)
    }
    
    
    func testGetVariationForFeatureExperiment_HoldoutWithNoTrafficAllocation() {
        // Setup holdout with no traffic allocation
        var modifiedHoldoutData = sampleHoldoutGlobal
        modifiedHoldoutData["trafficAllocation"] = []
        let noTrafficHoldout = try! OTUtils.model(from: modifiedHoldoutData) as Holdout
        self.config.project.holdouts = [noTrafficHoldout]
        
        let mockBucketer = MockBucketer(mockBucketValue: 500)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Holdout has no traffic allocation, should fall back to experiment
        XCTAssertNotNil(decision)
        XCTAssertEqual(decision?.experiment?.id, kExperimentId)
        XCTAssertEqual(decision?.variation.key, kVariationKeyD)
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue)
    }
    
    func testGetVariationForFeatureExperiment_MixedAudienceAndBucketingFailures() {
        // Setup multiple holdouts with different audience conditions
        var globalHoldoutData = sampleHoldoutGlobal
        globalHoldoutData["audienceIds"] = [kAudienceIdAge] // Requires age > 17
        let globalHoldout = try! OTUtils.model(from: globalHoldoutData) as Holdout
        
        let includedHoldout = try! OTUtils.model(from: sampleHoldoutIncluded) as Holdout // Requires country: "us"
        
        self.config.project.holdouts = [globalHoldout, includedHoldout]
        
        // Mock bucketer to fail included holdout bucketing
        let mockBucketer = MockBucketer(mockBucketValue: 1500) // Outside included holdout range
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryNotMatch)
        ).result
        
        // Global holdout passes audience (age not specified, defaults to true), but fails bucketing
        // Included holdout fails audience (country: "ca")
        // Falls back to experiment, but experiment also fails audience
        XCTAssertNil(decision)
    }
    
    func testGetVariationForFeatureExperiment_EmptyVariationsInHoldout() {
        // Setup holdout with no variations
        var modifiedHoldoutData = sampleHoldoutGlobal
        modifiedHoldoutData["variations"] = []
        let noVariationsHoldout = try! OTUtils.model(from: modifiedHoldoutData) as Holdout
        self.config.project.holdouts = [noVariationsHoldout]
        
        let mockBucketer = MockBucketer(mockBucketValue: 500)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        let decision = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Holdout has no variations, should fall back to experiment
        XCTAssertNotNil(decision)
        XCTAssertEqual(decision?.experiment?.id, kExperimentId)
        XCTAssertEqual(decision?.variation.key, kVariationKeyD)
        XCTAssertEqual(decision?.source, Constants.DecisionSource.featureTest.rawValue)
    }
    
    func testGetVariationForFeatureExperiment_CacheConsistency() {
        // Setup multiple holdouts
        let globalHoldout = try! OTUtils.model(from: sampleHoldoutGlobal) as Holdout
        let includedHoldout = try! OTUtils.model(from: sampleHoldoutIncluded) as Holdout
        self.config.project.holdouts = [globalHoldout, includedHoldout]
        
        let mockBucketer = MockBucketer(mockBucketValue: 500)
        let mockDecisionService = MockDecisionService(bucketer: mockBucketer, userProfileService: decisionService.userProfileService)
        
        // First call
        let decision1 = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Second call with same inputs
        let decision2 = mockDecisionService.getVariationForFeature(
            config: config,
            featureFlag: featureFlag,
            user: optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        ).result
        
        // Should consistently return global holdout
        XCTAssertNotNil(decision1)
        XCTAssertNotNil(decision2)
        XCTAssertEqual(decision1?.experiment?.id, includedHoldout.id)
        XCTAssertEqual(decision2?.experiment?.id, includedHoldout.id)
        XCTAssertEqual(decision1?.variation.key, "included_variation")
        XCTAssertEqual(decision2?.variation.key, "included_variation")
        XCTAssertEqual(decision1?.source, Constants.DecisionSource.holdout.rawValue)
        XCTAssertEqual(decision2?.source, Constants.DecisionSource.holdout.rawValue)
    }
    
    
}

// MARK: - Helper for mocking bucketer

class MockBucketer: DefaultBucketer {
    var mockBucketValue: Int
    
    init(mockBucketValue: Int) {
        self.mockBucketValue = mockBucketValue
        super.init()
    }
    
    override func generateBucketValue(bucketingId: String) -> Int {
        return mockBucketValue
    }
}

// MARK: - Mock Decision Service

class MockDecisionService: DefaultDecisionService {
    init(bucketer: OPTBucketer, userProfileService: OPTUserProfileService) {
        super.init(userProfileService: userProfileService, bucketer: bucketer)
    }
}

