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
            notificationExperiment = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationExperiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationVariation] as? String
            notificationType = type
        })
        
        let variation = try? optimizely?.activate(experimentKey:
            "ab_running_exp_audience_combo_empty_conditions",
                                                  userId: "test_user_1",
                                                  attributes: attributes)
        
        XCTAssertEqual(variation, "all_traffic_variation")
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.NotificationKeys.OptimizelyDecisionTypeExperiment)
    }

    func testDecisionListenerWithActivateWhenUserNotInExperiment() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationExperiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationVariation] as? String
            notificationType = type
        })
    
        _ = try? optimizely?.activate(experimentKey:
            "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2",
                                                  userId: "test_user_1",
                                                  attributes: nil)
        
        XCTAssertEqual(notificationExperiment, nil)
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.NotificationKeys.OptimizelyDecisionTypeExperiment)
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
            notificationExperiment = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationExperiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationVariation] as? String
            notificationType = type
        })
        
        _ = try? optimizely?.getVariation(experimentKey: "ab_running_exp_audience_combo_empty_conditions",
                                                      userId: "test_user_1",
                                                      attributes: attributes)
        
        XCTAssertEqual(notificationExperiment, "ab_running_exp_audience_combo_empty_conditions")
        XCTAssertEqual(notificationVariation, "all_traffic_variation")
        XCTAssertEqual(notificationType, Constants.NotificationKeys.OptimizelyDecisionTypeExperiment)
    }
    
    func testDecisionListenerWithGetVariationWhenUserNotInExperiment() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting", clearUserProfileService: true)
        var notificationVariation : String?
        var notificationExperiment : String?
        var notificationType: String?
        
        _ = optimizely?.notificationCenter.addDecisionNotificationListener(decisionListener: { (type, userId, attributes, decisionInfo) in
            notificationExperiment = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationExperiment] as? String
            notificationVariation = decisionInfo[Constants.NotificationKeys.OptimizelyNotificationVariation] as? String
            notificationType = type
        })
        
        _ = try? optimizely?.getVariation(experimentKey: "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2", userId: "test_user_1")
        
        XCTAssertEqual(notificationExperiment, nil)
        XCTAssertEqual(notificationVariation, nil)
        XCTAssertEqual(notificationType, Constants.NotificationKeys.OptimizelyDecisionTypeExperiment)
    }

}
