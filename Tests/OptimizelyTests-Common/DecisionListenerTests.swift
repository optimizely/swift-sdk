/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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

class DecisionListenerTests: XCTestCase {
    
    // MARK: - Constants
    
    let kFeatureKey = "feature_1"
    let kUserId = "11111"
    
    let kVariableKeyString = "s_foo"
    let kVariableKeyInt = "i_42"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyBool = "b_true"
    
    let kVariableValueString = "foo"
    let kVariableValueInt = 42
    let kVariableValueDouble = 4.2
    let kVariableValueBool = true
    
    // MARK: - Properties
    
    var datafile: Data!
    var optimizely: FakeManager!
    var notificationCenter: OPTNotificationCenter!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = FakeManager(sdkKey: "12345",
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
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
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

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
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

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
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

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
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
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserInRollout() {
        var exp = expectation(description: "x")

        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689660112", value: "false"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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

        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689280165", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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

        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2687470095", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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

        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserInExperiment() {
        var exp = expectation(description: "x")

        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689660112", value: "false"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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

        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
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

        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
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

class FakeManager: OptimizelyClient {
    
    override var decisionService: OPTDecisionService {
        get {
            return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey, isReintialize: true)!
        }
    }
    
    override init(sdkKey: String,
                  logger: OPTLogger? = nil,
                  eventDispatcher: OPTEventDispatcher? = nil,
                  userProfileService: OPTUserProfileService? = nil,
                  defaultLogLevel: OptimizelyLogLevel? = nil) {
        
        super.init(sdkKey: sdkKey,
                   logger: logger,
                   eventDispatcher: eventDispatcher,
                   userProfileService: userProfileService,
                   defaultLogLevel: defaultLogLevel)
        OptimizelyClient.clearRegistryService()

        let userProfileService = userProfileService ?? DefaultUserProfileService()
        self.registerServices(sdkKey: sdkKey,
                              logger: logger ?? DefaultLogger(),
                              eventDispatcher: eventDispatcher ?? DefaultEventDispatcher.sharedInstance,
                              datafileHandler: DefaultDatafileHandler(),
                              decisionService: FakeDecisionService(userProfileService: userProfileService),
                              notificationCenter: DefaultNotificationCenter())
    }
    
    func setDecisionServiceData(experiment: Experiment?, variation: Variation?) {
        (self.decisionService as! FakeDecisionService).experiment = experiment
        (self.decisionService as! FakeDecisionService).variation = variation
    }
}

class FakeDecisionService: DefaultDecisionService {
    
    var experiment: Experiment?
    var variation: Variation?
    
    override init(userProfileService: OPTUserProfileService) {
        super.init(userProfileService: DefaultUserProfileService())
    }
    
    override func getVariationForFeature(config: ProjectConfig, featureFlag: FeatureFlag, userId: String, attributes: OptimizelyAttributes) -> (experiment: Experiment?, variation: Variation?)? {
        return (self.experiment, self.variation)
    }
}

