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
        decisionService = (optimizely.decisionService as! DefaultDecisionService)
        ups = decisionService.userProfileService
        try! optimizely.start(datafile: datafile)
    }
    
}

// MARK: - decide API

extension OptimizelyClientTests_Decide {
    
    func testDecide() {
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertEqual(decision.enabled, true)
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
        
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
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
        
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
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
    
    func testDecide_sendImpression() {
        let featureKey = "feature_2"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertNotNil(decision.enabled)
        XCTAssertNotNil(eventDispatcher.eventSent)
        
        let desc = eventDispatcher.eventSent!.description
        XCTAssert(desc.contains("campaign_activated"))
    }
    
    func testDecide_doNotSendImpression() {
        let featureKey = "common_name"   // no experiment

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNil(decision.variationKey)
        XCTAssertNotNil(decision.enabled)
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
        
        let expDecision = OptimizelyDecision(enabled: true,
                                             variables: variablesExpected,
                                             variationKey: "variation_with_traffic",
                                             ruleKey: nil,
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
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: nil,
                                                                ruleKey: nil,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected2,
                                                                variationKey: "variation_with_traffic",
                                                                ruleKey: nil,
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
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: nil,
                                                                ruleKey: nil,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected2,
                                                                variationKey: "variation_with_traffic",
                                                                ruleKey: nil,
                                                                key: featureKey2,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(enabled: false,
                                                                variables: variablesExpected3,
                                                                variationKey: nil,
                                                                ruleKey: nil,
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
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: nil,
                                                                ruleKey: nil,
                                                                key: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
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
        
}

// MARK: - options

extension OptimizelyClientTests_Decide {
    
    func testDecide_sendImpression_disbleTracking() {
        let featureKey = "feature_1"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey, options: [.disableTracking])
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.enabled)
        XCTAssertNil(eventDispatcher.eventSent)
    }
    
    func testDecideOptions_useUPSbyDefault() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"
        let variationId = "10418551353"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))

        // this will set UPS
        _ = optimizely.decide(key: featureKey)
        
        XCTAssert(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId) == variationId)
    }
    
    func testDecideOptions_bypassUPS_doNotUpdateUPS() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))

        // this will not set UPS because of bypassUPS option
        _ = optimizely.decide(key: featureKey, options: [.bypassUPS])
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))
    }

    func testDecideOptions_bypassUPS_doNotReadUPS() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"
        let variationKey1 = "variation_with_traffic"
        let variationKey2 = "variation_no_traffic"
        let variationId2 = "10418510624"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        
        OTUtils.setVariationToUPS(ups: ups, userId: kUserId, experimentId: experimentId, variationId: variationId2)
        XCTAssert(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId) == variationId2)

        let decision1 = optimizely.decide(key: featureKey)
        let decision2 = optimizely.decide(key: featureKey, options: [.bypassUPS])

        XCTAssert(decision1.variationKey == variationKey2)
        XCTAssert(decision2.variationKey == variationKey1)
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
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: "variation_with_traffic",
                                                                ruleKey: nil,
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
