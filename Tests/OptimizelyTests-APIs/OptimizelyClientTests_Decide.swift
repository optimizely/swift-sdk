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

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        decisionService = (optimizely.decisionService as! DefaultDecisionService)
        try! optimizely.start(datafile: datafile)
    }
    
}

// MARK: - setUserContext

extension OptimizelyClientTests_Decide {
    
    func testSetUserContext() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user = OptimizelyUserContext(userId: "tester", attributes: attributes)
        
        optimizely.setUserContext(user)
        XCTAssert(optimizely.userContext == user)
    }
    
    func testSetUserContext_replace() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user1 = OptimizelyUserContext(userId: "tester1", attributes: attributes)
        let user2 = OptimizelyUserContext(userId: "tester2", attributes: [:])
        
        optimizely.setUserContext(user1)
        XCTAssert(optimizely.userContext == user1)
        
        optimizely.setUserContext(user2)
        XCTAssert(optimizely.userContext == user2)
    }
    
}
    
// MARK: - setDefaultDecideOptions

extension OptimizelyClientTests_Decide {

    func testSetDefaultDecideOptions() {
        let expOptions: [OptimizelyDecideOption] = [.ignoreUPS,
                                                    .disableDecisionEvent,
                                                    .enabledOnly,
                                                    .includeReasons]
        optimizely.setDefaultDecideOptions(expOptions)
        
        XCTAssert(optimizely.defaultDecideOptions == expOptions)
    }
    
    func testSetDefaultDecideOptions_replace() {
        let options1: [OptimizelyDecideOption] = [.ignoreUPS, .disableDecisionEvent]
        let options2: [OptimizelyDecideOption] = [.enabledOnly]

        optimizely.setDefaultDecideOptions(options1)
        XCTAssert(optimizely.defaultDecideOptions == options1)
        
        optimizely.setDefaultDecideOptions(options2)
        XCTAssert(optimizely.defaultDecideOptions == options2)
    }

}

// MARK: - decide

extension OptimizelyClientTests_Decide {

    func testDecide() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, "a")
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }

    func testDecide_userSetInCallParameter() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        
        let decision = optimizely.decide(key: featureKey, user: user)
        
        XCTAssertEqual(decision.variationKey, "a")
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
    func testDecide_userSetInCallParameterOverriding() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user1 = OptimizelyUserContext(userId: kUserId)
        let user2 = OptimizelyUserContext(userId: "newUser")
        optimizely.setUserContext(user1)
        let decision = optimizely.decide(key: featureKey, user: user2)
        
        XCTAssertEqual(decision.variationKey, "a")
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.user, user2)
        XCTAssert(decision.reasons.isEmpty)
    }
    
}

// MARK: - impression events

extension OptimizelyClientTests_Decide {
    
    // NOTE: we here validate impression events only.
    //       all decision-notification tests are in "OptimizelyTests-Common/DecisionListenerTests"
    
    func testDecide_sendImpression() {
        let featureKey = "feature_1"

        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertEqual(decision.variationKey, "a")
        XCTAssertNotNil(decision.enabled)
        XCTAssertNotNil(eventDispatcher.eventSent)
        
        let desc = eventDispatcher.eventSent!.description
        XCTAssert(desc.contains("campaign_activated"))
    }
    
    func testDecide_doNotSendImpression() {
        let featureKey = "common_name"   // no experiment

        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
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
        let featureKey = "feature_1"
        let featureKeys = [featureKey]
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[featureKey]!
        
        let expDecision = OptimizelyDecision(enabled: true,
                                             variables: variablesExpected,
                                             variationKey: "a",
                                             ruleKey: nil,
                                             flagKey: featureKey,
                                             user: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
    func testDecideAll_twoFeatures() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        
        let featureKeys = [featureKey1, featureKey2]
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = OptimizelyJSON(map: [:])
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: "a",
                                                                ruleKey: nil,
                                                                flagKey: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(enabled: false,
                                                                variables: variablesExpected2,
                                                                variationKey: nil,
                                                                ruleKey: nil,
                                                                flagKey: featureKey2,
                                                                user: user,
                                                                reasons: []))
    }
    
