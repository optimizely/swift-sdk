//
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
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = FakeManager(sdkKey: "12345",
                                      userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.initializeSDK(datafile: datafile)
    }
    
    func testDecisionListenerGetFeatureVariableBooleanWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableDoubleWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableIntegerWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
    }
    
    func testDecisionListenerGetFeatureVariableStringWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "123")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey, variableKey: kVariableKeyBool, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "boolean")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey, variableKey: kVariableKeyDouble, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Double, 4.2)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "double")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 50)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey, variableKey: kVariableKeyInt, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! Int, 42)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "integer")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
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
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "123")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableValue] as! String, "foo")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.variableType] as! String, "string")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, "exp_with_audience")
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, "a")
        }
        _ = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey, variableKey: kVariableKeyString, userId: kUserId)
    }
}

class FakeManager: OptimizelyManager {
    
    override var decisionService: OPTDecisionService {
        get {
            return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey, isReintialize: true)!
        }
    }
    
    override init(sdkKey: String, logger:OPTLogger? = nil, eventDispatcher:OPTEventDispatcher? = nil, userProfileService:OPTUserProfileService? = nil, periodicDownloadInterval:Int? = nil) {
        
        super.init(sdkKey: sdkKey, logger: logger, eventDispatcher: eventDispatcher, userProfileService: userProfileService, periodicDownloadInterval: periodicDownloadInterval)
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
