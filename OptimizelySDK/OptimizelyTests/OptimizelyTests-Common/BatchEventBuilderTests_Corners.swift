//
//  BatchEventBuilderTests_Corners.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/13/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest
import SwiftyJSON

class BatchEventBuilderTests_Corners: XCTestCase {

    func testEventAttributesFromObjC() {
        let eventDispatcher = FakeEventDispatcher()

        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher)!
        let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
        let userId = "test_user_1"
            
        let attributes: [String: Any] = [
            "s_foo": NSString(string: "foo"),
            "b_true": NSNumber(value: false),
            "i_42": NSNumber(value: 42),
            "d_4_2": NSNumber(value: 4.2)
        ]

        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)
        
        let event = eventDispatcher.events.first
        XCTAssertNotNil(event)
        
        let json = JSON(event!.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        var dict = [String: Any]()
        for item in array {
            dict[item["key"].stringValue] = item["value"].rawValue
        }
        
        // make sure type preserved correctly
        XCTAssert(CFGetTypeID(dict["s_foo"] as CFTypeRef) == CFGetTypeID("a" as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["b_true"] as CFTypeRef) == CFGetTypeID(false as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["i_42"] as CFTypeRef) == CFGetTypeID(0 as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["d_4_2"] as CFTypeRef) == CFGetTypeID(1.5 as CFTypeRef))
        
        XCTAssert(dict["s_foo"] as! String == "foo")
        XCTAssert(dict["b_true"] as! Bool == false)
        XCTAssert(dict["i_42"] as! Int == 42)
        XCTAssert(dict["d_4_2"] as! Double == 4.2)

    }
    
    func testEventAttributesFromObjC_2() {
        let eventDispatcher = FakeEventDispatcher()
        
        let optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher)!
        let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
        let userId = "test_user_1"
        
        let attributes: [String: Any] = [
            "s_foo": String("foo"),
            "b_true": Bool(true),
            "i_42": Int(42)
        ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)
        
        let event = eventDispatcher.events.first
        XCTAssertNotNil(event)
        
        let json = JSON(event!.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        var dict = [String: Any]()
        for item in array {
            dict[item["key"].stringValue] = item["value"].rawValue
        }
        
        // make sure type preserved correctly
        XCTAssert(CFGetTypeID(dict["s_foo"] as CFTypeRef) == CFGetTypeID("a" as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["b_true"] as CFTypeRef) == CFGetTypeID(false as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["i_42"] as CFTypeRef) == CFGetTypeID(0 as CFTypeRef))
        
        XCTAssert(dict["s_foo"] as! String == "foo")
        XCTAssert(dict["b_true"] as! Bool == true)
        XCTAssert(dict["i_42"] as! Int == 42)
        
    }
    
    func testBotFiltering() {
        let eventDispatcher = FakeEventDispatcher()
        let optimizely = OTUtils.createOptimizely(datafileName: "bot_filtering_enabled", clearUserProfileService: true, eventDispatcher: eventDispatcher)
        
        let variation = try? optimizely?.activate(experimentKey: "ab_running_exp_untargeted", userId: "test_user_1")
        
        XCTAssertNotNil(variation)
        
        let event = eventDispatcher.events.first
        XCTAssertNotNil(event)
        
        let json = try? JSONDecoder().decode(BatchEvent.self, from: (event?.body)!)
        let array = json?.visitors[0].attributes
        var assert = true
        for item in array! {
            if item.entityID == Constants.Attributes.OptimizelyBotFilteringAttribute {
                assert = false
            }
        }
        
        XCTAssertFalse(assert)
        
        
    }
}
