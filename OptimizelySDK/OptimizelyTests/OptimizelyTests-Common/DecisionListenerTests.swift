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
    
    // MARK: - Properties
    
    var datafile: Data!
    var optimizely: FakeManager!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("typed_audience_datafile")
        
        self.optimizely = FakeManager(sdkKey: "12345",
                                      userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.initializeSDK(datafile: datafile)
    }
    
    func testDecisionListenerForGetEnabledFeatures() {
    
        let tmpDatafile = OTUtils.loadJSONDatafile("api_datafile")
        
        let tmpOptimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! tmpOptimizely.initializeSDK(datafile: tmpDatafile!)
        
        var count = 0
        tmpOptimizely.notificationCenter.clearAllNotificationListeners()
        _ = tmpOptimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            count += 1
        }
        
        _ = try! tmpOptimizely.getEnabledFeatures(userId: kUserId)
        XCTAssertEqual(count, 2)
    }
    
    func testDecisionListenerWithUserNotInExperimentAndRollout() {
        
        self.optimizely.setDecisionServiceData(experiment: nil, variation: nil)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try? self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
    }
    
    func testDecisionListenerWithUserInRollout() {
        
        var variation: Variation = (self.optimizely.config?.allExperiments.first!.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try! self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: nil, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Rollout)
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment])
            XCTAssertNil(decisionInfo[Constants.DecisionInfoKeys.sourceVariation])
        }
        _ = try! self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
    }
    
    func testDecisionListenerWithUserInExperiment() {
        
        let experiment: Experiment = (self.optimizely.config?.allExperiments.first!)!
        var variation: Variation = (experiment.variations.first)!
        variation.featureEnabled = true
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, true)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, experiment.key)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, variation.key)
        }
        _ = try! self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        
        variation.featureEnabled = false
        self.optimizely.setDecisionServiceData(experiment: experiment, variation: variation)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
        _ = self.optimizely.notificationCenter.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.featureEnabled] as! Bool, false)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.source] as! String, Constants.DecisionSource.Experiment)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] as! String, experiment.key)
            XCTAssertEqual(decisionInfo[Constants.DecisionInfoKeys.sourceVariation] as! String, variation.key)
        }
        _ = try! self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
    }
    
    func testDecisionListenerWithActivateWhenUserInExperiment() {
        let attributes: [String: Any?] = ["s_foo": "foo",
                                          "b_true": "N/A",
                                          "i_42": 44,
                                          "d_4_2": "N/A"]
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.NotificationKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.variation] as? String
            notificationType = type
        })
        
        let variation = try? optimizely?.activate(experimentKey:
            "ab_running_exp_audience_combo_empty_conditions",
                                                  userId: "test_user_1",
                                                  attributes: attributes)
        
        XCTAssertEqual(variation, "all_traffic_variation")
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.experiment)
    }
    
    func testDecisionListenerWithActivateWhenUserNotInExperiment() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.NotificationKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.variation] as? String
            notificationType = type
        })
        
        _ = try? optimizely?.activate(experimentKey:
            "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2",
                                      userId: "test_user_1",
                                      attributes: nil)
        
        XCTAssertEqual(notificationExperiment, nil)
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.experiment)
    }
    
    func testDecisionListenerWithGetVariationWhenUserInExperiment() {
        let attributes: [String: Any?] = ["s_foo": "foo",
                                          "b_true": "N/A",
                                          "i_42": 44,
                                          "d_4_2": "N/A"]
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, _attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.NotificationKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.variation] as? String
            notificationType = type
        })
        
        _ = try? optimizely?.getVariation(experimentKey: "ab_running_exp_audience_combo_empty_conditions",
                                          userId: "test_user_1",
                                          attributes: attributes)
        
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.experiment)
    }
    
    func testDecisionListenerWithGetVariationWhenUserNotInExperiment() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.NotificationKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.variation] as? String
            notificationType = type
        })
        
        _ = try? optimizely?.getVariation(experimentKey: "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2", userId: "test_user_1")
        
        XCTAssertEqual(notificationExperiment, nil)
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.DecisionTypeKeys.experiment)
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
