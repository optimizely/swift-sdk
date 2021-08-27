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

class OptimizelyUserContextTests_ForcedDecisions: XCTestCase {

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
   
    func testSetForcedDecision_flagToDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   variationKey: "3324490562")
        var decision = user.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, "3324490562")
        XCTAssertEqual(decision.ruleKey, nil)
        XCTAssertEqual(decision.enabled, true)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext.userId, kUserId)
        XCTAssertEqual(decision.userContext.attributes.count, 0)
        XCTAssertEqual(decision.reasons, [])
        XCTAssertEqual(decision.userContext.forcedDecisions.count, 1)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].flagKey, featureKey)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].ruleKey, nil)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].variationKey, "3324490562")

        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecision(kUserId, featureKey, nil, "3324490562").reason))
    }
    
    func testSetForcedDecision_experimentRuleToDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["country": "US"])
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "exp_with_audience",
                                   variationKey: "b")
        var decision = user.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, "b")
        XCTAssertEqual(decision.ruleKey, "exp_with_audience")
        XCTAssertEqual(decision.enabled, false)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext.userId, kUserId)
        XCTAssertEqual(decision.userContext.attributes.count, 1)
        XCTAssertEqual(decision.reasons, [])
        XCTAssertEqual(decision.userContext.forcedDecisions.count, 1)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].flagKey, featureKey)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].ruleKey, "exp_with_audience")
        XCTAssertEqual(decision.userContext.forcedDecisions[0].variationKey, "b")
        
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecision(kUserId, featureKey, "exp_with_audience", "b").reason))
    }
    
    func testSetForcedDecision_deliveryRuleToDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "3332020515",
                                   variationKey: "3324490633")
        var decision = user.decide(key: featureKey)
                
        XCTAssertEqual(decision.variationKey, "3324490633")
        XCTAssertEqual(decision.ruleKey, "3332020515")
        XCTAssertEqual(decision.enabled, true)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext.userId, kUserId)
        XCTAssertEqual(decision.userContext.attributes.count, 0)
        XCTAssertEqual(decision.reasons, [])
        XCTAssertEqual(decision.userContext.forcedDecisions.count, 1)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].flagKey, featureKey)
        XCTAssertEqual(decision.userContext.forcedDecisions[0].ruleKey, "3332020515")
        XCTAssertEqual(decision.userContext.forcedDecisions[0].variationKey, "3324490633")
        
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecision(kUserId, featureKey, "3332020515", "3324490633").reason))
    }
    
    func testSetForcedDecision_invalid() {
        let featureKey = "feature_1"

        // flag-to-decision
        
        var user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   variationKey: "invalid")
        var decision = user.decide(key: featureKey, options: [.includeReasons])
        
        // invalid forced-decision will be ignored and regular decision will return
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecisionButInvalid(kUserId, featureKey, nil).reason))
        
        // experiment-rule-to-decision

        user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "exp_with_audience",
                                   variationKey: "invalid")
        decision = user.decide(key: featureKey, options: [.includeReasons])

        // invalid forced-decision will be ignored and regular decision will return
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecisionButInvalid(kUserId, featureKey, "exp_with_audience").reason))

        // delivery-rule-to-decision
        
        user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "3332020515",
                                   variationKey: "invalid")
        decision = user.decide(key: featureKey, options: [.includeReasons])

        // invalid forced-decision will be ignored and regular decision will return
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecisionButInvalid(kUserId, featureKey, "3332020515").reason))
    }
    
    func testSetForcedDecision_conflicts() {
        let featureKey = "feature_1"

        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   variationKey: "3324490562")
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "exp_with_audience",
                                   variationKey: "b")
        let decision = user.decide(key: featureKey)
        
        // flag-to-decision is the 1st priority
        
        XCTAssertEqual(decision.variationKey, "3324490562")
        XCTAssertNil(decision.ruleKey)
    }
    
    func testGetForcedDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        
        _ = user.setForcedDecision(flagKey: featureKey, variationKey: "fv1")
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey), "fv1")

        _ = user.setForcedDecision(flagKey: featureKey, variationKey: "fv2")
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey), "fv2")
        
        _ = user.setForcedDecision(flagKey: featureKey, ruleKey: "r", variationKey: "ev1")
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"), "ev1")

        _ = user.setForcedDecision(flagKey: featureKey, ruleKey: "r", variationKey: "ev2")
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"), "ev2")
        
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey), "fv2")
    }

    func testRemoveForcedDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        
        _ = user.setForcedDecision(flagKey: featureKey, variationKey: "fv1")
        _ = user.setForcedDecision(flagKey: featureKey, ruleKey: "r", variationKey: "ev1")
        
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey), "fv1")
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"), "ev1")
        
        XCTAssertTrue(user.removeForcedDecision(flagKey: featureKey))
        XCTAssertNil(user.getForcedDecision(flagKey: featureKey))
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"), "ev1")

        XCTAssertTrue(user.removeForcedDecision(flagKey: featureKey, ruleKey: "r"))
        XCTAssertNil(user.getForcedDecision(flagKey: featureKey))
        XCTAssertNil(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"))

        XCTAssertFalse(user.removeForcedDecision(flagKey: featureKey))  // no more saved decisions
    }
    
    func testRemoveAllForcedDecisions() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        
        _ = user.setForcedDecision(flagKey: featureKey, variationKey: "fv1")
        _ = user.setForcedDecision(flagKey: featureKey, ruleKey: "r", variationKey: "ev1")
        
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey), "fv1")
        XCTAssertEqual(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"), "ev1")

        XCTAssertTrue(user.removeAllForcedDecisions())
        XCTAssertNil(user.getForcedDecision(flagKey: featureKey))
        XCTAssertNil(user.getForcedDecision(flagKey: featureKey, ruleKey: "r"))
        XCTAssertFalse(user.removeForcedDecision(flagKey: featureKey))  // no more saved decisions
    }
    
    // Impression Events
    
    func testSetForcedDecision_flagToDecision_sendImpression() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   variationKey: "3324490562")

        // no impression event
        
        _ = user.decide(key: featureKey, options: [.disableDecisionEvent])

        optimizely.eventLock.sync{}
        XCTAssert(eventDispatcher.events.isEmpty)

        // impression event for forced-decision
        
        _ = user.decide(key: featureKey)

        optimizely.eventLock.sync{}
                
        let eventSent = eventDispatcher.events.first!
        let event = try! JSONDecoder().decode(BatchEvent.self, from: eventSent.body)
        let eventDecision: Decision = event.visitors[0].snapshots[0].decisions![0]
        let metadata = eventDecision.metaData
        
        let desc = eventSent.description
        XCTAssert(desc.contains("campaign_activated"))
        
        XCTAssertEqual(eventDecision.experimentID, "")
        XCTAssertEqual(eventDecision.variationID, "3324490562")
        
        XCTAssertEqual(metadata.flagKey, "feature_1")
        XCTAssertEqual(metadata.ruleKey, "")
        XCTAssertEqual(metadata.ruleType, "feature-test")
        XCTAssertEqual(metadata.variationKey, "3324490562")
        XCTAssertEqual(metadata.enabled, true)
    }
    
    func testSetForcedDecision_experimentRuleToDecision_sendImpression() {
        let featureKey = "feature_1"
        
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "exp_with_audience",
                                   variationKey: "b")
        _ = user.decide(key: featureKey)

        optimizely.eventLock.sync{}
                
        let eventSent = eventDispatcher.events.first!
        let event = try! JSONDecoder().decode(BatchEvent.self, from: eventSent.body)
        let eventDecision: Decision = event.visitors[0].snapshots[0].decisions![0]
        let metadata = eventDecision.metaData
        
        let desc = eventSent.description
        XCTAssert(desc.contains("campaign_activated"))
        
        XCTAssertEqual(eventDecision.experimentID, "10390977673")
        XCTAssertEqual(eventDecision.variationID, "10416523121")
        
        XCTAssertEqual(metadata.flagKey, "feature_1")
        XCTAssertEqual(metadata.ruleKey, "exp_with_audience")
        XCTAssertEqual(metadata.ruleType, "feature-test")
        XCTAssertEqual(metadata.variationKey, "b")
        XCTAssertEqual(metadata.enabled, false)
    }

    func testSetForcedDecision_deliveryRuleToDecision_sendImpression() {
        let featureKey = "feature_1"
        
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "3332020515",
                                   variationKey: "3324490633")
        _ = user.decide(key: featureKey)

        optimizely.eventLock.sync{}
                
        let eventSent = eventDispatcher.events.first!
        let event = try! JSONDecoder().decode(BatchEvent.self, from: eventSent.body)
        let eventDecision: Decision = event.visitors[0].snapshots[0].decisions![0]
        let metadata = eventDecision.metaData
        
        let desc = eventSent.description
        XCTAssert(desc.contains("campaign_activated"))
        
        XCTAssertEqual(eventDecision.experimentID, "3332020515")
        XCTAssertEqual(eventDecision.variationID, "3324490633")
        
        XCTAssertEqual(metadata.flagKey, "feature_1")
        XCTAssertEqual(metadata.ruleKey, "3332020515")
        XCTAssertEqual(metadata.ruleType, "rollout")
        XCTAssertEqual(metadata.variationKey, "3324490633")
        XCTAssertEqual(metadata.enabled, true)
    }

    // Notifications
    
    func testSetForcedDecision_flagToDecision_notification() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   variationKey: "3324490562")
        
        let exp = expectation(description: "a")
        
        optimizely.notificationCenter?.clearAllNotificationListeners()
        _ = optimizely.notificationCenter?.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, "feature_1")
            XCTAssert(decisionInfo[Constants.DecisionInfoKeys.ruleKey] is NSNull)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "3324490562")
            exp.fulfill()
        }
        
        _ = user.decide(key: featureKey)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testSetForcedDecision_experimentRuleToDecision_notification() {
        let featureKey = "feature_1"
        
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "exp_with_audience",
                                   variationKey: "b")
        
        let exp = expectation(description: "a")
        
        optimizely.notificationCenter?.clearAllNotificationListeners()
        _ = optimizely.notificationCenter?.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, "feature_1")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "b")
            exp.fulfill()
        }
        
        _ = user.decide(key: featureKey)
        
        wait(for: [exp], timeout: 1)
    }

    func testSetForcedDecision_deliveryRuleToDecision_notification() {
        let featureKey = "feature_1"
        
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(flagKey: featureKey,
                                   ruleKey: "3332020515",
                                   variationKey: "3324490633")
        let exp = expectation(description: "a")
        
        optimizely.notificationCenter?.clearAllNotificationListeners()
        _ = optimizely.notificationCenter?.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, "feature_1")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "3332020515")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "3324490633")
            exp.fulfill()
        }
        
        _ = user.decide(key: featureKey)
        
        wait(for: [exp], timeout: 1)
    }

}

