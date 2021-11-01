//
// Copyright 2021, Optimizely, Inc. and contributors
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

class OptimizelyUserContextTests_Decide_Reasons: XCTestCase {
    
    let kUserId = "tester"
    
    var optimizely: OptimizelyClient!
    var decisionService: DefaultDecisionService!
    var ups: OPTUserProfileService!
    var user: OptimizelyUserContext!

    override func setUp() {
        super.setUp()
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      userProfileService: OTUtils.createClearUserProfileService())
        user = optimizely.createUserContext(userId: kUserId)
        decisionService = optimizely.decisionService as? DefaultDecisionService
        ups = decisionService.userProfileService
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("decide_datafile")!)
    }
    
}

// MARK: - error reasons (always included)

extension OptimizelyUserContextTests_Decide_Reasons {

    func testDecideReasons_sdkNotReady() {
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      userProfileService: OTUtils.createClearUserProfileService())
        try? optimizely.start(datafile: OTUtils.loadJSONDatafile("unsupported_datafile")!)
        user = optimizely.createUserContext(userId: kUserId)

        let decision = user.decide(key: "any-key")
        XCTAssert(decision.hasFailed)
        XCTAssertEqual(decision.reasons, [OptimizelyError.sdkNotReady.reason])
    }
    
    func testDecideReasons_featureKeyInvalid() {
        let key = "invalid-key"
        let decision = user.decide(key: key)
        XCTAssert(decision.hasFailed)
        XCTAssertEqual(decision.reasons, [OptimizelyError.featureKeyInvalid(key).reason])
    }
        
    func testDecideReasons_variableValueInvalid() {
        let featureKey = "feature_1"
        let rolloutId = "3319450668"
        let integerVariableId = "2687470095"
        let integerVariableKey = "i_42"

        // inject invalid variable value
        var rollout = optimizely.config!.getRollout(id: rolloutId)!
        var rolloutVariation = rollout.experiments[0].variations[0]
        rolloutVariation.variables = [Variable(id: integerVariableId, value: "invalid")]
        rollout.experiments[0].variations[0] = rolloutVariation
        optimizely.config!.rolloutIdMap = [rolloutId: rollout]
        
        user.setAttribute(key: "country", value: "US")
        let decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.contains(OptimizelyError.variableValueInvalid(integerVariableKey).reason))
    }
    
}

// MARK: - error messages (only with "includeReasons")

extension OptimizelyUserContextTests_Decide_Reasons {

