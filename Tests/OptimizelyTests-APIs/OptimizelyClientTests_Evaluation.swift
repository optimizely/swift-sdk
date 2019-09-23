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

class OptimizelyClientTests_Evaluation: XCTestCase {

    let kUserId = "11111"
    
    var datafile: Data?
    var optimizely: OptimizelyClient?
    var eventDispatcher: FakeEventDispatcher?
    
    // MARK: - Attribute Value Range
    
    func testActivateConditions_ConditionRangeIntNegativeInvalid() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_typed_audiences_lt_43_match"
        let userId = "test_user_1"
        
        let attributes: [String: Any?] = [
            "i_42": -9007199254740994
       ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssertNil(variationKey)
    }
    
    func testActivateConditions_ConditionRangeIntPositiveInvalid() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_typed_audiences_gt_41_match"
        let userId = "test_user_1"
        
        let attributes: [String: Any?] = [
            "i_42": 9007199254740994
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssertNil(variationKey)
    }

    func testActivateConditions_ConditionRangeDoubleNegativeInvalid() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_typed_audiences_lt_4_3_match"
        let userId = "test_user_1"
        
        let attributes: [String: Any?] = [
            "d_4_2": -9007199254740994
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssertNil(variationKey)
    }

    func testActivateConditions_ConditionRangeDoublePositiveInvalid() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_typed_audiences_gt_4_1_match"
        let userId = "test_user_1"
        
        let attributes: [String: Any?] = [
            "d_4_2": 9007199254740994
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssertNil(variationKey)
    }

    // MARK: - Conditions
    
    func testActivateCondtions_MissingOperator() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!

        let experimentKey = "ab_running_exp_audience_combo_missing_operand_exact_foo_or_42"
        let userId = "test_user_1"
        let expectedVariationKey = "all_traffic_variation"

        let attributes: [String: Any?] = [
            "s_foo": "not_foo",
            "b_true": "N/A",
            "i_42": 42,
            "d_4_2": "N/A"
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }
    
    func testActivateCondtions_AudienceIdsIgnoredWhenConditionExists() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_audience_combo_with_exact_foo_match_audience_id_and_empty_audience_conditions"
        let userId = "test_user_1"
        let expectedVariationKey = "all_traffic_variation"
        
        let attributes: [String: Any?] = [
            "string_attribute": "no_match"
        ]
        
        // [audienceIds] should be ignored since [audienceCondtions] exists (empty)
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }
    
    func testActivateCondtions_ExistStringNil() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "negated_ab_running_exp_typed_audiences_s_foo_exists_match"
        let userId = "test_user_1"
        let expectedVariationKey = "all_traffic_variation"
        
        let attributes: [String: Any?] = [
            "s_foo": nil
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }
    
    func testActivateCondtions_ExistBoolNil() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "negated_ab_running_exp_typed_audiences_b_true_exists_match"
        let userId = "test_user_1"
        let expectedVariationKey = "all_traffic_variation"
        
        let attributes: [String: Any?] = [
            "b_true": nil
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

    func testActivateCondtions_ExistIntNil() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "negated_ab_running_exp_typed_audiences_i_42_exists_match"
        let userId = "test_user_1"
        let expectedVariationKey = "all_traffic_variation"
        
        let attributes: [String: Any?] = [
            "i_42": nil
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

    func testActivateCondtions_ExistDoubleNil() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "negated_ab_running_exp_typed_audiences_d_4_2_exists_match"
        let userId = "test_user_1"
        let expectedVariationKey = "all_traffic_variation"
        
        let attributes: [String: Any?] = [
            "d_4_2": nil
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

    // MARK: - Attribute values
    
    func testActivateWithNilAttributeValues() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_audience_combo_exact_foo_and_42"
        let userId = "test_user_1"

        let attributes: [String: Any?] = [
            "s_foo": "foo",
            "b_true": nil,
            "i_42": 44,
            "d_4_2": nil
            ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssertNil(variationKey)
    }

    func testActivateDispatchWithAttributeValues() {
        let eventDispatcher = FakeEventDispatcher()
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher)!

        let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_42"
        let userId = "test_user_1"

        let attributes: [String: Any?] = [
            "s_foo": "foo",
            "b_true": nil,
            "i_42": 44,
            "d_4_2": nil
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        sleep(1)
        XCTAssertNotNil(variationKey)
        XCTAssertNotNil(eventDispatcher.events.first)
    }

    func testActivateWithExactCombo() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!

        let experimentKey = "ab_running_exp_audience_combo_exact_foo_and_true__or__42_and_4_2"
        let expectedVariationKey = "all_traffic_variation"

        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.3
        ]
        
        var isEqual = false
        do {
            let variationKey = try optimizely.activate(experimentKey: experimentKey,
                                                       userId: kUserId,
                                                       attributes: attributes)
            isEqual = variationKey == expectedVariationKey
        } catch {
        }
        XCTAssert(isEqual)
    }
    
    func testBucketWithOptBucketId() {
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketing_id",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_untargeted"
        let expectedVariationKey = "variation_10000"
        
        let attributes: [String: Any] = ["$opt_bucketing_id": "ppid21886780721"]
        
        let variationKey = try! optimizely.activate(experimentKey: experimentKey,
                                                    userId: kUserId,
                                                    attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }
    
    func testBucketWithOptBucketId2() {
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketing_id", clearUserProfileService: true)!

        let experimentKey = "ab_running_exp_untargeted"
        let expectedVariationKey = "variation_7500"

        let attributes: [String: Any] = ["$opt_bucketing_id": "ppid21886780722"]

        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: kUserId, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

    func testBucketWithOptBucketIdEmpty() {
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketing_id", clearUserProfileService: true)!

        let experimentKey = "ab_running_exp_untargeted"
        let userIdForThisTestOnly = "11111"
        let expectedVariationKey = "variation_10000"

        let attributes: [String: Any] = ["$opt_bucketing_id": ""]

        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: userIdForThisTestOnly, attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

    func testBucketWithGroup() {
        let optimizely = OTUtils.createOptimizely(datafileName: "grouped_experiments", clearUserProfileService: true)!

        let experimentKey = "experiment_4000"
        let userIdForThisTestOnly = "ppid31886780721"
        let expectedVariationKey = "all_traffic_variation_exp_1"

        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: userIdForThisTestOnly)
        XCTAssert(variationKey == expectedVariationKey)
    }
    
    func testForcedVariation() {
        let optimizely = OTUtils.createOptimizely(datafileName: "ab_experiments", clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_untargeted"
        let expectedVariationKey = "no_traffic_variation"
        
        let attributes: [String: Any] = ["customattr": "does_not_matter"]
        
        _ = optimizely.setForcedVariation(experimentKey: experimentKey,
                                           userId: kUserId,
                                           variationKey: expectedVariationKey)
        
        let variationKey = try! optimizely.activate(experimentKey: experimentKey,
                                                    userId: kUserId,
                                                    attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

}
