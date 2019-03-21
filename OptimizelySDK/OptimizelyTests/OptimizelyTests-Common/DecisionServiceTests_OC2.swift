//
//  DecisionServiceTests-OC2.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/5/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DecisionServiceTests_OC2: XCTestCase {

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
        func initialize(config: ProjectConfig, bucketer: OPTBucketer, userProfileService: OPTUserProfileService) {
        }
        
        func getVariation(userId: String, experiment: Experiment, attributes: OptimizelyAttributes) -> Variation? {
            return nil
        }
        
        func getVariationForFeature(featureFlag: FeatureFlag, userId: String, attributes: OptimizelyAttributes) -> (experiment: Experiment?, variation: Variation?)? {
            return nil
        }
    }
    
    var optimizely: OptimizelyManager!
    var optimizelyTypedAudience: OptimizelyManager!
    
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    var bucketer: OPTBucketer!
    
    var configTypedAudience: ProjectConfig!
    var decisionServiceTypedAudience: DefaultDecisionService!
    var bucketerTypedAudience: OPTBucketer!
    
    var attributes: [String: Any]!
    var userProfileWithFirefoxAudience: [String: Any]!


    override func setUp() {
        super.setUp()
        
        let userProfileService = DefaultUserProfileService()
        let datafile = OTUtils.loadJSONDatafile(kDatafileName)!
        optimizely = OptimizelyManager(sdkKey: kSdkKey,
                                       userProfileService: userProfileService)
        try! optimizely.initializeSDK(datafile: datafile)
        
        let typedAudienceDatafile = OTUtils.loadJSONDatafile(ktypeAudienceDatafileName)!
        optimizelyTypedAudience = OptimizelyManager(sdkKey: kSdkKey)
        try! optimizelyTypedAudience.initializeSDK(datafile: typedAudienceDatafile)

        self.config = self.optimizely.config
        self.configTypedAudience = self.optimizelyTypedAudience.config
        
        self.bucketer = optimizely.bucketer
        self.decisionService = (optimizely.decisionService as! DefaultDecisionService)
        
        self.bucketerTypedAudience = optimizelyTypedAudience.bucketer
        self.decisionServiceTypedAudience = (optimizelyTypedAudience.decisionService as! DefaultDecisionService)
        
        self.attributes = [kAttributeKey : kAttributeValue]
        
        decisionService.saveProfile(userId: kUserId,
                                    experimentId: kExperimentWithAudienceId,
                                    variationId: kExperimentWithAudienceVariationId)
        self.userProfileWithFirefoxAudience = userProfileService.lookup(userId: kUserId)
    }

    // MARK: - Validate Preconditions

    // experiment is running, user is in experiment
    func testValidatePreconditions() {
        let experiment = self.config.getExperiment(key: kExperimentWithAudienceKey)!
        do {
            let isValid = try self.decisionService.isInExperiment(experiment: experiment, userId: self.kUserId, attributes: self.attributes)
            XCTAssert(isValid, "Experiment running with user in experiment should pass validation.")
        } catch {
            XCTAssert(false, "\(error)")
        }
    }
