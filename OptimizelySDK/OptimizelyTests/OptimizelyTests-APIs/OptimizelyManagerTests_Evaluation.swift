//
//  OptimizelyManagerTests_Evaluation.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Jae Kim on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Evaluation: XCTestCase {

    let kUserId = "11111"
    
    var datafile: Data?
    var optimizely: OptimizelyManager?
    var eventDispatcher:FakeEventDispatcher?
    
    func testActivateConditions_ConditionInvalid() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_typed_audiences_lt_43_match"
        let userId = "test_user_1"
        
        let attributes: [String : Any?] = [
            "i_42": -9007199254740994.0
       ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: userId, attributes: attributes)
        XCTAssertNil(variationKey)
    }

    func testActivateWithNilAttributeValues() {
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_audience_combo_exact_foo_and_42"
        
        let attributes: [String : Any?] = [
            "s_foo": "foo",
            "b_true": nil,
            "i_42": 44,
            "d_4_2": nil
            ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: kUserId, attributes: attributes)
        XCTAssertNil(variationKey)
    }

    func testActivateDispatchWithAttributeValues() {
        let eventDispatcher = FakeEventDispatcher()
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher)!

        let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_42"
        
        let attributes: [String : Any?] = [
            "s_foo": "foo",
            "b_true": nil,
            "i_42": 44,
            "d_4_2": nil
        ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: kUserId, attributes: attributes)
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
        
        do {
            let variationKey = try optimizely.activate(experimentKey: experimentKey,
                                                       userId: kUserId,
                                                       attributes: attributes)
            XCTAssert(variationKey == expectedVariationKey)
        } catch {
            XCTAssert(false)
        }
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

    // TODO: [Jae] FSC reports different results. check it out 
    
//    func testBucketWithOptBucketId2() {
//        let optimizely = OTUtils.createOptimizely(datafileName: "bucketing_id", clearUserProfileService: true)!
//
//        let experimentKey = "ab_running_exp_untargeted"
//        let expectedVariationKey = "variation_7500"
//
//        let attributes: [String: Any] = ["$opt_bucketing_id": "ppid21886780722"]
//
//        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: kUserId, attributes: attributes)
//        XCTAssert(variationKey == expectedVariationKey)
//    }
//
//    func testBucketWithOptBucketIdEmpty() {
//        let optimizely = OTUtils.createOptimizely(datafileName: "bucketing_id", clearUserProfileService: true)!
//
//        let experimentKey = "ab_running_exp_untargeted"
//        let userIdForThisTestOnly = "11111"
//        let expectedVariationKey = "variation_7500"
//
//        let attributes: [String: Any] = ["$opt_bucketing_id": ""]
//
//        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: userIdForThisTestOnly, attributes: attributes)
//        XCTAssert(variationKey == expectedVariationKey)
//    }

    func testBucketWithGroup() {
        
        // TODO: [Jae] empty experiments[] cause trouble for current "activate" implementation
        //             experiments are defined only in group.
        
//        let optimizely = OTUtils.createOptimizely(datafileName: "grouped_experiments", clearUserProfileService: true)!
//
//        let experimentKey = "experiment_4000"
//        let userIdForThisTestOnly = "ppid31886780721"
//        let expectedVariationKey = "variation_7500"
//
//        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: userIdForThisTestOnly)
//        XCTAssert(variationKey == expectedVariationKey)
    }
    
    func testForcedVariation() {
        let optimizely = OTUtils.createOptimizely(datafileName: "ab_experiments", clearUserProfileService: true)!
        
        let experimentKey = "ab_running_exp_untargeted"
        let expectedVariationKey = "no_traffic_variation"
        
        let attributes: [String: Any] = ["customattr": "does_not_matter"]
        
        try! optimizely.setForcedVariation(experimentKey: experimentKey,
                                           userId: kUserId,
                                           variationKey: expectedVariationKey)
        
        let variationKey = try! optimizely.activate(experimentKey: experimentKey,
                                                    userId: kUserId,
                                                    attributes: attributes)
        XCTAssert(variationKey == expectedVariationKey)
    }

}

class FakeEventDispatcher : OPTEventDispatcher {

    public var events:[EventForDispatch] = [EventForDispatch]()
    required init() {
        
    }

    func dispatchEvent(event:EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        events.append(event)
        //completionHandler(event)
    }
    
    /// Attempts to flush the event queue if there are any events to process.
    func flushEvents() {
        
    }

}
