//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

class DecisionListenerTests: XCTestCase {
    
    // MARK: - Constants
    
    let kFeatureKey = "feature_1"
    let kUserId = "11111"
    
    let kVariableKeyString = "s_foo"
    let kVariableKeyInt = "i_42"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyBool = "b_true"
    let kVariableKeyJSON = "j_1"
    
    let kVariableValueString = "foo"
    let kVariableValueInt = 42
    let kVariableValueDouble = 4.2
    let kVariableValueBool = true
    
    // MARK: - Properties
    
    var datafile: Data!
    var optimizely: FakeManager!
    let eventDispatcher = MockEventDispatcher()
    var notificationCenter: OPTNotificationCenter!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = FakeManager(sdkKey: "12345",
                                      eventDispatcher: eventDispatcher,
                                      userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
        self.notificationCenter = self.optimizely.notificationCenter!
    }
    
    func testDecisionListenerParameters() {
        var count = 0
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, "feature")
            XCTAssertEqual(userId, self.kUserId)
            XCTAssert(attributes!.isEmpty)   // [:]
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.feature])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.featureEnabled])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.source])
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            count += 1
        }
        
        _ = optimizely.getEnabledFeatures(userId: kUserId)
        sleep(1)
        
        XCTAssertEqual(count, 2)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
       }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableJSONWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual((decisionInfo[Constants.DecisionInfoKeys.variableValue] as! [String: Any])["value"] as! Int, 1)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, Constants.VariableValueType.json.rawValue)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
       }
        _ = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetAllFeatureVariablesWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, _, _, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.allFeatureVariables.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variableValues])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variableValues] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey,
                                                        userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserInRollout() {
        var exp = expectation(description: "x")

        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689660112", value: "false"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserInRollout() {
        var exp = expectation(description: "x")
        
        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689280165", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserInRollout() {
        var exp = expectation(description: "x")

        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2687470095", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserInRollout() {
        var exp = expectation(description: "x")

        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "123")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableJSONWithUserInRollout() {
        var exp = expectation(description: "x")

        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150067", value: "{\"value\":2}"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual((decisionInfo[Constants.DecisionInfoKeys.variableValue] as! [String: Any])["value"] as! Int, 2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, Constants.VariableValueType.json.rawValue)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertEqual((decisionInfo[Constants.DecisionInfoKeys.variableValue] as! [String: Any])["value"] as! Int, 1)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, Constants.VariableValueType.json.rawValue)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetAllFeatureVariablesWithUserInRollout() {
        var exp = expectation(description: "x")
        
        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variableValues])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variableValues] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, "123")
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
        
        exp = expectation(description: "x")
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variableValues])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variableValues] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetAllFeatureVariablesWithInvalidType() {
        let exp = expectation(description: "x")
        
        for (index, featureFlag) in self.optimizely.config!.project!.featureFlags.enumerated() {
            if featureFlag.key == kFeatureKey {
                var flag = featureFlag
                flag.variables.append(FeatureVariable(id: "2689660112",
                                                      key: "b_true",
                                                      type: "invalid",
                                                      subType: nil,
                                                      defaultValue: "true"))
                self.optimizely.config?.project.featureFlags[index] = flag
                break
            }
        }
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variableValues])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variableValues] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! String, "true")
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689660112", value: "false"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689280165", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2687470095", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "123")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetFeatureVariableJSONWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150067", value: "{\"value\":2}"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual((decisionInfo[Constants.DecisionInfoKeys.variableValue] as! [String: Any])["value"] as! Int, 2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, Constants.VariableValueType.json.rawValue)
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertEqual((decisionInfo[Constants.DecisionInfoKeys.variableValue] as! [String: Any])["value"] as! Int, 1)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, Constants.VariableValueType.json.rawValue)
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey, variableKey: kVariableKeyJSON, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerGetAllFeatureVariablesWithUserInExperiment() {
        var exp = expectation(description: "x")
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variableValues])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variableValues] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, "123")
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
        
        exp = expectation(description: "x")
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variableValues])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variableValues] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
            exp.fulfill()
        }
        _ = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerForGetEnabledFeatures() {
        var count = 0
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.feature])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.featureEnabled])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.source])
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            count += 1
        }
        
        _ = optimizely.getEnabledFeatures(userId: kUserId)
        sleep(1)
        
        XCTAssertEqual(count, 2)
    }
    
    func testDecisionListenerWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerWithUserInRollout() {
        var exp = expectation(description: "x")
        
        let experiment: Experiment = self.optimizely.config!.allExperiments.first!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)

        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout.rawValue)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
            exp.fulfill()
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first!)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, experiment.key)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, variation.key)
            exp.fulfill()
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
        
        exp = expectation(description: "x")

        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest.rawValue)
            let sourceInfo: [String: Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String: Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, experiment.key)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, variation.key)
            exp.fulfill()
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        wait(for: [exp], timeout: 1)
    }
    
}
    
