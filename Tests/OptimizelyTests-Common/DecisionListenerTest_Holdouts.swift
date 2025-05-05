//
// Copyright 2022, Optimizely, Inc. and contributors 
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

class DecisionListenerTests_Holdouts: XCTestCase {
    let kUserId = "11111"
    var optimizely: OptimizelyClient!
    var notificationCenter: OPTNotificationCenter!
    var eventDispatcher = MockEventDispatcher()
    
    var kAttributesCountryMatch: [String: Any] = ["country": "US"]
    var kAttributesCountryNotMatch: [String: Any] = ["country": "ca"]
    
    let kFeatureKey = "feature_1"
    let kFeatureId = "4482920077"
    
    let kVariableKeyString = "s_foo"
    let kVariableKeyInt = "i_42"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyBool = "b_true"
    let kVariableKeyJSON = "j_1"
    
    let kVariableValueString = "foo"
    let kVariableValueInt = 42
    let kVariableValueDouble = 4.2
    let kVariableValueBool = true
    
    var sampleHoldout: [String: Any] {
        return [
            "status": "Running",
            "id": "id_holdout",
            "key": "key_holdout",
            "layerId": "10420273888",
            "trafficAllocation": [
                ["entityId": "id_holdout_variation", "endOfRange": 500]
            ],
            "audienceIds": [],
            "variations": [
                [
                    "variables": [],
                    "id": "id_holdout_variation",
                    "key": "key_holdout_variation"
                ]
            ],
            "includedFlags": [],
            "excludedFlags": []
        ]
    }
    
    override func setUp() {
        super.setUp()
        
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("decide_datafile")!)
        
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        //  Audience "13389130056" requires "country" = "US"
        holdout.audienceIds = ["13389130056"]
        
        let mockDecisionService = DefaultDecisionService(userProfileService: OTUtils.createClearUserProfileService(), bucketer: MockBucketer(mockBucketValue: 400))
        optimizely.decisionService = mockDecisionService
        optimizely.config!.project.holdouts = [holdout]
        
        self.notificationCenter = self.optimizely.notificationCenter!
    }
    
    func testDecisionListenerDecideWithUserInHoldout() {
        let exp = expectation(description: "x")
        
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(userId, user.userId)
            XCTAssertEqual(attributes!["country"] as! String, "US")
            
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, "foo")
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "key_holdout_variation")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "key_holdout")
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        
        _ = user.decide(key: self.kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecideWithIncludedFlags() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.includedFlags = [kFeatureId]
        optimizely.config!.project.holdouts = [holdout]
        
        let exp = expectation(description: "x")
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "key_holdout_variation")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "key_holdout")
            exp.fulfill()
        }
        
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecideWithExcludedFlags() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.excludedFlags = [kFeatureId]
        optimizely.config!.project.holdouts = [holdout]
        
        let exp = expectation(description: "x")
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "3324490633")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "3332020515")
            exp.fulfill()
        }
        
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecideWithMultipleHoldouts() {
        var holdout = try! OTUtils.model(from: sampleHoldout) as Holdout
        holdout.excludedFlags = [kFeatureId]
        
        var holdout_2 = holdout
        holdout_2.key = "holdout_key_2"
        holdout_2.id = "holdout_id_2"
        holdout_2.includedFlags = [kFeatureId]
        
        optimizely.config!.project.holdouts = [holdout, holdout_2]
        
        let exp = expectation(description: "x")
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "key_holdout_variation")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "holdout_key_2")
            exp.fulfill()
        }
        
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListener_DecisionEventDispatched_withSendFlagDecisions() {
        let user = optimizely.createUserContext(userId: kUserId, attributes: kAttributesCountryMatch)
        
        // (1) sendFlagDecision = false. feature-test.
        
        optimizely.config?.project.sendFlagDecisions = false
        
        var exp = expectation(description: "x")
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
        
        // (2) sendFlagDecision = true
        
        optimizely.config?.project.sendFlagDecisions = true
        
        exp = expectation(description: "x")
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecide_disableDecisionEvent() {
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        
        // (1) default (send-decision-event)
        
        var exp = expectation(description: "x")
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
        
        // (2) disable-decision-event)
        
        exp = expectation(description: "x")
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, false)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey, options: [.disableDecisionEvent])
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecideForKeys() {
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        
        var count = 0
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(userId, user.userId)
            XCTAssertEqual(attributes!["country"] as! String, "US")
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.flagKey])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.enabled])
            count += 1
        }
        
        _ = user.decide(keys: [kFeatureKey, kFeatureKey, kFeatureKey, kFeatureKey])
        sleep(1)
        
        XCTAssertEqual(count, 4)
    }
    
    func testDecisionListenerDecideAll() {
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        
        var count = 0
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(userId, user.userId)
            XCTAssertEqual(attributes!["country"] as! String, "US")
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.flagKey])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.enabled])
            count += 1
        }
        
        _ = user.decideAll()
        sleep(1)
        
        XCTAssertEqual(count, 3)
    }
}
