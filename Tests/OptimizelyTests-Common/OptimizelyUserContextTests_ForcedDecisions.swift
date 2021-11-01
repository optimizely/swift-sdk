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
    let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
    
    var optimizely: OptimizelyClient!
    var eventDispatcher = MockEventDispatcher()
    var decisionService: DefaultDecisionService!
    var ups: OPTUserProfileService!

    override func setUp() {
        super.setUp()
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        decisionService = (optimizely.decisionService as! DefaultDecisionService)
        ups = decisionService.userProfileService
        try! optimizely.start(datafile: datafile)
    }
    
    func testForcedDecision_returnStatus() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let user = optimizely.createUserContext(userId: kUserId)
        var status: Bool
        var result: OptimizelyForcedDecision?
        
        let context = OptimizelyDecisionContext(flagKey: "feature_1")
        let d = OptimizelyForcedDecision(variationKey: "3324490562")

        try? optimizely.start(datafile: "invalid datafile contents")

        status = user.setForcedDecision(context: context, decision: d)
        XCTAssertFalse(status)
        result = user.getForcedDecision(context: context)
        XCTAssertNil(result)
        status = user.removeForcedDecision(context: context)
        XCTAssertFalse(status)
        status = user.removeAllForcedDecisions()
        XCTAssertFalse(status)

        try? optimizely.start(datafile: datafile)

        status = user.setForcedDecision(context: context, decision: d)
        XCTAssertTrue(status)
        result = user.getForcedDecision(context: context)
        XCTAssert(result!.variationKey == "3324490562")
        status = user.removeForcedDecision(context: context)
        XCTAssertTrue(status)
        status = user.removeAllForcedDecisions()
        XCTAssertTrue(status)
    }
   
    func testSetForcedDecision_flagToDecision() {
        let featureKey = "feature_1"
        let variationKey = "3324490562"
        
        let user = optimizely.createUserContext(userId: kUserId)
        
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey),
                                   decision: OptimizelyForcedDecision(variationKey: variationKey))
        var decision = user.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, variationKey)
        XCTAssertEqual(decision.ruleKey, nil)
        XCTAssertEqual(decision.enabled, true)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext.userId, kUserId)
        XCTAssertEqual(decision.userContext.attributes.count, 0)
        XCTAssertEqual(decision.reasons, [])
        XCTAssertEqual(decision.userContext.forcedDecisions?.count, 1)
        XCTAssertEqual(decision.userContext.forcedDecisions?[OptimizelyDecisionContext(flagKey: featureKey)]!.variationKey, variationKey)

        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecision(kUserId, featureKey, nil, variationKey).reason))
    }
    
    func testSetForcedDecision_experimentRuleToDecision() {
        let featureKey = "feature_1"
        let ruleKey = "exp_with_audience"
        let variationKey = "b"
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["country": "US"])
        
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: ruleKey),
                                   decision: OptimizelyForcedDecision(variationKey: variationKey))
        var decision = user.decide(key: featureKey)
        
        XCTAssertEqual(decision.variationKey, variationKey)
        XCTAssertEqual(decision.ruleKey, ruleKey)
        XCTAssertEqual(decision.enabled, false)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext.userId, kUserId)
        XCTAssertEqual(decision.userContext.attributes.count, 1)
        XCTAssertEqual(decision.reasons, [])
        XCTAssertEqual(decision.userContext.forcedDecisions?.count, 1)
        XCTAssertEqual(decision.userContext.forcedDecisions?[OptimizelyDecisionContext(flagKey: featureKey, ruleKey: ruleKey)]!.variationKey, variationKey)
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecision(kUserId, featureKey, ruleKey, variationKey).reason))
    }
    
    func testSetForcedDecision_deliveryRuleToDecision() {
        let featureKey = "feature_1"
        let ruleKey = "3332020515"
        let variationKey = "3324490633"
        
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: ruleKey),
                                   decision: OptimizelyForcedDecision(variationKey: variationKey))
        var decision = user.decide(key: featureKey)
                
        XCTAssertEqual(decision.variationKey, variationKey)
        XCTAssertEqual(decision.ruleKey, ruleKey)
        XCTAssertEqual(decision.enabled, true)
        XCTAssertEqual(decision.flagKey, featureKey)
        XCTAssertEqual(decision.userContext.userId, kUserId)
        XCTAssertEqual(decision.userContext.attributes.count, 0)
        XCTAssertEqual(decision.reasons, [])
        XCTAssertEqual(decision.userContext.forcedDecisions?.count, 1)
        XCTAssertEqual(decision.userContext.forcedDecisions?[OptimizelyDecisionContext(flagKey: featureKey, ruleKey: ruleKey)]!.variationKey, variationKey)
        
        decision = user.decide(key: featureKey, options: [.includeReasons])
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecision(kUserId, featureKey, ruleKey, variationKey).reason))
    }
    
    func testSetForcedDecision_invalid() {
        let featureKey = "feature_1"
        
        // flag-to-decision
        
        var user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey),
                                   decision: OptimizelyForcedDecision(variationKey: "invalid"))
        var decision = user.decide(key: featureKey, options: [.includeReasons])
        
        // invalid forced-decision will be ignored and regular decision will return
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecisionButInvalid(kUserId, featureKey, nil).reason))
        
        // experiment-rule-to-decision

        user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "exp_with_audience"),
                                   decision: OptimizelyForcedDecision(variationKey: "invalid"))
        decision = user.decide(key: featureKey, options: [.includeReasons])

        // invalid forced-decision will be ignored and regular decision will return
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecisionButInvalid(kUserId, featureKey, "exp_with_audience").reason))

        // delivery-rule-to-decision
        
        user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "3332020515"),
                                   decision: OptimizelyForcedDecision(variationKey: "invalid"))
        decision = user.decide(key: featureKey, options: [.includeReasons])

        // invalid forced-decision will be ignored and regular decision will return
        XCTAssertEqual(decision.variationKey, "18257766532")
        XCTAssertEqual(decision.ruleKey, "18322080788")
        XCTAssert(decision.reasons.contains(LogMessage.userHasForcedDecisionButInvalid(kUserId, featureKey, "3332020515").reason))
    }
    
    func testSetForcedDecision_conflicts() {
        let featureKey = "feature_1"

        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey),
                                   decision: OptimizelyForcedDecision(variationKey: "3324490562"))
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "exp_with_audience"),
                                   decision: OptimizelyForcedDecision(variationKey: "b"))
        let decision = user.decide(key: featureKey)
        
        // flag-to-decision is the 1st priority
        
        XCTAssertEqual(decision.variationKey, "3324490562")
        XCTAssertNil(decision.ruleKey)
    }
    
    func testGetForcedDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        
        var context = OptimizelyDecisionContext(flagKey: featureKey)
        var d = OptimizelyForcedDecision(variationKey: "fv1")
        
        _ = user.setForcedDecision(context: context, decision: d)
        XCTAssertEqual(user.getForcedDecision(context: context)!.variationKey, "fv1")

        context = OptimizelyDecisionContext(flagKey: featureKey)
        d = OptimizelyForcedDecision(variationKey: "fv2")

        _ = user.setForcedDecision(context: context, decision: d)
        XCTAssertEqual(user.getForcedDecision(context: context)!.variationKey, "fv2")

        context = OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "r")
        d = OptimizelyForcedDecision(variationKey: "ev1")

        _ = user.setForcedDecision(context: context, decision: d)
        XCTAssertEqual(user.getForcedDecision(context: context)!.variationKey, "ev1")

        context = OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "r")
        d = OptimizelyForcedDecision(variationKey: "ev2")

        _ = user.setForcedDecision(context: context, decision: d)
        XCTAssertEqual(user.getForcedDecision(context: context)!.variationKey, "ev2")
        
        context = OptimizelyDecisionContext(flagKey: featureKey)
        d = OptimizelyForcedDecision(variationKey: "fv2")

        XCTAssertEqual(user.getForcedDecision(context: context)!.variationKey, "fv2")
    }

    func testRemoveForcedDecision() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        
        let context1 = OptimizelyDecisionContext(flagKey: featureKey)
        let context2 = OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "r")
        let d1 = OptimizelyForcedDecision(variationKey: "fv1")
        let d2 = OptimizelyForcedDecision(variationKey: "ev1")

        _ = user.setForcedDecision(context: context1, decision: d1)
        _ = user.setForcedDecision(context: context2, decision: d2)
        
        XCTAssertEqual(user.getForcedDecision(context: context1)!.variationKey, "fv1")
        XCTAssertEqual(user.getForcedDecision(context: context2)!.variationKey, "ev1")
        
        XCTAssertTrue(user.removeForcedDecision(context: context1))
        XCTAssertNil(user.getForcedDecision(context: context1))
        XCTAssertEqual(user.getForcedDecision(context: context2)!.variationKey, "ev1")

        XCTAssertTrue(user.removeForcedDecision(context: context2))
        XCTAssertNil(user.getForcedDecision(context: context1))
        XCTAssertNil(user.getForcedDecision(context: context2))

        XCTAssertFalse(user.removeForcedDecision(context: context1))  // no more saved decisions
    }
    
    func testRemoveAllForcedDecisions() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        
        let context1 = OptimizelyDecisionContext(flagKey: featureKey)
        let context2 = OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "r")
        let d1 = OptimizelyForcedDecision(variationKey: "fv1")
        let d2 = OptimizelyForcedDecision(variationKey: "ev1")

        _ = user.setForcedDecision(context: context1, decision: d1)
        _ = user.setForcedDecision(context: context2, decision: d2)
        
        XCTAssertEqual(user.getForcedDecision(context: context1)!.variationKey, "fv1")
        XCTAssertEqual(user.getForcedDecision(context: context2)!.variationKey, "ev1")

        XCTAssertTrue(user.removeAllForcedDecisions())
        XCTAssertNil(user.getForcedDecision(context: context1))
        XCTAssertNil(user.getForcedDecision(context: context2))
        XCTAssertFalse(user.removeForcedDecision(context: context1))  // no more saved decisions
    }
    
    // Impression Events
    
    func testSetForcedDecision_flagToDecision_sendImpression() {
        let featureKey = "feature_1"
        let user = optimizely.createUserContext(userId: kUserId)
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey),
                                   decision: OptimizelyForcedDecision(variationKey: "3324490562"))

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
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "exp_with_audience"),
                                   decision: OptimizelyForcedDecision(variationKey: "b"))
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
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "3332020515"),
                                   decision: OptimizelyForcedDecision(variationKey: "3324490633"))
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
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey),
                                   decision: OptimizelyForcedDecision(variationKey: "3324490562"))
        
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
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "exp_with_audience"),
                                   decision: OptimizelyForcedDecision(variationKey: "b"))
        
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
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: featureKey, ruleKey: "3332020515"),
                                   decision: OptimizelyForcedDecision(variationKey: "3324490633"))
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
    
    func testAccessForcedDecisionBeforeSet() {
        let user = optimizely.createUserContext(userId: kUserId)
        XCTAssertNil(user.forcedDecisions)
        XCTAssertNil(user.getForcedDecision(context: OptimizelyDecisionContext(flagKey: "a")))
        XCTAssertFalse(user.removeForcedDecision(context: OptimizelyDecisionContext(flagKey: "a")))
        XCTAssertTrue(user.removeAllForcedDecisions())    // removeAll always returns true
        XCTAssertNil(user.findForcedDecision(context: OptimizelyDecisionContext(flagKey: "a")))
        XCTAssertNil(user.findValidatedForcedDecision(context: OptimizelyDecisionContext(flagKey: "a",ruleKey: "b")).result)
    }
    
    func testClone() {
        let user = optimizely.createUserContext(userId: kUserId, attributes: ["country": "us"])
        
        // clone with empty ForcedDecisions
        
        guard let user2 = user.clone else {
            XCTFail()
            return
        }
        XCTAssertEqual(user2.userId, kUserId)
        XCTAssertEqual(user2.attributes["country"] as? String, "us")
        XCTAssertNil(user2.forcedDecisions)
        
        // clone with non-empty ForcedDecisions
        
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: "a"), decision: OptimizelyForcedDecision(variationKey: "b"))
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: "a", ruleKey: "c"), decision: OptimizelyForcedDecision(variationKey: "d"))
        
        guard let user3 = user.clone else {
            XCTFail()
            return
        }
        XCTAssertEqual(user3.userId, kUserId)
        XCTAssertEqual(user3.attributes["country"] as? String, "us")
        XCTAssertNotNil(user3.forcedDecisions)
        XCTAssertEqual(user3.getForcedDecision(context: OptimizelyDecisionContext(flagKey: "a"))!.variationKey, "b")
        XCTAssertEqual(user3.getForcedDecision(context: OptimizelyDecisionContext(flagKey: "a", ruleKey: "c"))!.variationKey, "d")
        XCTAssertNil(user3.getForcedDecision(context: OptimizelyDecisionContext(flagKey: "x")))
        
        // clone should have a separate copy for FocedDecisions
        
        _ = user.setForcedDecision(context: OptimizelyDecisionContext(flagKey: "a", ruleKey: "new-rk"), decision: OptimizelyForcedDecision(variationKey: "new-vk"))
        XCTAssertEqual(user.getForcedDecision(context: OptimizelyDecisionContext(flagKey: "a", ruleKey: "new-rk"))!.variationKey, "new-vk")
        XCTAssertNil(user3.getForcedDecision(context: OptimizelyDecisionContext(flagKey: "a", ruleKey: "new-rk")))
    }

}