    func testDecideReasons_conditionNoMatchingAudience() {
        let featureKey = "feature_1"
        let audienceId = "invalid_id"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)

        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.conditionNoMatchingAudience(audienceId).reason))
    }
    
    func testDecideReasons_conditionInvalidFormat() {
        let featureKey = "feature_1"
        let audienceId = "invalid_format"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)

        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.conditionInvalidFormat("Empty condition array").reason))
    }
    
    func testDecideReasons_evaluateAttributeInvalidCondition() {
        let featureKey = "feature_1"
        let audienceId = "invalid_condition"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)

        let condition = "{\"match\":\"gt\",\"value\":\"US\",\"name\":\"age\",\"type\":\"custom_attribute\"}"
        user.setAttribute(key: "age", value: 25)

        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.evaluateAttributeInvalidCondition(condition).reason))
    }
    
    func testDecideReasons_evaluateAttributeInvalidType() {
        let featureKey = "feature_1"
        let audienceId = "13389130056"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)

        let condition = "{\"match\":\"exact\",\"value\":\"US\",\"name\":\"country\",\"type\":\"custom_attribute\"}"
        let attributeKey = "country"
        let attributeValue = 25
        user.setAttribute(key: attributeKey, value: attributeValue)
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.evaluateAttributeInvalidType(condition, attributeValue, attributeKey).reason))
    }
    
    func testDecideReasons_evaluateAttributeValueOutOfRange() {
        let featureKey = "feature_1"
        let audienceId = "age_18"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)

        let condition = "{\"match\":\"gt\",\"value\":18,\"name\":\"age\",\"type\":\"custom_attribute\"}"
        user.setAttribute(key: "age", value: pow(2,54) as Double)   // TOO-BIG value
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.evaluateAttributeValueOutOfRange(condition, "age").reason))
    }
    
    func testDecideReasons_userAttributeInvalidType() {
        let featureKey = "feature_1"
        let audienceId = "invalid_type"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)
                
        let condition = "{\"match\":\"gt\",\"value\":18,\"name\":\"age\",\"type\":\"invalid\"}"
        user.setAttribute(key: "age", value: 25)
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.userAttributeInvalidType(condition).reason))
    }
    
    func testDecideReasons_userAttributeInvalidMatch() {
        let featureKey = "feature_1"
        let audienceId = "invalid_match"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)
                
        let condition = "{\"match\":\"invalid\",\"value\":18,\"name\":\"age\",\"type\":\"custom_attribute\"}"
        user.setAttribute(key: "age", value: 25)
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.userAttributeInvalidMatch(condition).reason))
    }
    
    func testDecideReasons_userAttributeNilValue() {
        let featureKey = "feature_1"
        let audienceId = "nil_value"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)

        let condition = "{\"name\":\"age\",\"type\":\"custom_attribute\",\"match\":\"gt\"}"
        user.setAttribute(key: "age", value: 25)
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.userAttributeNilValue(condition).reason))
    }
    
    func testDecideReasons_userAttributeInvalidName() {
        let featureKey = "feature_1"
        let audienceId = "invalid_name"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)
                
        let condition = "{\"type\":\"custom_attribute\",\"match\":\"gt\",\"value\":18}"
        user.setAttribute(key: "age", value: 25)
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.userAttributeInvalidName(condition).reason))
    }
    
    func testDecideReasons_missingAttributeValue() {
        let featureKey = "feature_1"
        let audienceId = "age_18"
        setAudienceForFeatureTest(featureKey: featureKey, audienceId: audienceId)
                
        let condition = "{\"match\":\"gt\",\"value\":18,\"name\":\"age\",\"type\":\"custom_attribute\"}"
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(OptimizelyError.missingAttributeValue(condition, "age").reason))
    }
     
}

// MARK: - log messages (only with "includeReasons")

extension OptimizelyUserContextTests_Decide_Reasons {