//
//    // experiment is not running, validator should return false
//    - (void)testValidatePreconditionsExperimentNotRunning
//    {
//    BOOL isActive = [self.decisionService isExperimentActive:self.config
//    experimentKey:kExperimentNotRunningKey];
//    NSAssert(isActive == false, "Experiment not running with user in experiment should fail validation.");
//    }
//
//    // experiment is running, user is in experiment, bad attributes
//    - (void)testValidatePreconditionsBadAttributes
//    {
//    NSDictionary *badAttributes = @{"badAttributeKey":"12345"};
//    OPTLYExperiment *experiment = [self.config getExperimentForKey:kExperimentWithAudienceKey];
//    BOOL isValid = [self.decisionService userPassesTargeting:self.config
//    experiment:experiment
//    userId:kUserId
//    attributes:badAttributes];
//    NSAssert(isValid == false, "Experiment running with user in experiment, but with bad attributes should fail validation.");
//    }
//
//    - (void)testValidatePreconditionsAllowsWhiteListedUserToOverrideAudienceEvaluation {
//    NSData *whitelistingDatafile = [OPTLYTestHelper loadJSONDatafileIntoDataObject:kWhitelistingTestDatafileName];
//    Optimizely *optimizely = [[Optimizely alloc] initWithBuilder:[OPTLYBuilder builderWithBlock:^(OPTLYBuilder * _Nullable builder) {
//    builder.datafile = whitelistingDatafile;
//    }]];
//
//    // user should not be bucketed if userId is not a match and they do not pass attributes
//    OPTLYVariation *variation = [optimizely variation:kWhitelistedExperiment
//    userId:kUserId
//    attributes:self.attributes];
//    XCTAssertNil(variation);
//
//    // user should be bucketed if userID is whitelisted
//    variation = [optimizely variation:kWhitelistedExperiment
//    userId:kWhitelistedUserId
//    attributes:self.attributes];
//    XCTAssertNotNil(variation);
//    XCTAssertEqualObjects(variation.variationKey, kWhitelistedVariation);
//    }
//
//    - (void)testUserInExperimentWithEmptyAudienceIdAndConditions
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    experiment.audienceIds = @[];
//    experiment.audienceConditions = (NSArray<OPTLYCondition> *)@[];
//    BOOL isValid = [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertTrue(isValid);
//    }
//
//    - (void)testUserInExperimentWithValidAudienceIdAndEmptyAudienceConditions
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    experiment.audienceConditions = (NSArray<OPTLYCondition> *)@[];
//    BOOL isValid = [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertTrue(isValid);
//    }
//
//    - (void)testUserInExperimentWithEmptyAudienceIdAndNilAudienceConditions
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    experiment.audienceIds = @[];
//    experiment.audienceConditions = nil;
//    BOOL isValid = [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertTrue(isValid);
//    }
//
//    - (void)testIsUserInExperimentUsesNonNullAudienceConditionsWhenAudienceIdsAlsoAvailable
//    {
//    NSDictionary *tmpAttributes = @{"favorite_ice_cream":"strawberry", "house":"Slytherin"};
//    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    XCTAssertTrue([self.typedAudienceDecisionService shouldEvaluateUsingAudienceConditions:experiment]);
//
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:tmpAttributes];
//    NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorEvaluationStartedForExperiment, experiment.experimentKey, [experiment getAudienceConditionsString]];
//    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//
//    OPTLYAudience *audience = [self.optimizelyTypedAudience.config getAudienceForId:"3468206642"];
//    NSString *conditionString = [audience getConditionsString];
//    logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorEvaluationStartedWithConditions, audience.audienceName, conditionString];
//    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//
//    logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorExperimentEvaluationCompletedWithResult, experiment.experimentKey, "TRUE"];
//    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelInfo]);
//
//    tmpAttributes = @{"favorite_ice_cream1":"pineapple", "house":"test"};
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:tmpAttributes];
//    logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorExperimentEvaluationCompletedWithResult, experiment.experimentKey, "FALSE"];
//    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelInfo]);
//
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorExperimentEvaluationCompletedWithResult, experiment.experimentKey, "FALSE"];
//    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelInfo]);
//
//
//    [loggerMock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentUsesAudienceIdsWhenAudienceConditionsNull
//    {
//    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizelyTypedAudience.logger);
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:"typed_audience_experiment"];
//    experiment.audienceConditions = nil;
//    XCTAssertFalse([self.typedAudienceDecisionService shouldEvaluateUsingAudienceConditions:experiment]);
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//
//    OPTLYAudience *audience = [self.typedAudienceConfig getAudienceForId:"3468206642"];
//    NSString *conditionString = [audience getConditionsString];
//    NSString *logMessage = [NSString stringWithFormat:OPTLYLoggerMessagesAudienceEvaluatorEvaluationStartedWithConditions, audience.audienceName, conditionString];
//    OCMVerify([loggerMock logMessage:logMessage withLevel:OptimizelyLogLevelDebug]);
//
//    [loggerMock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentReturnsTrueWhenBothAudienceConditionsAndAudienceIdsNull
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    experiment.audienceConditions = nil;
//    experiment.audienceIds = @[];
//    BOOL isValid = [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertTrue(isValid);
//    }
//
//    - (void)testIsUserInExperimentEvaluatesAudienceWhenAttributesEmpty
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    id mock = [OCMockObject partialMockForObject:experiment];
//    [[mock expect] evaluateConditionsWithAttributes:[OCMArg any] projectConfig:[OCMArg any]];
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:@{}];
//    XCTAssertTrue([mock verify]);
//    [mock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentEvaluatesAudienceWhenAttributesEmptyAndAudienceConditionsNil
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    experiment.audienceConditions = nil;
//    OPTLYAudience *audience = [self.typedAudienceConfig getAudienceForId:experiment.audienceIds[0]];
//    id mock = [OCMockObject partialMockForObject:audience];
//    [[mock expect] evaluateConditionsWithAttributes:[OCMArg any] projectConfig:[OCMArg any]];
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:@{}];
//    XCTAssertTrue([mock verify]);
//    [mock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentEvaluatesAudienceWhenAttributesNil
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    id mock = [OCMockObject partialMockForObject:experiment];
//    [[mock expect] evaluateConditionsWithAttributes:[OCMArg any] projectConfig:[OCMArg any]];
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:nil];
//    XCTAssertTrue([mock verify]);
//    [mock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentEvaluatesAudienceWhenAttributesNilAndAudienceConditionsNil
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    experiment.audienceConditions = nil;
//    OPTLYAudience *audience = [self.typedAudienceConfig getAudienceForId:experiment.audienceIds[0]];
//    id mock = [OCMockObject partialMockForObject:audience];
//    [[mock expect] evaluateConditionsWithAttributes:[OCMArg any] projectConfig:[OCMArg any]];
//    [self.typedAudienceDecisionService isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:nil];
//    XCTAssertTrue([mock verify]);
//    [mock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentReturnsFalseWhenEvaluatorReturnsFalseOrNull
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    id decisionServiceMock = OCMPartialMock(self.typedAudienceDecisionService);
//    OCMStub([decisionServiceMock evaluateAudienceConditionsForExperiment:[OCMArg any] config:[OCMArg any] attributes:[OCMArg any]]).andReturn(false);
//    BOOL isValid = [decisionServiceMock isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertFalse(isValid);
//    [decisionServiceMock stopMocking];
//
//    decisionServiceMock = OCMPartialMock(self.typedAudienceDecisionService);
//    experiment.audienceConditions = nil;
//    OCMStub([decisionServiceMock evaluateAudienceIdsForExperiment:[OCMArg any] config:[OCMArg any] attributes:[OCMArg any]]).andReturn(false);
//    isValid = [decisionServiceMock isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertFalse(isValid);
//    [decisionServiceMock stopMocking];
//
//    decisionServiceMock = OCMPartialMock(self.typedAudienceDecisionService);
//    OCMStub([decisionServiceMock evaluateAudienceWithId:[OCMArg any] config:[OCMArg any] attributes:[OCMArg any]]).andReturn(nil);
//    isValid = [decisionServiceMock isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertFalse(isValid);
//    [decisionServiceMock stopMocking];
//    }
//
//    - (void)testIsUserInExperimentReturnsTrueWhenEvaluatorReturnsTrue
//    {
//    OPTLYExperiment *experiment = [self.typedAudienceConfig getExperimentForKey:kExperimentWithTypedAudienceKey];
//    id decisionServiceMock = OCMPartialMock(self.typedAudienceDecisionService);
//    OCMStub([decisionServiceMock evaluateAudienceConditionsForExperiment:[OCMArg any] config:[OCMArg any] attributes:[OCMArg any]]).andReturn(true);
//    BOOL isValid = [decisionServiceMock isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertTrue(isValid);
//    [decisionServiceMock stopMocking];
//
//    decisionServiceMock = OCMPartialMock(self.typedAudienceDecisionService);
//    experiment.audienceConditions = nil;
//    OCMStub([decisionServiceMock evaluateAudienceIdsForExperiment:[OCMArg any] config:[OCMArg any] attributes:[OCMArg any]]).andReturn(true);
//    isValid = [decisionServiceMock isUserInExperiment:self.typedAudienceConfig experiment:experiment attributes:self.attributes];
//    XCTAssertTrue(isValid);
//    [decisionServiceMock stopMocking];
//    }
//
//    #pragma mark - getVariation
//
//    // if the experiment is not running should return nil for getVariation
//    - (void)testGetVariationExperimentNotRunning
//    {
//    OPTLYExperiment *experimentNotRunning = [self.config getExperimentForKey:kExperimentNotRunningKey];
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId experiment:experimentNotRunning attributes:nil];
//    XCTAssertNil(variation, "Get variation on an experiment not running should return nil: %", variation);
//    }
//
//    // whitelisted user should return the whitelisted variation for getVariation
//    - (void)testGetVariationWithWhitelistedVariation
//    {
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:kWhitelistedExperiment_test_data_10_experiments];
//    OPTLYVariation *variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssert([variation.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should return: %@, but instead returns: %@.", kWhitelistedVariation_test_data_10_experiments, variation.variationKey);
//    }
//
//    // whitelisted user having invalid whitelisted variation should return bucketed variation for getVariation
//    - (void)testGetVariationWithInvalidWhitelistedVariation {
//
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:"testExperiment5"];
//    OPTLYVariation *expectedVariation = experimentWhitelisted.variations[0];
//
//    id bucketerMock = OCMPartialMock(self.bucketer);
//    OCMStub([bucketerMock bucketExperiment:experimentWhitelisted
//    withBucketingId:kWhitelistedUserId_test_data_10_experiments]).andReturn(expectedVariation);
//
//    self.decisionService = [[OPTLYDecisionService alloc] initWithProjectConfig:self.config
//    bucketer:bucketerMock];
//
//    OPTLYVariation *variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssert([variation.variationKey isEqualToString:expectedVariation.variationKey], "Get variation on an invalid whitelisted variation should return: %@, but instead returns: %@.", expectedVariation.variationKey, variation.variationKey);
//    OCMVerify([bucketerMock bucketExperiment:experimentWhitelisted withBucketingId:kWhitelistedUserId_test_data_10_experiments]);
//    [bucketerMock stopMocking];
//    }
//
//
//    // invalid audience should return nil for getVariation
//    - (void)testGetVariationWithInvalidAudience
//    {
//    OPTLYExperiment *experimentWithAudience = [self.config getExperimentForKey:kExperimentWithAudienceKey];
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId
//    experiment:experimentWithAudience
//    attributes:nil];
//    XCTAssertNil(variation, "Get variation with an invalid audience should return nil: %", variation);
//    }
//
//    // invalid audience should return nil for getVariation overridden by call to setForcedVariation
//    - (void)testGetVariationWithInvalidAudienceOverriddenBySetForcedVariation
//    {
//    [self.optimizely setForcedVariation:kExperimentWithAudienceKey
//    userId:kUserId
//    variationKey:kExperimentNoAudienceVariationKey];
//    OPTLYExperiment *experimentWithAudience = [self.config getExperimentForKey:kExperimentWithAudienceKey];
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId
//    experiment:experimentWithAudience
//    attributes:nil];
//    XCTAssertNotNil(variation, "Get variation with an invalid audience  should be overridden by setForcedVariation");
//    XCTAssertEqualObjects(variation.variationKey, kExperimentNoAudienceVariationKey, "Should be the forced varation %@ .", kExperimentNoAudienceVariationKey);
//    }
//
//    // if the experiment is running and the user is not whitelisted,
//    // lookup should be called to get the stored variation
//    - (void)testGetVariationNoAudience
//    {
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    id userProfileServiceMock = OCMPartialMock((NSObject *)self.config.userProfileService);
//
//    OPTLYExperiment *experiment = [self.config getExperimentForKey:kExperimentWithAudienceKey];
//
//    [[[userProfileServiceMock stub] andReturn:self.userProfileWithFirefoxAudience] lookup:[OCMArg isNotNil]];
//
//    OPTLYVariation *storedVariation = [decisionServiceMock getVariation:kUserId experiment:experiment attributes:self.attributes];
//
//    OCMVerify([userProfileServiceMock lookup:[OCMArg isNotNil]]);
//
//    XCTAssertNotNil(storedVariation, "Stored variation should not be nil.");
//
//    [decisionServiceMock stopMocking];
//    [userProfileServiceMock stopMocking];
//    }
//
//    // if bucketingId attribute is not a string. Defaulted to userId
//    - (void)testGetVariationWithInvalidBucketingId {
//    NSDictionary *attributes = @{OptimizelyBucketId: @YES};
//    OPTLYExperiment *experiment = [self.config getExperimentForKey:kExperimentNoAudienceKey];
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId experiment:experiment attributes:attributes];
//    XCTAssertNotNil(variation, "Get variation with invalid bucketing Id should use userId for bucketing.");
//    XCTAssertEqualObjects(variation.variationKey, kExperimentWithAudienceVariationKey,
//    "Get variation with invalid bucketing Id should return: %@, but instead returns: %@.",
//    kExperimentWithAudienceVariationKey, variation.variationKey);
//    }
//
//    - (void)testGetVariationWithEmptyBucketingId {
//    OPTLYExperiment *experiment = [self.config getExperimentForKey:kExperimentNoAudienceKey];
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId experiment:experiment attributes:nil];
//
//    XCTAssertNotNil(variation, "Get variation");
//
//    NSDictionary *attributes = @{OptimizelyBucketId: ""};
//    OPTLYVariation *variationWithEmptyBucketingId = [self.decisionService getVariation:kUserId experiment:experiment attributes:attributes];
//
//    XCTAssertNotEqual(variation.variationKey,variationWithEmptyBucketingId.variationKey);
//    }
//
//    - (void)testGetVariationAcceptAllTypeAttributes {
//
//    OPTLYExperiment *experiment = [self.config getExperimentForKey:kExperimentNoAudienceKey];
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId experiment:experiment attributes:@{kAttributeKey: kAttributeValue,
//    kAttributeKeyBrowserBuildNumberInt: @(10), kAttributeKeyBrowserVersionNumberInt: @(0.23), kAttributeKeyIsBetaVersionBool: @(YES)}];
//
//    XCTAssertNotNil(variation, "Get variation with supported types should return valid variation.");
//    XCTAssertEqualObjects(variation.variationKey, kExperimentWithAudienceVariationKey);
//    }
//
//    #pragma mark - setForcedVariation
//
//    // whitelisted user should return the whitelisted variation for getVariation overridden by call to setForcedVariation
//    - (void)testGetVariationWithWhitelistedVariationOverriddenBySetForcedVariation
//    {
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:kExperimentNoAudienceVariationKey];
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:kWhitelistedExperiment_test_data_10_experiments];
//    OPTLYVariation *variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssertFalse([variation.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should be overridden by setForcedVariation");
//    XCTAssertEqualObjects(variation.variationKey, kExperimentNoAudienceVariationKey, "Should be the forced varation %@ .", kExperimentNoAudienceVariationKey);
//    }
//
//    - (void)testSetForcedVariationFollowedByGetForcedVariation
//    {
//    // Call setForcedVariation:userId:variationKey:
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:kExperimentNoAudienceVariationKey];
//    // Confirm getForcedVariation:userId: returns forced variation.
//    OPTLYVariation *variation1 = [self.config getForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments];
//    XCTAssertFalse([variation1.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should be overridden by setForcedVariation");
//    XCTAssertEqualObjects(variation1.variationKey, kExperimentNoAudienceVariationKey, "Should be the forced varation %@ .", kExperimentNoAudienceVariationKey);
//    // Confirm decisionService's getVariation:experiment:attributes: finds forced variation.
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:kWhitelistedExperiment_test_data_10_experiments];
//    OPTLYVariation *variation2 = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssertFalse([variation2.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should be overridden by setForcedVariation");
//    XCTAssertEqualObjects(variation2.variationKey, kExperimentNoAudienceVariationKey, "Should be the forced varation %@ .", kExperimentNoAudienceVariationKey);
//    // The two answers should be the same.
//    XCTAssertEqualObjects(variation1.variationKey, variation1.variationKey, "Should be the same forced varation %@ .", kExperimentNoAudienceVariationKey);
//    }
//
//    // whitelisted user should return the whitelisted variation for getVariation after setForcedVariation is cleared
//    - (void)testGetVariationWithWhitelistedVariationAfterClearingSetForcedVariation
//    {
//    // Set a forced variation
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:kExperimentNoAudienceVariationKey];
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:kWhitelistedExperiment_test_data_10_experiments];
//    OPTLYVariation *variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssertFalse([variation.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should be overridden by setForcedVariation");
//    XCTAssertEqualObjects(variation.variationKey, kExperimentNoAudienceVariationKey, "Should be the forced varation %@ .", kExperimentNoAudienceVariationKey);
//    // Clear the forced variation
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:nil];
//    // Confirm return to variation expected in absence of a forced variation.
//    variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssert([variation.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should return: %@, but instead returns: %@.", kWhitelistedVariation_test_data_10_experiments, variation.variationKey);
//    }
//
//    // whitelisted user should return the whitelisted variation for getVariation overridden by call to setForcedVariation twice
//    - (void)testGetVariationWithWhitelistedVariationOverriddenBySetForcedVariationTwice
//    {
//    // First call to setForcedVariation:userId:variationKey:
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:kExperimentNoAudienceVariationKey];
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:kWhitelistedExperiment_test_data_10_experiments];
//    OPTLYVariation *variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssertFalse([variation.variationKey isEqualToString:kWhitelistedVariation_test_data_10_experiments], "Get variation on a whitelisted variation should be overridden by setForcedVariation");
//    XCTAssertEqualObjects(variation.variationKey, kExperimentNoAudienceVariationKey, "Should be the forced varation %@ .", kExperimentNoAudienceVariationKey);
//    // Second call to setForcedVariation:userId:variationKey: to a different forced variation
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:kWhitelistedVariation_test_data_10_experiments];
//    variation = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    XCTAssertFalse([variation.variationKey isEqualToString:kExperimentNoAudienceVariationKey], "Variation should agree with second call to setForcedVariation");
//    XCTAssertEqualObjects(variation.variationKey, kWhitelistedVariation_test_data_10_experiments, "Should be the forced varation %@ .", kWhitelistedVariation_test_data_10_experiments);
//    }
//
//    // two different users experience two different setForcedVariation's in the same experiment differently
//    - (void)testGetVariationWithWhitelistedVariationOverriddenBySetForcedVariationForTwoDifferentUsers
//    {
//    // First call to setForcedVariation:userId:variationKey:
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId
//    variationKey:kExperimentNoAudienceVariationKey];
//    // Second call to setForcedVariation:userId:variationKey: to a different variation
//    [self.optimizely setForcedVariation:kWhitelistedExperiment_test_data_10_experiments
//    userId:kWhitelistedUserId_test_data_10_experiments
//    variationKey:kWhitelistedVariation_test_data_10_experiments];
//    // Query variation's experienced by the two different users
//    OPTLYExperiment *experimentWhitelisted = [self.config getExperimentForKey:kWhitelistedExperiment_test_data_10_experiments];
//    OPTLYVariation *variation1 = [self.decisionService getVariation:kWhitelistedUserId
//    experiment:experimentWhitelisted
//    attributes:nil];
//    OPTLYVariation *variation2 = [self.decisionService getVariation:kWhitelistedUserId_test_data_10_experiments
//    experiment:experimentWhitelisted
//    attributes:nil];
//    // Confirm the two variations are different and they agree with predictions
//    XCTAssertNotEqualObjects(variation1.variationKey,variation2.variationKey,"Expecting two different forced variations for the two different users in this experiment");
//    XCTAssertEqualObjects(variation1.variationKey,kExperimentNoAudienceVariationKey,"Should have been variation predicted for the first user");
//    XCTAssertEqualObjects(variation2.variationKey,kWhitelistedVariation_test_data_10_experiments,"Should have been variation predicted for the second user");
//    }
//
//    // if the experiment is not running should return nil for getVariation even after setForcedVariation
//    - (void)testSetForcedVariationExperimentNotRunning
//    {
//    OPTLYExperiment *experimentNotRunning = [self.config getExperimentForKey:kExperimentNotRunningKey];
//    XCTAssert([self.optimizely setForcedVariation:kExperimentNotRunningKey
//    userId:kUserId
//    variationKey:kExperimentNoAudienceVariationKey]);
//    OPTLYVariation *variation = [self.decisionService getVariation:kUserId experiment:experimentNotRunning attributes:nil];
//    XCTAssertNil(variation, "Set forced variation on an experiment not running should return nil: %", variation);
//    }
//
//    // setForcedVariation called on invalid experimentKey (empty string)
//    - (void)testSetForcedVariationCalledOnInvalidExperimentKey1
//    {
//    NSString *invalidExperimentKey = ""
//    XCTAssertFalse([self.optimizely setForcedVariation:invalidExperimentKey
//    userId:kUserId
//    variationKey:kExperimentNoAudienceVariationKey]);
//    }
//
//    // setForcedVariation called on invalid experimentKey (non-existent experiment)
//    - (void)testSetForcedVariationCalledOnInvalidExperimentKey2
//    {
//    NSString *invalidExperimentKey = "invalid_experiment_key_3817"
//    XCTAssertFalse([self.optimizely setForcedVariation:invalidExperimentKey
//    userId:kUserId
//    variationKey:kExperimentNoAudienceVariationKey]);
//    }
//
//    // setForcedVariation called on invalid variationKey (empty string)
//    - (void)testSetForcedVariationCalledOnInvalidVariationKey1
//    {
//    NSString *invalidVariationKey = ""
//    XCTAssertFalse([self.optimizely setForcedVariation:kExperimentNotRunningKey
//    userId:kUserId
//    variationKey:invalidVariationKey]);
//    }
//
//    // setForcedVariation called on invalid variationKey (non-existent variation)
//    - (void)testSetForcedVariationCalledOnInvalidVariationKey2
//    {
//    NSString *invalidVariationKey = "invalid_variation_key_3817"
//    XCTAssertFalse([self.optimizely setForcedVariation:kExperimentNotRunningKey
//    userId:kUserId
//    variationKey:invalidVariationKey]);
//    }
//
//    // setForcedVariation called on invalid userId (empty string)
//    - (void)testSetForcedVariationCalledOnInvalidUserId
//    {
//    NSString *invalidUserId = ""
//    XCTAssertTrue([self.optimizely setForcedVariation:kExperimentNotRunningKey
//    userId:invalidUserId
//    variationKey:kExperimentNoAudienceVariationKey]);
//    }
//
//    #pragma mark - saveUserProfile
//
//    // for decision service saves, the user profile service save should be called with the expected user profile
//    - (void)testSaveVariation
//    {
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    id userProfileServiceMock = OCMPartialMock((NSObject *)self.config.userProfileService);
//
//    NSDictionary *variationDict = @{ OPTLYDatafileKeysVariationId  : kExperimentWithAudienceVariationId,
//    OPTLYDatafileKeysVariationKey : kExperimentWithAudienceVariationKey };
//    OPTLYVariation *variation = [[OPTLYVariation alloc] initWithDictionary:variationDict error:nil];
//
//    OPTLYExperiment *experiment = [self.config getExperimentForKey:kExperimentWithAudienceKey];
//    [self.decisionService saveUserProfile:nil variation:variation experiment:experiment userId:kUserId];
//
//    OCMVerify([userProfileServiceMock save:self.userProfileWithFirefoxAudience]);
//
//    [decisionServiceMock stopMocking];
//    [userProfileServiceMock stopMocking];
//    }
//
//    // check the format of the user profile object when saving multiple experiment-to-variation bucket value for a single user
//    - (void)testSaveMultipleVariations
//    {
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    id userProfileServiceMock = OCMPartialMock((NSObject *)self.config.userProfileService);
//
//    NSDictionary *userProfileMultipleExperimentValues = @{ OPTLYDatafileKeysUserProfileServiceUserId : kUserId,
//    OPTLYDatafileKeysUserProfileServiceExperimentBucketMap : @{
//    kExperimentWithAudienceId : @{ OPTLYDatafileKeysUserProfileServiceVariationId : kExperimentWithAudienceVariationId },
//    kExperimentNoAudienceId : @{ OPTLYDatafileKeysUserProfileServiceVariationId : kExperimentNoAudienceVariationId } } };
//
//    NSDictionary *variationWithAudienceDict = @{ OPTLYDatafileKeysVariationId  : kExperimentWithAudienceVariationId,
//    OPTLYDatafileKeysVariationKey : kExperimentWithAudienceVariationKey };
//    OPTLYVariation *variationWithAudience = [[OPTLYVariation alloc] initWithDictionary:variationWithAudienceDict error:nil];
//    OPTLYExperiment *experimentWithAudience = [self.config getExperimentForKey:kExperimentWithAudienceKey];
//    [self.decisionService saveUserProfile:nil variation:variationWithAudience experiment:experimentWithAudience userId:kUserId];
//
//    NSDictionary *variationNoAudienceDict = @{ OPTLYDatafileKeysVariationId  : kExperimentNoAudienceVariationId,
//    OPTLYDatafileKeysVariationKey : kExperimentNoAudienceVariationKey };
//    OPTLYVariation *variationNoAudience = [[OPTLYVariation alloc] initWithDictionary:variationNoAudienceDict error:nil];
//    OPTLYExperiment *experimentNoAudience = [self.config getExperimentForKey:kExperimentNoAudienceKey];
//    [self.decisionService saveUserProfile:self.userProfileWithFirefoxAudience variation:variationNoAudience experiment:experimentNoAudience userId:kUserId];
//
//    // make sure that the user profile service save is called on a user profile object with the expected values
//    OCMVerify([userProfileServiceMock save:userProfileMultipleExperimentValues]);
//
//    [decisionServiceMock stopMocking];
//    [userProfileServiceMock stopMocking];
//    }
//
//    #pragma mark - GetVariationForFeatureExperiment
//
//    // should return nil when the feature flag's experiment ids array is empty
//    - (void)testGetVariationForFeatureWithNoExperimentId {
//    OPTLYFeatureFlag *emptyFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagEmptyKey];
//    OPTLYFeatureDecision *decision = [self.decisionService getVariationForFeature:emptyFeatureFlag userId:kUserId attributes:nil];
//    XCTAssertNil(decision, "Get variation for feature with no experiment should return nil: %", decision);
//    }
//
//    // should return nil when the feature flag's group id is invalid
//    - (void)testGetVariationForFeatureWithInvalidGroupId {
//    OPTLYFeatureFlag *invalidFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagInvalidGroupKey];
//    OPTLYFeatureDecision *decision = [self.decisionService getVariationForFeature:invalidFeatureFlag userId:kUserId attributes:nil];
//    XCTAssertNil(decision, "Get variation for feature with invalid group should return nil: %", decision);
//    }
//
//    // should return nil when the feature flag's experiment id is invalid
//    - (void)testGetVariationForFeatureWithInvalidExperimentId {
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagInvalidExperimentKey];
//    OPTLYFeatureDecision *decision = [self.decisionService getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:nil];
//    XCTAssertNil(decision, "Get variation for feature with invalid experiment should return nil: %", decision);
//    }
//
//    // should return nil when the user is not bucketed into the feature flag's experiments
//    - (void)testGetVariationForFeatureWithNonMutexGroupAndUserNotBucketed {
//
//    OPTLYExperiment *multiVariateExp = [self.config getExperimentForKey:kExperimentMultiVariateKey];
//
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    OCMStub([decisionServiceMock getVariation:kUserId experiment:multiVariateExp attributes:nil]).andReturn(nil);
//
//    OPTLYFeatureFlag *multiVariateFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagMultiVariateKey];
//
//    OPTLYFeatureDecision *decision = [decisionServiceMock getVariationForFeature:multiVariateFeatureFlag userId:kUserId attributes:nil];
//    XCTAssertNil(decision, "Get variation for feature with no bucketed experiment should return nil: %", decision);
//
//    OCMVerify([decisionServiceMock getVariation:kUserId experiment:multiVariateExp attributes:nil]);
//    [decisionServiceMock stopMocking];
//    }
//
//    // should return nil when the user is not bucketed into any of the mutex experiments
//    - (void)testGetVariationForFeatureWithMutexGroupAndUserNotBucketed {
//    OPTLYExperiment *mutexExperiment = [self.config getExperimentForKey:kExperimentMutexGroupKey];
//
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    OCMStub([decisionServiceMock getVariation:[OCMArg any] experiment:[OCMArg any] attributes:[OCMArg any]]).andReturn(nil);
//
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagMutexGroupKey];
//    OPTLYFeatureDecision *decision = [decisionServiceMock getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:@{}];
//
//    XCTAssertNil(decision, "Get variation for feature with no bucketed mutex experiment should return nil: %", decision);
//
//    OCMVerify([decisionServiceMock getVariation:kUserId experiment:mutexExperiment attributes:@{}]);
//    [decisionServiceMock stopMocking];
//    }
//
//    // should return variation when the user is bucketed into a variation for the experiment on the feature flag
//    - (void)testGetVariationForFeatureWithNonMutexGroupAndUserIsBucketed {
//
//    OPTLYExperiment *multiVariateExp = [self.config getExperimentForKey:kExperimentMultiVariateKey];
//    OPTLYVariation *expectedVariation = [multiVariateExp getVariationForVariationId:kExperimentMultiVariateVariationId];
//    OPTLYFeatureDecision *expectedDecision = [[OPTLYFeatureDecision alloc] initWithExperiment:multiVariateExp
//    variation:expectedVariation
//    source:DecisionSourceExperiment];
//
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    OCMStub([decisionServiceMock getVariation:kUserId experiment:multiVariateExp attributes:@{}]).andReturn(expectedVariation);
//
//    OPTLYFeatureFlag *multiVariateFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagMultiVariateKey];
//    OPTLYFeatureDecision *decision = [decisionServiceMock getVariationForFeature:multiVariateFeatureFlag userId:kUserId attributes:@{}];
//
//    XCTAssertNotNil(decision, "Get variation for feature with bucketed experiment should return variation: %", decision);
//    XCTAssertEqualObjects(decision.variation, expectedDecision.variation);
//
//    OCMVerify([decisionServiceMock getVariation:kUserId experiment:multiVariateExp attributes:@{}]);
//    [decisionServiceMock stopMocking];
//    }
//
//    // should return variation when the user is bucketed into one of the experiments on the feature flag
//    - (void)testGetVariationForFeatureWithMutexGroupAndUserIsBucketed {
//    OPTLYExperiment *mutexExperiment = [self.config getExperimentForKey:kExperimentMutexGroupKey];
//    OPTLYVariation *expectedVariation = mutexExperiment.variations[0];
//    OPTLYFeatureDecision *expectedDecision = [[OPTLYFeatureDecision alloc] initWithExperiment:mutexExperiment
//    variation:expectedVariation
//    source:DecisionSourceExperiment];
//    id decisionServiceMock = OCMPartialMock(self.decisionService);
//    OCMStub([decisionServiceMock getVariation:kUserId experiment:mutexExperiment attributes:@{}]).andReturn(expectedVariation);
//
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagMutexGroupKey];
//    OPTLYFeatureDecision *decision = [decisionServiceMock getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:@{}];
//
//    XCTAssertNotNil(decision, "Get variation for feature with one of the bucketed experiment should return variation: %", decision);
//    XCTAssertEqualObjects(decision.variation, expectedDecision.variation);
//
//    OCMVerify([decisionServiceMock getVariation:kUserId experiment:mutexExperiment attributes:@{}]);
//    [decisionServiceMock stopMocking];
//    }
//
//    #pragma mark - GetVariationForFeatureRollout
//
//    // should return nil when rollout doesn't exist for the feature.
//    - (void)testGetVariationForFeatureWithInvalidRolloutId {
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagInvalidRolloutKey];
//    OPTLYFeatureDecision *decision = [self.decisionService getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:nil];
//    XCTAssertNil(decision, "Get variation for feature with invalid rollout should return nil: %", decision);
//    }
//
//    // should return nil when rollout doesn't contain any rule.
//    - (void)testGetVariationForFeatureWithNoRule {
//    OPTLYFeatureFlag *stringFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagEmptyRuleRolloutKey];
//    NSDictionary *userAttributes = @{ kAttributeKey: kAttributeValueChrome };
//
//    OPTLYFeatureDecision *decision = [self.decisionService getVariationForFeature:stringFeatureFlag userId:kUserId attributes:userAttributes];
//
//    XCTAssertNil(decision, "Get variation for feature with rollout having no rule should return nil: %", decision);
//    }
//
//    // should return nil when the user is not bucketed into targeting rule as well as "Fall Back" rule.
//    - (void)testGetVariationForFeatureWithNoBucketing {
//    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizely.logger);
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagNoBucketedRuleRolloutKey];
//    NSString *rolloutId = booleanFeatureFlag.rolloutId;
//    OPTLYRollout *rollout = [self.config getRolloutForId:rolloutId];
//    OPTLYExperiment *experiment = rollout.experiments[0];
//    OPTLYExperiment *fallBackRule = rollout.experiments[rollout.experiments.count - 1];
//    NSDictionary *userAttributes = @{ kAttributeKey: kAttributeValueChrome };
//
//    id bucketerMock = OCMPartialMock(self.bucketer);
//    OCMStub([bucketerMock bucketExperiment:[OCMArg any] withBucketingId:[OCMArg any]]).andReturn(nil);
//    OPTLYDecisionService *decisionService = [[OPTLYDecisionService alloc] initWithProjectConfig:self.config bucketer:bucketerMock];
//
//    OPTLYFeatureDecision *decision = [decisionService getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:userAttributes];
//    [loggerMock stopMocking];
//
//    XCTAssertNil(decision, "Get variation for feature with rollout having no bucketing rule should return nil: %", decision);
//
//    OCMVerify([bucketerMock bucketExperiment:experiment withBucketingId:kUserId]);
//    OCMVerify([bucketerMock bucketExperiment:fallBackRule withBucketingId:kUserId]);
//    [bucketerMock stopMocking];
//    }
//
//    // should return variation when the user is bucketed into targeting rule
//    - (void)testGetVariationForFeatureWithTargetingRuleBucketing {
//
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagNoBucketedRuleRolloutKey];
//    NSString *rolloutId = booleanFeatureFlag.rolloutId;
//    OPTLYRollout *rollout = [self.config getRolloutForId:rolloutId];
//    OPTLYExperiment *experiment = rollout.experiments[0];
//    OPTLYVariation *expectedVariation = experiment.variations[0];
//    OPTLYFeatureDecision *expectedDecision = [[OPTLYFeatureDecision alloc] initWithExperiment:experiment
//    variation:expectedVariation
//    source:DecisionSourceRollout];
//    NSDictionary *userAttributes = @{ kAttributeKey: kAttributeValueChrome };
//
//    id bucketerMock = OCMPartialMock(self.bucketer);
//    OCMStub([bucketerMock bucketExperiment:[OCMArg any] withBucketingId:[OCMArg any]]).andReturn(expectedVariation);
//    OPTLYDecisionService *decisionService = [[OPTLYDecisionService alloc] initWithProjectConfig:self.config bucketer:bucketerMock];
//
//    OPTLYFeatureDecision *decision = [decisionService getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:userAttributes];
//
//    XCTAssertNotNil(decision, "Get variation for feature with rollout having targeting rule should return variation: %", decision);
//    XCTAssertEqualObjects(decision.variation, expectedDecision.variation);
//
//    OCMVerify([bucketerMock bucketExperiment:experiment withBucketingId:kUserId]);
//    [bucketerMock stopMocking];
//    }
//
//    // should return variation when the user is bucketed into "Fall Back" rule instead of targeting rule
//    - (void)testGetVariationForFeatureWithFallBackRuleBucketing {
//    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizely.logger);
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagNoBucketedRuleRolloutKey];
//    NSString *rolloutId = booleanFeatureFlag.rolloutId;
//    OPTLYRollout *rollout = [self.config getRolloutForId:rolloutId];
//    OPTLYExperiment *experiment = rollout.experiments[0];
//    OPTLYExperiment *fallBackRule = rollout.experiments[rollout.experiments.count - 1];
//    OPTLYVariation *expectedVariation = fallBackRule.variations[0];
//    OPTLYFeatureDecision *expectedDecision = [[OPTLYFeatureDecision alloc] initWithExperiment:fallBackRule
//    variation:expectedVariation
//    source:DecisionSourceRollout];
//    NSDictionary *userAttributes = @{ kAttributeKey: kAttributeValueChrome };
//
//    id bucketerMock = OCMPartialMock(self.bucketer);
//    OCMStub([bucketerMock bucketExperiment:experiment withBucketingId:[OCMArg any]]).andReturn(nil);
//    OCMStub([bucketerMock bucketExperiment:fallBackRule withBucketingId:kAttributeValueChrome]).andReturn(expectedVariation);
//    OPTLYDecisionService *decisionService = [[OPTLYDecisionService alloc] initWithProjectConfig:self.config bucketer:bucketerMock];
//
//    OPTLYFeatureDecision *decision = [decisionService getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:userAttributes];
//    [loggerMock stopMocking];
//
//    XCTAssertNotNil(decision, "Get variation for feature with rollout having fall back rule should return variation: %", decision);
//    XCTAssertEqualObjects(decision.variation, expectedDecision.variation);
//
//    OCMVerify([bucketerMock bucketExperiment:experiment withBucketingId:kUserId]);
//    OCMVerify([bucketerMock bucketExperiment:fallBackRule withBucketingId:kUserId]);
//    [bucketerMock stopMocking];
//    }
//
//    // should return variation when the user is bucketed into "Fall Back" after attempting to bucket into all targeting rules
//    - (void)testGetVariationForFeatureWithFallBackRuleBucketingButNoTargetingRule {
//    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizely.logger);
//    OPTLYFeatureFlag *booleanFeatureFlag = [self.config getFeatureFlagForKey:kFeatureFlagNoBucketedRuleRolloutKey];
//    NSString *rolloutId = booleanFeatureFlag.rolloutId;
//    OPTLYRollout *rollout = [self.config getRolloutForId:rolloutId];
//    OPTLYExperiment *fallBackRule = rollout.experiments[rollout.experiments.count - 1];
//    OPTLYVariation *expectedVariation = fallBackRule.variations[0];
//    OPTLYFeatureDecision *expectedDecision = [[OPTLYFeatureDecision alloc] initWithExperiment:fallBackRule
//    variation:expectedVariation
//    source:DecisionSourceRollout];
//
//    id bucketerMock = OCMPartialMock(self.bucketer);
//    OCMStub([bucketerMock bucketExperiment:fallBackRule withBucketingId:[OCMArg any]]).andReturn(expectedVariation);
//    OPTLYDecisionService *decisionService = [[OPTLYDecisionService alloc] initWithProjectConfig:self.config bucketer:bucketerMock];
//
//    // Provide null attributes so that user does not qualify for audience.
//    OPTLYFeatureDecision *decision = [decisionService getVariationForFeature:booleanFeatureFlag userId:kUserId attributes:nil];
//    [loggerMock stopMocking];
//
//    XCTAssertNotNil(decision, "Get variation for feature with rollout having fall back rule after failing all targeting rules should return variation: %", decision);
//    XCTAssertEqualObjects(decision.variation, expectedDecision.variation);
//
//    OCMVerify([bucketerMock bucketExperiment:fallBackRule withBucketingId:kUserId]);
//    [bucketerMock stopMocking];
//    }
//
//    - (void)testGetVariationForFeatureWithFallBackRuleBucketingId {
//    id loggerMock = OCMPartialMock((OPTLYLoggerDefault *)self.optimizely.logger);
//    OPTLYFeatureFlag *featureFlag = [self.config getFeatureFlagForKey:kFeatureFlagNoBucketedRuleRolloutKey];
//    OPTLYRollout *rollout = [self.config getRolloutForId:featureFlag.rolloutId];
//    OPTLYExperiment *rolloutRuleExperiment = rollout.experiments[rollout.experiments.count - 1];
//    OPTLYVariation *rolloutVariation = rolloutRuleExperiment.variations[0];
//    NSString *bucketingId = "user_bucketing_id"
//    NSString *userId = "user_id"
//    NSDictionary *attributes = @{OptimizelyBucketId: bucketingId};
//
//    id bucketerMock = OCMPartialMock(self.bucketer);
//    OCMStub([bucketerMock bucketExperiment:rolloutRuleExperiment withBucketingId:userId]).andReturn(nil);
//    OCMStub([bucketerMock bucketExperiment:rolloutRuleExperiment withBucketingId:bucketingId]).andReturn(rolloutVariation);
//
//    OPTLYDecisionService *decisionService = [[OPTLYDecisionService alloc] initWithProjectConfig:self.config
//    bucketer:bucketerMock];
//
//    OPTLYFeatureDecision *expectedFeatureDecision = [[OPTLYFeatureDecision alloc] initWithExperiment:rolloutRuleExperiment
//    variation:rolloutVariation
//    source:DecisionSourceRollout];
//    OPTLYFeatureDecision *featureDecision = [decisionService getVariationForFeature:featureFlag userId:userId attributes:attributes];
//    [loggerMock stopMocking];
//
//    XCTAssertEqualObjects(expectedFeatureDecision.experiment, featureDecision.experiment);
//    XCTAssertEqualObjects(expectedFeatureDecision.variation, featureDecision.variation);
//    XCTAssertEqualObjects(expectedFeatureDecision.source, featureDecision.source);
//    }

}
