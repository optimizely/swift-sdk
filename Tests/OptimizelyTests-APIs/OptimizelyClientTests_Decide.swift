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
        let expOptions: [OptimizelyDecideOption] = [.ignoreUPS,
                                                    .disableDecisionEvent,
                                                    .enabledOnly,
                                                    .includeReasons]
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        XCTAssert(optimizely.defaultDecideOptions.count == 0)

        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      defaultDecideOptions: expOptions)
        XCTAssert(optimizely.defaultDecideOptions == expOptions)
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
