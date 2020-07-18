/****************************************************************************
 * Copyright 2020, Optimizely, Inc. and contributors                        *
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

class OptimizelyClientTests_Decide: XCTestCase {
    
    let kUserId = "tester"
    
    var optimizely: OptimizelyClient!
    var eventDispatcher = MockEventDispatcher()
    var decisionService: DefaultDecisionService!
    var ups: OPTUserProfileService!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        decisionService = optimizely.decisionService as? DefaultDecisionService
        ups = decisionService.userProfileService
        try! optimizely.start(datafile: datafile)
    }
    
}

// MARK: - decide API

extension OptimizelyClientTests_Decide {
    
    func testDecide_feature() {
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
    func testDecide_experiment() {
        let experimentKey = "exp_no_audience"
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: experimentKey)
        
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertNil(decision.enabled)
        XCTAssertNil(decision.variables)
        
        XCTAssertEqual(decision.key, experimentKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
    func testDecide_featureAndExperimentNameConflict() {
        let featureKey = "common_name"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, false)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    func testDecide_userSetInCallParameter() {
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        
        let decision = optimizely.decide(key: featureKey, user: user)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
    func testDecide_userSetInCallParameterOverriding() {
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user1 = OptimizelyUserContext(userId: kUserId)
        let user2 = OptimizelyUserContext(userId: "newUser")
        try? optimizely.setUserContext(user1)
        let decision = optimizely.decide(key: featureKey, user: user2)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user2)
        XCTAssert(decision.reasons.isEmpty)
    }
    
}

// MARK: - impression events

extension OptimizelyClientTests_Decide {
    
    // NOTE: we here validate impression events only.
    //       all decision-notification tests are in "OptimizelyTests-Common/DecisionListenerTests"
    
    func testDecide_feature_sendImpression() {
        let featureKey = "feature_2"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.enabled)
        XCTAssertNotNil(eventDispatcher.eventSent)
        
        let desc = eventDispatcher.eventSent!.description
        XCTAssert(desc.contains("campaign_activated"))
    }
    
    func testDecide_feature_doNotSendImpression() {
        let featureKey = "common_name"   // no experiment

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.enabled)
        XCTAssertNil(eventDispatcher.eventSent)
    }

    func testDecide_experiment_sendImpression() {
        let experimentKey = "exp_no_audience"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: experimentKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.variationKey)
        XCTAssertNotNil(eventDispatcher.eventSent)
        
        let desc = eventDispatcher.eventSent!.description
        XCTAssert(desc.contains("campaign_activated"))
    }

    func testDecide_experiment_doNotSendImpression() {
        let experimentKey = "exp_with_audience"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: experimentKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNil(decision.variationKey)
        XCTAssertNil(eventDispatcher.eventSent)
    }
    
}

// MARK: - decideAll API

extension OptimizelyClientTests_Decide {
    
    func testDecideAll_oneFeature() {
        let featureKey = "feature_2"
        let featureKeys = [featureKey]
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[featureKey]!
        
        let expDecision = OptimizelyDecision(variationKey: nil,
                                             enabled: true,
                                             variables: variablesExpected,
                                             key: featureKey,
                                             user: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
    func testDecideAll_twoFeatures() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        
        let featureKeys = [featureKey1, featureKey2]
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                key: featureKey2,
                                                                user: user,
                                                                reasons: []))
    }
    
    func testDecideAll_nilKeys() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKey3 = "common_name"
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON(map: [:])
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: nil)
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                key: featureKey2,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: false,
                                                                variables: variablesExpected3,
                                                                key: featureKey3,
                                                                user: user,
                                                                reasons: []))
    }
    
    func testDecideAll_nilKeys_enabledOnly() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: nil, options: [.enabledOnly])
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                key: featureKey2,
                                                                user: user,
                                                                reasons: []))
    }

    
    func testDecideAll_emptyKeys() {
        let featureKeys = [String]()
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 0)
    }
    
    func testDecideAll_oneExperiment() {
        let experimentKey = "exp_no_audience"
        let experimentKeys = [experimentKey]
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: experimentKeys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[experimentKey]!
        
        let expDecision = OptimizelyDecision(variationKey: "variation_with_traffic",
                                             enabled: nil,
                                             variables: nil,
                                             key: experimentKey,
                                             user: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
    func testDecideAll_twoExperiments() {
        let experimentKey1 = "exp_with_audience"
        let experimentKey2 = "exp_no_audience"
        
        let experimentKeys = [experimentKey1, experimentKey2]
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: experimentKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[experimentKey1]! == OptimizelyDecision(variationKey: nil,    // audience missing
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey1,
                                                                   user: user,
                                                                   reasons: []))
        XCTAssert(decisions[experimentKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey2,
                                                                   user: user,
                                                                   reasons: []))
    }

    func testDecideAll_nilKeys_forExperiment() {
        let experimentKey1 = "exp_with_audience"
        let experimentKey2 = "exp_no_audience"
        let experimentKey3 = "common_name"
        let experimentKey4 = "group_exp_1"
        let experimentKey5 = "group_exp_2"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: nil, options: [.forExperiment])
        
        XCTAssert(decisions.count == 5)
        
        XCTAssert(decisions[experimentKey1]! == OptimizelyDecision(variationKey: nil,
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey1,
                                                                   user: user,
                                                                   reasons: []))
        XCTAssert(decisions[experimentKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey2,
                                                                   user: user,
                                                                   reasons: []))
        XCTAssert(decisions[experimentKey3]! == OptimizelyDecision(variationKey: "variation_a",
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey3,
                                                                   user: user,
                                                                   reasons: []))
        XCTAssert(decisions[experimentKey4]! == OptimizelyDecision(variationKey: "a",
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey4,
                                                                   user: user,
                                                                   reasons: []))
        XCTAssert(decisions[experimentKey5]! == OptimizelyDecision(variationKey: nil,       // group-exclusion
                                                                   enabled: nil,
                                                                   variables: nil,
                                                                   key: experimentKey5,
                                                                   user: user,
                                                                   reasons: []))
    }
    
    func testDecideAll_nameConflict() {
        let commonKey = "common_name"
        let keys = [commonKey]
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: commonKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: keys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[commonKey]!
        
        let expDecision = OptimizelyDecision(variationKey: nil,
                                             enabled: false,
                                             variables: variablesExpected,
                                             key: commonKey,
                                             user: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
}

// MARK: - options

extension OptimizelyClientTests_Decide {
    
    func testDecide_feature_sendImpression_disbleTracking() {
        let featureKey = "feature_1"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey, options: [.disableTracking])
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.enabled)
        XCTAssertNil(eventDispatcher.eventSent)
    }
    
    func testDecide_experiment_sendImpression_disableTracking() {
        let experimentKey = "exp_no_audience"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: experimentKey, options: [.disableTracking])
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.variationKey)
        XCTAssertNil(eventDispatcher.eventSent)
    }

    func testDecideOptions_useUPSbyDefault() {
        let experimentKey = "exp_no_audience"
        let experimentId = "10420810910"
        let variationId = "10418551353"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))

        _ = optimizely.decide(key: experimentKey)
        
        XCTAssert(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId) == variationId)
    }
    
    func testDecideOptions_bypassUPS_doNotUpdateUPS() {
        let experimentKey = "exp_no_audience"
        let experimentId = "10420810910"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))

        _ = optimizely.decide(key: experimentKey, options: [.bypassUPS])
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))
    }

    func testDecideOptions_bypassUPS_doNotReadUPS() {
        let experimentKey = "exp_no_audience"
        let experimentId = "10420810910"
        let variationKey1 = "variation_with_traffic"
        let variationKey2 = "variation_no_traffic"
        let variationId2 = "10418510624"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        OTUtils.setVariationToUPS(ups: ups, userId: kUserId, experimentId: experimentId, variationId: variationId2)
        XCTAssert(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId) == variationId2)

        let decision1 = optimizely.decide(key: experimentKey)
        let decision2 = optimizely.decide(key: experimentKey, options: [.bypassUPS])

        XCTAssert(decision1.variationKey == variationKey2)
        XCTAssert(decision2.variationKey == variationKey1)
    }

    func testDecideOptions_forExperiment() {
        let commonKey = "common_name"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: commonKey, options: [.forExperiment])
        
        XCTAssertEqual(decision.variationKey, "variation_a")
        XCTAssertNil(decision.enabled)
        XCTAssertNil(decision.variables)
        
        XCTAssertEqual(decision.key, commonKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
    func testDecideOptions_decideAll_forExperiment() {
        let commonKey = "common_name"
        let keys = [commonKey]
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: keys, options: [.forExperiment])
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[commonKey]!
        
        let expDecision = OptimizelyDecision(variationKey: "variation_a",
                                             enabled: nil,
                                             variables: nil,
                                             key: commonKey,
                                             user: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
}
    
// MARK: - debugging reasons
  
extension OptimizelyClientTests_Decide {

}

// MARK: - errors

extension OptimizelyClientTests_Decide {
    
    func testDecide_sdkNotReady() {
        let featureKey = "feature_1"
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        
        let user = OptimizelyUserContext(userId: kUserId)
        let decision = optimizely.decide(key: featureKey, user: user)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertNil(decision.enabled)
        XCTAssertNil(decision.variables)
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.sdkNotReady.reason)
    }
    
    func testDecide_userNotSet() {
        let featureKey = "feature_1"
        
        let decision = optimizely.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertNil(decision.enabled)
        XCTAssertNil(decision.variables)
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, nil)
        
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.userNotSet.reason)
    }
    
    func testDecide_invalidFeatureKey() {
        let featureKey = "invalid_key"
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        let decision = optimizely.decide(key: featureKey)
        
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.featureKeyInvalid(featureKey).reason)
    }
    
    func testDecide_invalidExperimentKey() {
        let experimentKey = "invalid_key"
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: experimentKey)
        
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.featureKeyInvalid(experimentKey).reason)
    }
    
    // decideAll
    
    func testDecideAll_sdkNotReady() {
        let featureKeys = ["feature_1"]
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        
        let user = OptimizelyUserContext(userId: kUserId)
        let decisions = optimizely.decideAll(keys: featureKeys, user: user)
        
        XCTAssert(decisions.count == 0)
    }
    
    func testDecideAll_userNotSet() {
        let featureKeys = ["feature_1"]

        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 0)
    }
    
    func testDecideAll_errorDecisionIncluded() {
        let featureKey1 = "feature_2"
        let featureKey2 = "invalid_key"

        let featureKeys = [featureKey1, featureKey2]
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision.errorDecision(key: featureKey2,
                                                                              user: user,
                                                                              error: .featureKeyInvalid(featureKey2)))
    }

}

// MARK: - helpers
    
class MockEventDispatcher: OPTEventDispatcher {
    var eventSent: EventForDispatch?
    
    func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        eventSent = event
    }
    
    func flushEvents() {
        
    }
}