    func testDecideReasons_experimentNotRunning() {
        let featureKey = "feature_1"
        let experimentKey = "exp_with_audience"
        setStatusForFeatureTest(featureKey: featureKey, status: .paused)
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.experimentNotRunning(experimentKey).reason))
    }
    
    func testDecideReasons_gotVariationFromUserProfile() {
        let featureKey = "feature_1"        // embedding experiment: "exp_with_audience"
        let experimentId = "10390977673"    // "exp_with_audience"
        let experimentKey = "exp_with_audience"
        let variationKey2 = "b"
        let variationId2 = "10416523121"

        OTUtils.setVariationToUPS(ups: ups, userId: kUserId, experimentId: experimentId, variationId: variationId2)
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        
        XCTAssertEqual(decision.variationKey, variationKey2)
        XCTAssertEqual(decision.reasons,
                       [LogMessage.gotVariationFromUserProfile(variationKey2, experimentKey, kUserId).reason])
    }
    
    func testDecideReasons_forcedVariationFound() {
        let featureKey = "feature_1"
        let variationKey = "b"
        let experimentKey = setForcedVariationForFeatureTest(featureKey: featureKey, userId: kUserId, variationKey: variationKey)

        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssertEqual(decision.variationKey, variationKey)
        XCTAssertEqual(decision.reasons, [LogMessage.userHasForcedVariation(kUserId, experimentKey, variationKey).reason])
    }
    
    func testDecideReasons_forcedVariationFoundButInvalid() {
        let featureKey = "feature_1"
        let variationKey = "b"
        let experimentKey = setForcedVariationForFeatureTest(featureKey: featureKey, userId: kUserId, variationKey: variationKey)
        // remove all variations after setting forced variations
        removeVariationsForFeatureTest(featureKey: featureKey, userId: kUserId, variationKey: variationKey)
        
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssertNotEqual(decision.variationKey, variationKey)
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedVariationButInvalid(kUserId, experimentKey).reason))
    }
    
    func testDecideReasons_whiteListVariationFound() {
        let featureKey = "feature_1"
        let variationKey = "b"
        setWhiteListForFeatureTest(featureKey: featureKey, userId: kUserId, variationKey: variationKey)

        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssertEqual(decision.variationKey, variationKey)
        XCTAssertEqual(decision.reasons, [LogMessage.forcedVariationFound(variationKey, kUserId).reason])
    }
    
    func testDecideReasons_whiteListVariationFoundButInvalid() {
        let featureKey = "feature_1"
        let variationKey = "invalid-key"
        setWhiteListForFeatureTest(featureKey: featureKey, userId: kUserId, variationKey: variationKey)

        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssertNotEqual(decision.variationKey, variationKey)
        XCTAssert(decision.reasons.contains(LogMessage.forcedVariationFoundButInvalid(variationKey, kUserId).reason))
    }

    func testDecideReasons_userMeetsConditionsForTargetingRule() {
        let key = "feature_1"
        
        user.setAttribute(key: "country", value: "US")
        var decision = user.decide(key: key)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: key, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userMeetsConditionsForTargetingRule(kUserId, "1").reason))
    }
    
    func testDecideReasons_userDoesntMeetConditionsForTargetingRule() {
        let key = "feature_1"
        
        user.setAttribute(key: "country", value: "CA")
        var decision = user.decide(key: key)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: key, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userDoesntMeetConditionsForTargetingRule(kUserId, "1").reason))
    }
    
    func testDecideReasons_userBucketedIntoTargetingRule() {
        let key = "feature_1"
        
        user.setAttribute(key: "country", value: "US")
        var decision = user.decide(key: key)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: key, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoTargetingRule(kUserId, "1").reason))
    }
      
    func testDecideReasons_userBucketedIntoEveryoneTargetingRule() {
        let key = "feature_1"
        
        user.setAttribute(key: "country", value: "KO")
        var decision = user.decide(key: key)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: key, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoTargetingRule(kUserId, "Everyone Else").reason))
    }
    
    func testDecideReasons_userNotBucketedIntoTargetingRule() {
        let key = "feature_1"
        
        user.setAttribute(key: "browser", value: "safari")
        var decision = user.decide(key: key)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: key, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userNotBucketedIntoTargetingRule(kUserId, "2").reason))
    }
        
    func testDecideReasons_userBucketedIntoVariationInExperiment() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentKey = "exp_no_audience"
        let variationKey = "variation_with_traffic"
        
        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.ignoreUserProfileService, .includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoVariationInExperiment(kUserId,
                                                                                             experimentKey,
                                                                                             variationKey).reason))
    }
    
    func testDecideReasons_userNotBucketedIntoVariation() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"

        var experiment = optimizely.config!.getExperiment(id: experimentId)!
        var trafficAllocation = experiment.trafficAllocation[0]
        trafficAllocation.endOfRange = 0
        experiment.trafficAllocation = [trafficAllocation]
        optimizely.config!.experimentIdMap = [experimentId: experiment]

        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userNotBucketedIntoVariation(kUserId).reason))
    }
    
    func testDecideReasons_userBucketedIntoInvalidVariation() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"
        let variationKey = "variation_with_traffic"
        let variationIdCorrect = "10418551353"
        let variationIdInvalid = "invalid"
        
        var experiment = optimizely.config!.getExperiment(id: experimentId)!
        var variation = experiment.getVariation(key: variationKey)!
        variation.id = variationIdInvalid
        experiment.variations = [variation]
        optimizely.config!.experimentIdMap = [experimentId: experiment]

        var decision = user.decide(key: featureKey)
        XCTAssert(decision.reasons.isEmpty)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoInvalidVariation(variationIdCorrect).reason))
    }
    
    func testDecideReasons_userBucketedIntoExperimentInGroup() {
        let featureKey = "feature_3"
        let experimentKey = "group_exp_1"
        let groupId = "13142870430"
        setExperimentForFeatureTest(featureKey: featureKey, experimentKey: experimentKey)

        let decision = user.decide(key: featureKey, options: [.ignoreUserProfileService, .includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoExperimentInGroup(kUserId,
                                                                                         experimentKey,
                                                                                         groupId).reason))
    }
    
    func testDecideReasons_userNotBucketedIntoExperimentInGroup() {
        let featureKey = "feature_3"
        let experimentKey = "group_exp_2"
        let groupId = "13142870430"
        setExperimentForFeatureTest(featureKey: featureKey, experimentKey: experimentKey)

        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userNotBucketedIntoExperimentInGroup(kUserId,
                                                                                            experimentKey,
                                                                                            groupId).reason))
    }
    
    func testDecideReasons_userNotBucketedIntoAnyExperimentInGroup() {
        let groupId = "13142870430"
        var group = optimizely.config!.getGroup(id: groupId)!
        group.trafficAllocation = []
        optimizely.config!.project.groups = [group]

        // set up temp feature-experiments AFTER config.project updated (otherwise overwritten)
        let featureKey = "feature_3"
        let experimentKey = "group_exp_1"
        setExperimentForFeatureTest(featureKey: featureKey, experimentKey: experimentKey)

        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userNotBucketedIntoAnyExperimentInGroup(kUserId,
                                                                                               groupId).reason))
    }
    
    func testDecideReasons_userBucketedIntoInvalidExperiment() {
        let experimentIdInvalid = "invalid"
        let groupId = "13142870430"
        var group = optimizely.config!.getGroup(id: groupId)!
        var trafficAllocation = group.trafficAllocation[0]
        trafficAllocation.entityId = experimentIdInvalid
        group.trafficAllocation = [trafficAllocation]
        optimizely.config!.project.groups = [group]

        // set up temp feature-experiments AFTER config.project updated (otherwise overwritten)
        let featureKey = "feature_3"
        let experimentKey = "group_exp_1"
        setExperimentForFeatureTest(featureKey: featureKey, experimentKey: experimentKey)

        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userBucketedIntoInvalidExperiment(experimentIdInvalid).reason))
    }
    
    func testDecideReasons_userNotInExperiment() {
        let featureKey = "feature_1"
        let experimentKey = "exp_with_audience"
        
        let decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userNotInExperiment(kUserId, experimentKey).reason))
    }
        
}