// MARK: - decide apis
    
extension DecisionListenerTests {
    
    func testDecisionListenerDecideWithUserInExperiment_featureEnabled() {
        let exp = expectation(description: "x")

        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(userId, user.userId)
            XCTAssertEqual(attributes!["country"] as! String, "US")
            
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, true)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, "123")
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)

            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "a")  //exp = "exp_with_audience"
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "exp_with_audience")
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecideWithUserInExperiment_featureDisabled() {
        let exp = expectation(description: "x")

        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)

            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "a")  //exp = "exp_with_audience"
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "exp_with_audience")
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListenerDecideWithUserNotInExperimentAndRollout() {
        let exp = expectation(description: "x")
        
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(type, Constants.DecisionType.flag.rawValue)
            XCTAssertEqual(userId, user.userId)
            XCTAssertEqual(attributes!["country"] as! String, "US")

            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)

            XCTAssert(decisionInfo[Constants.DecisionInfoKeys.variationKey] is NSNull)
            XCTAssert(decisionInfo[Constants.DecisionInfoKeys.ruleKey] is NSNull)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, false)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)

        wait(for: [exp], timeout: 1)
    }
    
    func testDecisionListener_DecisionEventDispatched_withSendFlagDecisions() {
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        
        // set for feature-test
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        
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
        
        // (2) sendFlagDecision = true. feature-test.

        optimizely.config?.project.sendFlagDecisions = true

        exp = expectation(description: "x")
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)

        // set for rollout (null variation)
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil, source: Constants.DecisionSource.rollout.rawValue)

        // (3) sendFlagDecisions = false. rollout.
        
        optimizely.config?.project.sendFlagDecisions = false

        exp = expectation(description: "x")
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, false)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)

        // (3) sendFlagDecisions = true. rollout.
        
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

    func testDecisionListenerDecide_featureEnabled() {
        let exp = expectation(description: "x")
        
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, true)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, "123")
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)

            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "a")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "exp_with_audience")
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, true)
            exp.fulfill()
        }
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
        
    }
    
    func testDecisionListenerDecide_featureDisabled() {
        let exp = expectation(description: "x")
        
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! Bool, self.kVariableValueBool)
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)

            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variationKey] as! String, "a")  //exp = "exp_with_audience"
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.ruleKey] as! String, "exp_with_audience")
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
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

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        let variation: Variation = (experiment.variations.first)!
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        
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

    func testDecisionListenerDecideWithInvalidType() {
        let exp = expectation(description: "x")
        
        let user = optimizely.createUserContext(userId: kUserId, attributes:["country": "US"])

        for (index, featureFlag) in self.optimizely.config!.project!.featureFlags.enumerated() {
            if featureFlag.key == kFeatureKey {
                var flag = featureFlag
                flag.variables.append(FeatureVariable(id: "2689660112",
                                                      key: kVariableKeyBool,
                                                      type: "invalid",
                                                      subType: nil,
                                                      defaultValue: "true"))
                self.optimizely.config?.project.featureFlags[index] = flag
                break
            }
        }
                
        notificationCenter.clearAllNotificationListeners()
        _ = notificationCenter.addDecisionNotificationListener { (_, _, _, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.flagKey] as! String, self.kFeatureKey)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.enabled] as! Bool, false)
            
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.variables])
            let variableValues = decisionInfo[Constants.DecisionInfoKeys.variables] as! [String: Any]
            XCTAssertEqual(variableValues[self.kVariableKeyString] as! String, self.kVariableValueString)
            XCTAssertEqual(variableValues[self.kVariableKeyInt] as! Int, self.kVariableValueInt)
            XCTAssertEqual(variableValues[self.kVariableKeyDouble] as! Double, self.kVariableValueDouble)
            XCTAssertEqual(variableValues[self.kVariableKeyBool] as! String, "true")
            let jsonMap = (variableValues[self.kVariableKeyJSON] as! [String: Any])
            XCTAssertEqual(jsonMap["value"] as! Int, 1)

            XCTAssert(decisionInfo[Constants.DecisionInfoKeys.variationKey] is NSNull)
            XCTAssert(decisionInfo[Constants.DecisionInfoKeys.ruleKey] is NSNull)
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.reasons])
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] as! Bool, false)
            exp.fulfill()
        }
        
        _ = user.decide(key: kFeatureKey)
        wait(for: [exp], timeout: 1)
    }
    
    // MARK: - decide-all api
    
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
        
        XCTAssertEqual(count, 2)
    }
    
}