    func testDecideAll_nilKeys() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKey3 = "common_name"
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = OptimizelyJSON(map: [:])
        let variablesExpected3 = OptimizelyJSON(map: [:])
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: nil)
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: "a",
                                                                ruleKey: nil,
                                                                flagKey: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(enabled: false,
                                                                variables: variablesExpected2,
                                                                variationKey: nil,
                                                                ruleKey: nil,
                                                                flagKey: featureKey2,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(enabled: false,
                                                                variables: variablesExpected3,
                                                                variationKey: nil,
                                                                ruleKey: nil,
                                                                flagKey: featureKey3,
                                                                user: user,
                                                                reasons: []))
    }
    
    func testDecideAll_nilKeys_enabledOnly() {
        let featureKey1 = "feature_1"
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: nil, options: [.enabledOnly])
        
        XCTAssert(decisions.count == 1)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: "a",
                                                                ruleKey: nil,
                                                                flagKey: featureKey1,
                                                                user: user,
                                                                reasons: []))
    }

    
    func testDecideAll_emptyKeys() {
        let featureKeys = [String]()
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 0)
    }
        
}

// MARK: - options

extension OptimizelyClientTests_Decide {
    
    func testDecide_sendImpression_disbleTracking() {
        let featureKey = "feature_1"

        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decision = optimizely.decide(key: featureKey, options: [.disableDecisionEvent])
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(decision.enabled)
        XCTAssertNil(eventDispatcher.eventSent)
    }
    
    func testDecideOptions_useUPSbyDefault() {
        let featureKey = "feature_1"        // embedding experiment: "exp_with_audience"
        let experimentId = "10390977673"    // "exp_with_audience"
        let variationId = "10389729780"

        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        
        XCTAssertNil(getProfileVariation(userId: kUserId, experimentId: experimentId))

        // this will set UPS
        _ = optimizely.decide(key: featureKey)
        
        XCTAssert(getProfileVariation(userId: kUserId, experimentId: experimentId) == variationId)
    }
    
    func testDecideOptions_bypassUPS_doNotUpdateUPS() {
        let featureKey = "feature_1"        // embedding experiment: "exp_with_audience"
        let experimentId = "10390977673"    // "exp_with_audience"

        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        
        XCTAssertNil(getProfileVariation(userId: kUserId, experimentId: experimentId))

        // this will not set UPS because of bypassUPS option
        _ = optimizely.decide(key: featureKey, options: [.ignoreUPS])
        
        XCTAssertNil(getProfileVariation(userId: kUserId, experimentId: experimentId))
    }

    func testDecideOptions_bypassUPS_doNotReadUPS() {
        let featureKey = "feature_1"        // embedding experiment: "exp_with_audience"
        let experimentId = "10390977673"    // "exp_with_audience"
        let variationKey1 = "a"
        let variationKey2 = "b"
        let variationId2 = "10416523121"

        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        
        setProfileVariation(userId: kUserId, experimentId: experimentId, variationId: variationId2)
        XCTAssert(getProfileVariation(userId: kUserId, experimentId: experimentId) == variationId2)

        let decision1 = optimizely.decide(key: featureKey)
        let decision2 = optimizely.decide(key: featureKey, options: [.ignoreUPS])

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
        XCTAssertEqual(decision.flagKey, featureKey)
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
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.user, nil)
        
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.userNotSet.reason)
    }
    
    func testDecide_invalidFeatureKey() {
        let featureKey = "invalid_key"
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        
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
        let featureKey1 = "feature_1"
        let featureKey2 = "invalid_key"

        let featureKeys = [featureKey1, featureKey2]
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        
        let user = OptimizelyUserContext(userId: kUserId)
        optimizely.setUserContext(user)
        let decisions = optimizely.decideAll(keys: featureKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(enabled: true,
                                                                variables: variablesExpected1,
                                                                variationKey: "a",
                                                                ruleKey: nil,
                                                                flagKey: featureKey1,
                                                                user: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision.errorDecision(key: featureKey2,
                                                                              user: user,
                                                                              error: .featureKeyInvalid(featureKey2)))
    }

}

// MARK: - helpers

extension OptimizelyClientTests_Decide {
    func getProfileVariation(userId: String, experimentId: String) -> String? {
        if let profile = decisionService.userProfileService.lookup(userId: userId),
            let bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap,
            let experimentMap = bucketMap[experimentId],
            let variationId = experimentMap[UserProfileKeys.kVariationId] {
            return variationId
        } else {
            return nil
        }
    }
    
    func setProfileVariation(userId: String, experimentId: String, variationId: String){
        var profile = decisionService.userProfileService.lookup(userId: userId) ?? OPTUserProfileService.UPProfile()
        
        var bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
        bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
        
        profile[UserProfileKeys.kBucketMap] = bucketMap
        profile[UserProfileKeys.kUserId] = userId
        
        decisionService.userProfileService.save(userProfile: profile)
    }
}
    
class MockEventDispatcher: OPTEventDispatcher {
    var eventSent: EventForDispatch?
    
    func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        eventSent = event
    }
    
    func flushEvents() {
        
    }
}
