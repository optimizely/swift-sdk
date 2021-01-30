/****************************************************************************
 * Copyright 2021, Optimizely, Inc. and contributors                        *
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

class OptimizelyUserContextTests_Decide: XCTestCase {

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
   
    func testCreateUserContext() {
        let userId = "tester"
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        
        let user = optimizely.createUserContext(userId: "tester", attributes: attributes)
        
        XCTAssert(user.optimizely == optimizely)
        XCTAssert(user.userId == userId)
        XCTAssert(user.attributes["country"] as! String == "us")
        XCTAssert(user.attributes["age"] as! Int == 100)
        XCTAssert(user.attributes["old"] as! Bool == true)
    }
    
    func testCreateUserContext_multiple() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user1 = optimizely.createUserContext(userId: "tester1", attributes: attributes)
        let user2 = optimizely.createUserContext(userId: "tester2", attributes: [:])
        
        XCTAssert(user1.userId == "tester1")
        XCTAssert(user2.userId == "tester2")
    }
    
    func testDefaultDecideOptions() {
        let expOptions: [OptimizelyDecideOption] = [.ignoreUserProfileService,
                                                    .disableDecisionEvent,
                                                    .enabledFlagsOnly,
                                                    .includeReasons,
                                                    .excludeVariables]
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        XCTAssert(optimizely.defaultDecideOptions.count == 0)

        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      defaultDecideOptions: expOptions)
        XCTAssert(optimizely.defaultDecideOptions == expOptions)
    }
    
}

// MARK: - decide

extension OptimizelyUserContextTests_Decide {

    func testDecide() {
        let featureKey = "feature_2"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)

        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertTrue(decision.enabled)
        XCTAssertTrue(NSDictionary(dictionary: decision.variables.toMap()).isEqual(to: variablesExpected.toMap()))
        XCTAssertEqual(decision.ruleKey, "exp_no_audience")
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext, user)
        XCTAssert(decision.reasons.isEmpty)
    }
    
}

// MARK: - impression events

extension OptimizelyUserContextTests_Decide {
    
    // NOTE: we here validate impression events only.
    //       all decision-notification tests are in "OptimizelyTests-Common/DecisionListenerTests"
    
    func testDecide_sendImpression() {
        let featureKey = "feature_2"

        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertEqual(decision.variationKey, "variation_with_traffic")
        XCTAssertTrue(decision.enabled)
        XCTAssertNotNil(eventDispatcher.eventSent)
        
        let eventSent = eventDispatcher.eventSent!
        let event = try! JSONDecoder().decode(BatchEvent.self, from: eventSent.body)
        let eventDecision: Decision = event.visitors[0].snapshots[0].decisions![0]
        let metadata = eventDecision.metaData

        let desc = eventDispatcher.eventSent!.description
        XCTAssert(desc.contains("campaign_activated"))
        
        XCTAssertEqual(eventDecision.experimentID, "10420810910")
        XCTAssertEqual(eventDecision.variationID, "10418551353")

        XCTAssertEqual(metadata.flagKey, "feature_2")
        XCTAssertEqual(metadata.ruleKey, "exp_no_audience")
        XCTAssertEqual(metadata.ruleType, "feature-test")
        XCTAssertEqual(metadata.variationKey, "variation_with_traffic")
        XCTAssertEqual(metadata.enabled, true)
    }
    
    func testDecide_sendImpressionForNullVariation() {
        let featureKey = "feature_3"

        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(eventDispatcher.eventSent)
        
        let eventSent = eventDispatcher.eventSent!
        let event = try! JSONDecoder().decode(BatchEvent.self, from: eventSent.body)
        let eventDecision: Decision = event.visitors[0].snapshots[0].decisions![0]
        let metadata = eventDecision.metaData
        
        let desc = eventDispatcher.eventSent!.description
        XCTAssert(desc.contains("campaign_activated"))
        
        XCTAssertEqual(eventDecision.variationID, "")
        XCTAssertEqual(eventDecision.experimentID, "")

        XCTAssertEqual(metadata.flagKey, "feature_3")
        XCTAssertEqual(metadata.ruleKey, "")
        XCTAssertEqual(metadata.ruleType, "rollout")
        XCTAssertEqual(metadata.variationKey, "")
        XCTAssertEqual(metadata.enabled, false)
    }
    
    func testDecideError_doNotSendImpression() {
        let featureKey = "invalid"   // invalid flag

        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNil(decision.variationKey)
        XCTAssertFalse(decision.enabled)
        XCTAssertNil(eventDispatcher.eventSent)
    }

    // sendFlagDecisions = false
    
    func testDecide_sendImpression_withSendFlagDecisionsOff() {
        optimizely.config?.project.sendFlagDecisions = false

        let featureKey = "feature_2"

        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}

        XCTAssertNotNil(eventDispatcher.eventSent)
    }

    func testDecide_shouldNotSendImpressionForRollout_withSendFlagDecisionsOff() {
        optimizely.config?.project.sendFlagDecisions = false
        
        let featureKey = "feature_3"
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.decide(key: featureKey)
        
        optimizely.eventLock.sync{}
        
        XCTAssertNil(eventDispatcher.eventSent)
    }

}

// MARK: - decideForKeys API

extension OptimizelyUserContextTests_Decide {

    func testDecideForKeys_oneFeature() {
        let featureKey = "feature_2"
        let featureKeys = [featureKey]
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        let user = optimizely.createUserContext(userId: kUserId)
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 1)
        let decision = decisions[featureKey]!
        
        let expDecision = OptimizelyDecision(variationKey: "variation_with_traffic",
                                             enabled: true,
                                             variables: variablesExpected,
                                             ruleKey: "exp_no_audience",
                                             flagKey: featureKey,
                                             userContext: user,
                                             reasons: [])
        XCTAssertEqual(decision, expDecision)
    }
    
    func testDecideForKeys_twoFeatures() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        
        let featureKeys = [featureKey1, featureKey2]
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "a",
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                ruleKey: "exp_with_audience",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                ruleKey: "exp_no_audience",
                                                                flagKey: featureKey2,
                                                                userContext: user,
                                                                reasons: []))
    }
    
    func testDecideForKeys_emptyKeys() {
        let featureKeys = [String]()
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 0)
    }
        
}

// MARK: - decideAll API

extension OptimizelyUserContextTests_Decide {
    
    func testDecideAll() {
        let featureKey1 = "feature_1"
        let featureKey2 = "feature_2"
        let featureKey3 = "feature_3"
        
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        let variablesExpected2 = try! optimizely.getAllFeatureVariables(featureKey: featureKey2, userId: kUserId)
        let variablesExpected3 = OptimizelyJSON.createEmpty()
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll()
        
        XCTAssert(decisions.count == 3)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "a",
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                ruleKey: "exp_with_audience",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                enabled: true,
                                                                variables: variablesExpected2,
                                                                ruleKey: "exp_no_audience",
                                                                flagKey: featureKey2,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey3]! == OptimizelyDecision(variationKey: nil,
                                                                enabled: false,
                                                                variables: variablesExpected3,
                                                                ruleKey: nil,
                                                                flagKey: featureKey3,
                                                                userContext: user,
                                                                reasons: []))
    }
    
    func testDecideAll_enabledOnly() {
        let featureKey1 = "feature_1"
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["gender": "f"])
        let decisions = user.decideAll(options: [.enabledFlagsOnly])
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "a",
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                ruleKey: "exp_with_audience",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
    }

}

// MARK: - options

extension OptimizelyUserContextTests_Decide {
    
    func testDecide_sendImpression_disbleTracking() {
        let featureKey = "feature_2"

        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey, options: [.disableDecisionEvent])
        
        optimizely.eventLock.sync{}

        XCTAssertTrue(decision.enabled)
        XCTAssertNil(eventDispatcher.eventSent)
    }
    
    func testDecideOptions_useUPSbyDefault() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"
        let variationId = "10418551353"

        let user = optimizely.createUserContext(userId: kUserId)
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))

        // this will set UPS
        _ = user.decide(key: featureKey)
        
        XCTAssert(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId) == variationId)
    }
    
    func testDecideOptions_bypassUPS_doNotUpdateUPS() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"

        let user = optimizely.createUserContext(userId: kUserId)

        XCTAssertNil(getProfileVariation(userId: kUserId, experimentId: experimentId))

        // this will not set UPS because of bypassUPS option
        _ = user.decide(key: featureKey, options: [.ignoreUserProfileService])
        
        XCTAssertNil(OTUtils.getVariationFromUPS(ups: ups, userId: kUserId, experimentId: experimentId))
    }

    func testDecideOptions_bypassUPS_doNotReadUPS() {
        let featureKey = "feature_2"        // embedding experiment: "exp_no_audience"
        let experimentId = "10420810910"    // "exp_no_audience"
        let variationKey1 = "variation_with_traffic"
        let variationKey2 = "variation_no_traffic"
        let variationId2 = "10418510624"

        let user = optimizely.createUserContext(userId: kUserId)

        setProfileVariation(userId: kUserId, experimentId: experimentId, variationId: variationId2)
        XCTAssert(getProfileVariation(userId: kUserId, experimentId: experimentId) == variationId2)

        let decision1 = user.decide(key: featureKey)
        let decision2 = user.decide(key: featureKey, options: [.ignoreUserProfileService])

        XCTAssert(decision1.variationKey == variationKey2)
        XCTAssert(decision2.variationKey == variationKey1)
    }
    
    func testDecide_excludeVariables() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)

        let user = optimizely.createUserContext(userId: kUserId)
        
        var decision = user.decide(key: featureKey)
        XCTAssertTrue(NSDictionary(dictionary: decision.variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        decision = user.decide(key: featureKey, options: [.excludeVariables])
        XCTAssertTrue(decision.variables.isEmpty)
    }
    
    func testDecide_defaultDecideOption() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)

        var user = optimizely.createUserContext(userId: kUserId)
        var decision = user.decide(key: featureKey)
        XCTAssertTrue(NSDictionary(dictionary: decision.variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        // new optimizley instance with defaultDecideOptions and a new user-context
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      defaultDecideOptions: [.excludeVariables])
        try! optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)
        decision = user.decide(key: featureKey)
        XCTAssertTrue(decision.variables.isEmpty)
    }

}
    
// MARK: - debugging reasons
  
extension OptimizelyUserContextTests_Decide {

}

// MARK: - errors
  
extension OptimizelyUserContextTests_Decide {
    
    func testDecide_sdkNotReady() {
        let featureKey = "feature_1"
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())

        let user = optimizely.createUserContext(userId: kUserId)
        let decision = user.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertFalse(decision.enabled)
        XCTAssertTrue(decision.variables.isEmpty)
        XCTAssertNil(decision.ruleKey)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext, user)
        
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.sdkNotReady.reason)
    }
    
    func testDecide_sdkNotReady_optimizelyReleased() {
        let featureKey = "feature_1"

        var optimizelyClient: OptimizelyClient! = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        try! optimizelyClient.start(datafile: datafile)

        let user = optimizelyClient.createUserContext(userId: kUserId)
        
        // optimizelyClient released and the weak ref in userContext will become nil
        optimizelyClient = nil
        let decision = user.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.sdkNotReady.reason)
    }

    func testDecide_invalidFeatureKey() {
        let featureKey = "invalid_key"

        let user = optimizely.createUserContext(userId: kUserId)

        let decision = user.decide(key: featureKey)

        XCTAssertNil(decision.variationKey)
        XCTAssertFalse(decision.enabled)
        XCTAssertTrue(decision.variables.isEmpty)
        XCTAssertNil(decision.ruleKey)
        XCTAssert(decision.reasons.count == 1)
        XCTAssert(decision.reasons.first == OptimizelyError.featureKeyInvalid(featureKey).reason)
    }
        
    // decideForKeys
    
    func testDecideForKeys_sdkNotReady() {
        let featureKeys = ["feature_1"]
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 0)
    }
    
    func testDecideForKeys_sdkNotReady_optimizelyReleased() {
        let featureKeys = ["feature_1"]

        var optimizelyClient: OptimizelyClient! = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        try! optimizelyClient.start(datafile: datafile)

        let user = optimizelyClient.createUserContext(userId: kUserId)
        
        // optimizelyClient released and the weak ref in userContext will become nil
        optimizelyClient = nil
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 0)
    }
    
    func testDecideForKeys_errorDecisionIncluded() {
        let featureKey1 = "feature_2"
        let featureKey2 = "invalid_key"

        let featureKeys = [featureKey1, featureKey2]
        let variablesExpected1 = try! optimizely.getAllFeatureVariables(featureKey: featureKey1, userId: kUserId)
        
        let user = optimizely.createUserContext(userId: kUserId)
        let decisions = user.decide(keys: featureKeys)
        
        XCTAssert(decisions.count == 2)
        
        XCTAssert(decisions[featureKey1]! == OptimizelyDecision(variationKey: "variation_with_traffic",
                                                                enabled: true,
                                                                variables: variablesExpected1,
                                                                ruleKey: "exp_no_audience",
                                                                flagKey: featureKey1,
                                                                userContext: user,
                                                                reasons: []))
        XCTAssert(decisions[featureKey2]! == OptimizelyDecision.errorDecision(key: featureKey2,
                                                                              user: user,
                                                                              error: .featureKeyInvalid(featureKey2)))
    }

}

// MARK: - helpers

extension OptimizelyUserContextTests_Decide {
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