class FakeManager: OptimizelyClient {
    override init(sdkKey: String,
                  logger: OPTLogger? = nil,
                  eventDispatcher: OPTEventDispatcher? = nil,
                  datafileHandler: OPTDatafileHandler? = nil,
                  userProfileService: OPTUserProfileService? = nil,
                  defaultLogLevel: OptimizelyLogLevel? = nil,
                  defaultDecideOptions: [OptimizelyDecideOption]? = nil) {
        
        super.init(sdkKey: sdkKey,
                   logger: logger,
                   eventDispatcher: eventDispatcher,
                   datafileHandler: datafileHandler,
                   userProfileService: userProfileService,
                   defaultLogLevel: defaultLogLevel,
                   defaultDecideOptions: defaultDecideOptions)
        HandlerRegistryService.shared.removeAll()
        
        let userProfileService = userProfileService ?? DefaultUserProfileService()
        self.registerServices(sdkKey: sdkKey,
                              logger: logger ?? DefaultLogger(),
                              eventDispatcher: eventDispatcher ?? DefaultEventDispatcher.sharedInstance,
                              datafileHandler: datafileHandler ?? DefaultDatafileHandler(),
                              decisionService: FakeDecisionService(userProfileService: userProfileService),
                              notificationCenter: DefaultNotificationCenter())
    }
    
    func setDecisionServiceData(experiment: Experiment?, variation: Variation?, source: String) {
        (self.decisionService as! FakeDecisionService).experiment = experiment
        (self.decisionService as! FakeDecisionService).variation = variation
        (self.decisionService as! FakeDecisionService).source = source
    }
}

class FakeDecisionService: DefaultDecisionService {
    
    var experiment: Experiment?
    var variation: Variation?
    var source: String!
    
    override init(userProfileService: OPTUserProfileService) {
        super.init(userProfileService: DefaultUserProfileService())
    }
    
    override func getVariationForFeature(config: ProjectConfig,
                                         featureFlag: FeatureFlag,
                                         userId: String,
                                         attributes: OptimizelyAttributes,
                                         options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        guard let experiment = self.experiment, let tmpVariation = self.variation else {
            return DecisionResponse.nilNoReasons()
        }
        
        let featureDecision = FeatureDecision(experiment: experiment, variation: tmpVariation, source: source)
        return DecisionResponse.responseNoReasons(result: featureDecision)
    }
}

fileprivate extension HandlerRegistryService {
    func removeAll() {
        self.binders.property?.removeAll()
    }
}
