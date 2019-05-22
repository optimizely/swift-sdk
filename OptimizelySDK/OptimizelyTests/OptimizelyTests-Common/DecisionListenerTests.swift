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
    var optimizely2: OptimizelyClient?
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = FakeManager(sdkKey: "12345",
                                      userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
        
        
        self.optimizely2 = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserInRollout() {
        
        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689660112", value: "false"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserInRollout() {
        
        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689280165", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserInRollout() {
        
        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2687470095", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserInRollout() {
        
        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "123")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserInExperiment() {
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689660112", value: "false"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserInExperiment() {
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2689280165", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserInExperiment() {
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2687470095", value: "50"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserInExperiment() {
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        variation.variables?.append(Variable(id: "2696150066", value: "123"))
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "123")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, "exp_with_audience")
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
    }
    
    func testDecisionListenerWithActivateWhenUserInExperiment() {
        let attributes: [String: Any?] = ["s_foo": "foo",
                                          "b_true": "N/A",
                                          "i_42": 44,
                                          "d_4_2": "N/A"]
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = self.optimizely2?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
        })
        
        let variation = try? optimizely2?.activate(experimentKey:
            "ab_running_exp_audience_combo_empty_conditions",
                                                  userId: "test_user_1",
                                                  attributes: attributes)
        
        XCTAssertEqual(variation, "all_traffic_variation")
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.abTest)
    }
    
    func testDecisionListenerWithActivateWhenUserNotInExperiment() {
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely2?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
        })
        
        _ = try? optimizely2?.activate(experimentKey:
            "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2",
                                      userId: "test_user_1",
                                      attributes: nil)
        
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.abTest)
        self.optimizely2?.notificationCenter.clearAllNotificationListeners()
    }
    
    func testDecisionListenerWithGetVariationWhenUserInExperiment() {
        let attributes: [String: Any?] = ["s_foo": "foo",
                                          "b_true": "N/A",
                                          "i_42": 44,
                                          "d_4_2": "N/A"]
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely2?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, _attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
        })
        
        _ = try? optimizely2?.getVariation(experimentKey: "ab_running_exp_audience_combo_empty_conditions",
                                          userId: "test_user_1",
                                          attributes: attributes)
        
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.abTest)
        self.optimizely2?.notificationCenter.clearAllNotificationListeners()
    }
    
    func testDecisionListenerWithGetVariationWhenUserNotInExperiment() {
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely2?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
        })
        
        _ = try? optimizely2?.getVariation(experimentKey: "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2", userId: "test_user_1")
        
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.abTest)
        self.optimizely2?.notificationCenter.clearAllNotificationListeners()
    }
    
    func testDecisionListenerForGetEnabledFeatures() {

        var count = 0
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.feature])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.featureEnabled])
            XCTAssertNotNil(decisionInfo[Constants.DecisionInfoKeys.source])
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            count += 1
        }
        
        _ = optimizely.getEnabledFeatures(userId: kUserId)
        XCTAssertEqual(count, 2)
    }
    
    func testDecisionListenerWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
    }
    
    func testDecisionListenerWithUserInRollout() {
        
        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.rollout)
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment])
            XCTAssertNil(decisionInfo[Constants.ExperimentDecisionInfoKeys.variation])
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
    }
    
    func testDecisionListenerWithUserInExperiment() {
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first!)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, experiment.key)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, variation.key)
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.featureTest)
            let sourceInfo: [String:Any] = decisionInfo[Constants.DecisionInfoKeys.sourceInfo]! as! [String : Any]
            XCTAssertNotNil(sourceInfo)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] as! String, experiment.key)
            XCTAssertEqual(sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] as! String, variation.key)
        }
        _ = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
    }
}

class FakeManager: OptimizelyClient {
    
    override var decisionService: OPTDecisionService {
        get {
            return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey, isReintialize: true)!
        }
    }
    
    override init(sdkKey: String, logger:OPTLogger? = nil, eventDispatcher:OPTEventDispatcher? = nil, userProfileService:OPTUserProfileService? = nil, periodicDownloadInterval:Int? = nil, defaultLogLevel: OptimizelyLogLevel? = nil) {
        
        super.init(sdkKey: sdkKey, logger: logger, eventDispatcher: eventDispatcher, userProfileService: userProfileService, periodicDownloadInterval: periodicDownloadInterval, defaultLogLevel: defaultLogLevel)
        HandlerRegistryService.shared.removeAll()
        
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
    
    override func getVariationForFeature(config:ProjectConfig, featureFlag:FeatureFlag, userId:String, attributes: OptimizelyAttributes) -> (experiment:Experiment?, variation:Variation?)? {
        return (self.experiment, self.variation)
    }
}

fileprivate extension HandlerRegistryService {
    func removeAll() {
        self.binders.removeAll()
    }
}
