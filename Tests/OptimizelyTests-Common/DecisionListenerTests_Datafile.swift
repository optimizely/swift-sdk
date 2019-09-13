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

class DecisionListenerTests_Datafile: XCTestCase {
    var optimizely: OptimizelyClient!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
    }
    
    func testDecisionListenerWithActivateWhenUserInExperiment() {
        let attributes: [String: Any?] = ["s_foo": "foo",
                                          "b_true": "N/A",
                                          "i_42": 44,
                                          "d_4_2": "N/A"]
        var notificationVariation: String?
        var notificationExperiment: String?
        var notificationType: String?
        
        let exp = expectation(description: "x")

        _ = self.optimizely.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, _, _, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
            exp.fulfill()
        })
        
        let variation = try? optimizely.activate(experimentKey:
            "ab_running_exp_audience_combo_empty_conditions",
                                                  userId: "test_user_1",
                                                  attributes: attributes)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(variation, "all_traffic_variation")
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.DecisionType.abTest.rawValue)
    }
    
    func testDecisionListenerWithActivateWhenUserNotInExperiment() {
        var notificationVariation: String?
        var notificationExperiment: String?
        var notificationType: String?
        
        let exp = expectation(description: "x")

        _ = optimizely.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, _, _, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
            exp.fulfill()
        })
        
        _ = try? optimizely.activate(experimentKey:
            "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2",
                                      userId: "test_user_1",
                                      attributes: nil)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.DecisionType.abTest.rawValue)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
    }
    
    func testDecisionListenerWithGetVariationWhenUserInExperiment() {
        let attributes: [String: Any?] = ["s_foo": "foo",
                                          "b_true": "N/A",
                                          "i_42": 44,
                                          "d_4_2": "N/A"]
        var notificationVariation: String?
        var notificationExperiment: String?
        var notificationType: String?
        
        let exp = expectation(description: "x")

        _ = optimizely.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, _, _, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
            exp.fulfill()
       })
        
        _ = try? optimizely.getVariation(experimentKey: "ab_running_exp_audience_combo_empty_conditions",
                                          userId: "test_user_1",
                                          attributes: attributes)
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.DecisionType.abTest.rawValue)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
    }
    
    func testDecisionListenerWithGetVariationWhenUserNotInExperiment() {
        var notificationVariation: String?
        var notificationExperiment: String?
        var notificationType: String?
        
        let exp = expectation(description: "x")

        _ = optimizely.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, _, _, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] as? String
            notificationVariation = decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] as? String
            notificationType = type
            exp.fulfill()
        })
        
        _ = try? optimizely.getVariation(experimentKey: "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2", userId: "test_user_1")
        wait(for: [exp], timeout: 1)

        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2")
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.DecisionType.abTest.rawValue)
        self.optimizely.notificationCenter.clearAllNotificationListeners()
    }
    
}