// Utils

extension OptimizelyUserContextTests_Decide_Reasons {

    func setAudienceForFeatureTest(featureKey: String, audienceId: String) {
        let experimentId = "10390977673"    // "exp_with_audience"
        var experiment = optimizely.config!.getExperiment(id: experimentId)!
        experiment.audienceIds = [audienceId]
        optimizely.config!.experimentIdMap = [experimentId: experiment]
    }
    
    func setStatusForFeatureTest(featureKey: String, status: Experiment.Status) {
        let experimentId = "10390977673"    // "exp_with_audience"
        var experiment = optimizely.config!.getExperiment(id: experimentId)!
        experiment.status = status
        optimizely.config!.experimentIdMap = [experimentId: experiment]
    }
    
    func setForcedVariationForFeatureTest(featureKey: String, userId: String, variationKey: String) -> String {
        let experimentId = "10390977673"    // "exp_with_audience"
        let experiment = optimizely.config!.getExperiment(id: experimentId)!
        _ = optimizely.setForcedVariation(experimentKey: experiment.key, userId: userId, variationKey: variationKey)
        return experiment.key
    }

    func removeVariationsForFeatureTest(featureKey: String, userId: String, variationKey: String) {
        let experimentId = "10390977673"    // "exp_with_audience"
        var experiment = optimizely.config!.getExperiment(id: experimentId)!
        experiment.variations = []
        optimizely.config!.experimentIdMap = [experimentId: experiment]
        optimizely.config!.experimentKeyMap = [experiment.key: experiment]
    }

    func setWhiteListForFeatureTest(featureKey: String, userId: String, variationKey: String) {
        let experimentId = "10390977673"    // "exp_with_audience"
        var experiment = optimizely.config!.getExperiment(id: experimentId)!
        experiment.forcedVariations = [userId: variationKey]
        optimizely.config!.experimentIdMap = [experimentId: experiment]
    }

    func setExperimentForFeatureTest(featureKey: String, experimentKey: String) {
        let experimentId = optimizely.config!.getExperimentId(key: experimentKey)!
        var feature = optimizely.config!.getFeatureFlag(key: featureKey)!
        feature.experimentIds = [experimentId]
        optimizely.config!.featureFlagKeyMap = [featureKey: feature]
    }

}

