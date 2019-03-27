//
//  DecisionServiceTests_Others.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/5/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DecisionServiceTests_Others: XCTestCase {
    
    let kSdkKey = "12345"
    
    let kDatafileName = "test_data_10_experiments"
    let ktypeAudienceDatafileName = "typed_audience_datafile"
    let kUserId = "6369992312"
    let kUserNotInExperimentId = "6358043286"
    
    // whitelisting test constants
    let kWhitelistingTestDatafileName = "optimizely_7519590183"
    let kWhitelistedUserId = "whitelisted_user"
    let kWhitelistedExperiment = "whitelist_testing_experiment"
    let kWhitelistedVariation = "a"
    // whitelisting test constants from "test_data_10_experiments.json"
    let kWhitelistedUserId_test_data_10_experiments = "forced_variation_user"
    let kWhitelistedExperiment_test_data_10_experiments = "testExperiment6"
    let kWhitelistedVariation_test_data_10_experiments = "variation"
    
    // events with experiment and audiences
    let kExperimentWithTypedAudienceKey = "audience_combinations_experiment"
    let kExperimentWithTypedAudienceId = "3988293898"
    
    // events with experiment and audiences
    let kExperimentWithAudienceKey = "testExperimentWithFirefoxAudience"
    let kExperimentWithAudienceId = "6383811281"
    let kExperimentWithAudienceVariationId = "6333082303"
    let kExperimentWithAudienceVariationKey = "control"
    
    // experiment not running parameters
    let kExperimentNotRunningKey = "testExperimentNotRunning"
    let kExperimentNotRunningId = "6367444440"
    
    let kAttributeKey = "browser_type"
    let kAttributeValue = "firefox"
    let kAttributeValueChrome = "chrome"
    let kAttributeKeyBrowserBuildNumberInt = "browser_buildnumber"
    let kAttributeKeyBrowserVersionNumberInt = "browser_version"
    let kAttributeKeyIsBetaVersionBool = "browser_isbeta"
    
    // experiment with no audience
    let kExperimentNoAudienceKey = "testExperiment4"
    let kExperimentNoAudienceId = "6358043286"
    let kExperimentNoAudienceVariationId = "6373141147"
    let kExperimentNoAudienceVariationKey = "control"
    
    // experiment & feature flag with multiple variables
    let kExperimentMultiVariateKey = "testExperimentMultivariate"
    let kExperimentMultiVariateVariationId = "6373141147"
    let kFeatureFlagMultiVariateKey = "multiVariateFeature"
    
    // experiment & feature flag with mutex group
    let kExperimentMutexGroupKey = "mutex_exp1"
    let kFeatureFlagMutexGroupKey = "booleanFeature"
    
    // feature flag with no experiment and rollout
    let kFeatureFlagEmptyKey = "emptyFeature"
    
    // feature flag with invalid experiment and rollout
    let kFeatureFlagInvalidGroupKey = "invalidGroupIdFeature"
    let kFeatureFlagInvalidExperimentKey = "invalidExperimentIdFeature"
    let kFeatureFlagInvalidRolloutKey = "invalidRolloutIdFeature"
    
    // feature flag with rollout id having no rule
    let kFeatureFlagEmptyRuleRolloutKey = "stringSingleVariableFeature"
    
    // feature flag with rollout id having no bucketed rule
    let kFeatureFlagNoBucketedRuleRolloutKey = "booleanSingleVariableFeature"
    
    class TestDecisionService: OPTDecisionService {
        func getVariation(config:ProjectConfig, userId: String, experiment: Experiment, attributes: OptimizelyAttributes) -> Variation? {
            return nil
        }
        
        func getVariationForFeature(config:ProjectConfig, featureFlag: FeatureFlag, userId: String, attributes: OptimizelyAttributes) -> (experiment: Experiment?, variation: Variation?)? {
            return nil
        }
    }
    
    var optimizely: OptimizelyManager!
    
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    
    var attributes: [String: Any]!
    var userProfileWithFirefoxAudience: [String: Any]!
    
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: kDatafileName,
                                                   clearUserProfileService: true)!
        self.config = self.optimizely.config
        self.decisionService = (optimizely.decisionService as! DefaultDecisionService)
        
        self.attributes = [kAttributeKey : kAttributeValue]
        
        decisionService.saveProfile(userId: kUserId,
                                    experimentId: kExperimentWithAudienceId,
                                    variationId: kExperimentWithAudienceVariationId)
    }
    
    // MARK: - Validate Preconditions
    
    // experiment is running, user is in experiment
    func testValidatePreconditions() {
        let experiment = self.config.getExperiment(key: kExperimentWithAudienceKey)!
        do {
            let isValid = try self.decisionService.isInExperiment(config: config,
                                                                  experiment: experiment,
                                                                  userId: self.kUserId,
                                                                  attributes: self.attributes)
            XCTAssert(isValid, "Experiment running with user in experiment should pass validation.")
        } catch {
            XCTAssert(false, "\(error)")
        }
    }
    
    // experiment is not running, validator should return false
    func testValidatePreconditionsExperimentNotRunning() {
        let experiment = self.config.getExperiment(key: kExperimentNotRunningKey)!
        XCTAssertFalse(experiment.isActivated)
    }
    
    // experiment is running, user is in experiment, bad attributes
    func testValidatePreconditionsBadAttributes() {
        let badAttributes = ["badAttributeKey": "12345"]
        
        let experiment = self.config.getExperiment(key: kExperimentWithAudienceKey)!
        do {
            _ = try self.decisionService.isInExperiment(config: config,
                                                        experiment: experiment,
                                                        userId: self.kUserId,
                                                        attributes: badAttributes)
            XCTAssert(false)
        } catch {
            XCTAssert(true, "expect null (throw) when no matching attribute provided")
        }
    }
    
    func testValidatePreconditionsAllowsWhiteListedUserToOverrideAudienceEvaluation() {
        optimizely = OTUtils.createOptimizely(datafileName: kWhitelistingTestDatafileName, clearUserProfileService: true)!
        
        // user should not be bucketed if userId is not a match and they do not pass attributes
        var variation = try? optimizely.getVariation(experimentKey: kWhitelistedExperiment,
                                                     userId: kUserId,
                                                     attributes: self.attributes)
        XCTAssertNil(variation)
        
        // user should be bucketed if userID is whitelisted
        variation = try? optimizely.getVariation(experimentKey: kWhitelistedExperiment,
                                                 userId: kWhitelistedUserId,
                                                 attributes: self.attributes)
        XCTAssert(variation!.key == kWhitelistedVariation);
    }
    
    func testUserInExperimentWithEmptyAudienceIdAndConditions() {
        optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName, clearUserProfileService: true)!
        var experiment = optimizely.config!.getExperiment(key: kExperimentWithTypedAudienceKey)!
        
        experiment.audienceIds = []
        experiment.audienceConditions = ConditionHolder.array([])
        
        let isValid = try? (optimizely.decisionService as! DefaultDecisionService).isInExperiment(config: config,
                                                                                                  experiment: experiment,
                                                                                                  userId: kUserId,
                                                                                                  attributes: self.attributes)
        XCTAssert(isValid!)
    }
    
    func testUserInExperimentWithValidAudienceIdAndEmptyAudienceConditions() {
        optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName, clearUserProfileService: true)!
        var experiment = optimizely.config!.getExperiment(key: kExperimentWithTypedAudienceKey)!
        
        experiment.audienceConditions = ConditionHolder.array([])
        let isValid = try! (optimizely.decisionService as! DefaultDecisionService).isInExperiment(config: config,
                                                                                                  experiment: experiment,
                                                                                                  userId: kUserId,
                                                                                                  attributes: self.attributes)
        XCTAssert(isValid)
    }
    
    func testUserInExperimentWithEmptyAudienceIdAndNilAudienceConditions()  {
        optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName, clearUserProfileService: true)!
        var experiment = optimizely.config!.getExperiment(key: kExperimentWithTypedAudienceKey)!
        
        experiment.audienceIds = []
        experiment.audienceConditions = nil
        
        let isValid = try? (optimizely.decisionService as! DefaultDecisionService).isInExperiment(config: config,
                                                                                                  experiment: experiment,
                                                                                                  userId: kUserId,
                                                                                                  attributes: self.attributes)
        XCTAssert(isValid!)
    }
    
    // MARK: - getVariation
    
    // if the experiment is not running should return nil for getVariation
    func testGetVariationExperimentNotRunning() {
        let experimentNotRunning = self.config.getExperiment(key: kExperimentNotRunningKey)!
        let variation = self.decisionService.getVariation(config: config,
                                                          userId: kUserId,
                                                          experiment: experimentNotRunning,
                                                          attributes: [:])
        XCTAssertNil(variation)
    }
    
    // whitelisted user should return the whitelisted variation for getVariation
    func testGetVariationWithWhitelistedVariation() {
        let experimentWhitelisted = self.config.getExperiment(key: kWhitelistedExperiment_test_data_10_experiments)!
        let variation = self.decisionService.getVariation(config: config,
                                                          userId: kWhitelistedUserId_test_data_10_experiments,
                                                          experiment: experimentWhitelisted,
                                                          attributes: [:])
        XCTAssert(variation!.key == kWhitelistedVariation_test_data_10_experiments)
    }
    
    // whitelisted user having invalid whitelisted variation should return bucketed variation for getVariation
    func testGetVariationWithInvalidWhitelistedVariation() {
        let experimentWhitelisted = self.config.getExperiment(key: "testExperiment5")!
        let expectedVariation = experimentWhitelisted.variations[0]
        
        let variation = self.decisionService.getVariation(config: config,
                                                          userId: kWhitelistedUserId_test_data_10_experiments,
                                                          experiment: experimentWhitelisted,
                                                          attributes: [:])
        XCTAssert(variation!.key == expectedVariation.key)
    }
    
    // if the experiment is running and the user is not whitelisted,
    // lookup should be called to get the stored variation
    func testGetVariationNoAudience() {
        
        // wrong test name ?
        
        let experiment = self.config.getExperiment(key: kExperimentWithAudienceKey)!
        let variation = self.decisionService.getVariation(config: config,
                                                          userId: kUserId,
                                                          experiment: experiment,
                                                          attributes: self.attributes)
        XCTAssertNotNil(variation)
    }
    
}
