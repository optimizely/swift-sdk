//
//  BatchEventBuilderTests_EventTags.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/13/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest
import SwiftyJSON

class BatchEventBuilderTests_EventTags: XCTestCase {

    let userId = "test_user_1"
    let eventKey = "event_single_targeted_exp"

    var optimizely: OptimizelyManager!
    var eventDispatcher: FakeEventDispatcher!
    var project: Project!
    
    override func setUp() {
        eventDispatcher = FakeEventDispatcher()
        
        optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher)!
        project = optimizely.config!.project!
    }
    
    func testEventTags() {
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "price": 14.5,
                                        "count": 20,
                                        "check": false]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]

        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["price"] as! Double, 14.5)
        XCTAssertEqual(tags["count"] as! Int, 20)
        XCTAssertEqual(tags["check"] as! Bool, false)
        XCTAssertNil(de["revenue"])
        XCTAssertNil(de["value"])
    }
    
    func testEventTagsWhenRevenueAndValue() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": 123,
                                        "value": 32.5]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]

        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! Int, 123)
        XCTAssertEqual(tags["value"] as! Double, 32.5)
        XCTAssertEqual(de["revenue"] as! Int, 123, "revenue field must be copied")
        XCTAssertEqual(de["value"] as! Double, 32.5, "value field must be copied")
    }

}

// MARK: - invalid types in tags

extension BatchEventBuilderTests_EventTags {

    func testEventTagsWhenInvalidType() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "future": [1,2,3]]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertNil(tags["future"])
    }

    func testEventTagsWhenTooBigNumbers() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "big": OTUtils.positiveMaxValueAllowed,
                                        "tooBig": OTUtils.positiveTooBigValue]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["big"] as! Double, OTUtils.positiveMaxValueAllowed)
        XCTAssertNil(tags["tooBig"])
    }

}

// MARK: - {revenue, value} invalid values
    
extension BatchEventBuilderTests_EventTags {

    func testEventTagsWhenRevenueAndValueWhenWrongType1() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": "foo",
                                        "value": "bar"]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]

        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! String, "foo")
        XCTAssertEqual(tags["value"] as! String, "bar")
        XCTAssertNil(de["revenue"], "invalid-type revenue field should not be copied")
        XCTAssertNil(de["value"], "invalid-type value field should not be copied")
    }
    
    func testEventTagsWhenRevenueAndValueWhenWrongType2() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": true,
                                        "value": false]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]

        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! Bool, true)
        XCTAssertEqual(tags["value"] as! Bool, false)
        XCTAssertNil(de["revenue"], "invalid-type revenue field should not be copied")
        XCTAssertNil(de["value"], "invalid-type value field should not be copied")
    }

    func testEventTagsWhenRevenueAndValueWhenWrongType3() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": 12.5,
                                        "value": 30]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! Double, 12.5)
        XCTAssertEqual(tags["value"] as! Int, 30)
        XCTAssertEqual(de["revenue"] as! Int, 12, "double converted to integer")
        XCTAssertEqual(de["value"] as! Double, 30.0, "integer converted to double")
    }
    
}

// MARK: - {revenue, value} large numbers

extension BatchEventBuilderTests_EventTags {

    func testEventTagsWhenRevenueAndValueWhenValidBigNumbers() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["revenue": Int64(OTUtils.positiveMaxValueAllowed),
                                        "value": OTUtils.positiveMaxValueAllowed]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["revenue"] as! Int64, Int64(OTUtils.positiveMaxValueAllowed))
        XCTAssertEqual(tags["value"] as! Double, OTUtils.positiveMaxValueAllowed)
        XCTAssertEqual(de["revenue"] as! Int64, Int64(OTUtils.positiveMaxValueAllowed))
        XCTAssertEqual(de["value"] as! Double, OTUtils.positiveMaxValueAllowed)
    }
    
    func testEventTagsWhenRevenueAndValueWhenInvalidBigNumbers() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["revenue": Int64(OTUtils.positiveTooBigValue),
                                        "value": OTUtils.positiveTooBigValue]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertNil(tags["revenue"], "invalid number must be filtered")
        XCTAssertNil(tags["value"], "invalid number must be filtered")
        XCTAssertNil(de["revenue"], "invalid-type revenue field should not be copied")
        XCTAssertNil(de["value"], "invalid-type value field should not be copied")
    }

    func testEventTagsWhenRevenueAndValueWhenValidBigNumbersNegative() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["revenue": Int64(OTUtils.negativeMaxValueAllowed),
                                        "value": OTUtils.negativeMaxValueAllowed]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["revenue"] as! Int64, Int64(OTUtils.negativeMaxValueAllowed))
        XCTAssertEqual(tags["value"] as! Double, OTUtils.negativeMaxValueAllowed)
        XCTAssertEqual(de["revenue"] as! Int64, Int64(OTUtils.negativeMaxValueAllowed))
        XCTAssertEqual(de["value"] as! Double, OTUtils.negativeMaxValueAllowed)
    }
    
    func testEventTagsWhenRevenueAndValueWhenInvalidBigNumbersNegative() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["revenue": Int64(OTUtils.negativeTooBigValue),
                                        "value": OTUtils.negativeTooBigValue]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertNil(tags["revenue"], "invalid number must be filtered")
        XCTAssertNil(tags["value"], "invalid number must be filtered")
        XCTAssertNil(de["revenue"], "invalid-type revenue field should not be copied")
        XCTAssertNil(de["value"], "invalid-type value field should not be copied")
    }
}

// MARK: - {revenue, value} test with {0, 1} values

extension BatchEventBuilderTests_EventTags {

    func testEventTagsWhenRevenueAndValueWithValue0() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": 0,
                                        "value": 0]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]

        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! Int, 0)
        XCTAssertEqual(tags["value"] as! Double, 0)
        XCTAssertEqual(de["revenue"] as! Int, 0, "value 0 must be valid for revenue")
        XCTAssertEqual(de["value"] as! Double, 0, "value 0 must be valid for value")
    }
    
    func testEventTagsWhenRevenueAndValueWithValue1() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": 1,
                                        "value": 1]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! Int, 1)
        XCTAssertEqual(tags["value"] as! Double, 1)
        XCTAssertEqual(de["revenue"] as! Int, 1, "value 1 must be valid for revenue")
        XCTAssertEqual(de["value"] as! Double, 1, "value 1 must be valid for value")
    }

    func testEventTagsWhenRevenueAndValueWithValueM1() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": -1,
                                        "value": -1]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["revenue"] as! Int, -1)
        XCTAssertEqual(tags["value"] as! Double, -1)
        XCTAssertEqual(de["revenue"] as! Int, -1, "value -1 must be valid for revenue")
        XCTAssertEqual(de["value"] as! Double, -1, "value -1 must be valid for value")
    }
}

// MARK: - ObjC or special types

extension BatchEventBuilderTests_EventTags {
    
    func testEventTagsWhenRevenueAndValueWithObjcTypes() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "check": NSNumber(booleanLiteral: true),
                                        "revenue": NSNumber(value: 10),
                                        "value": NSNumber(value: 3.15)]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["check"] as! Bool, true)
        XCTAssertEqual(tags["revenue"] as! Int, 10)
        XCTAssertEqual(tags["value"] as! Double, 3.15)
        XCTAssertEqual(de["revenue"] as! Int, 10, "value must be valid for revenue")
        XCTAssertEqual(de["value"] as! Double, 3.15, "value must be valid for value")
    }
    
    func testEventTagsWhenRevenueAndValueWithSpecialTypes() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "v1": Int8(10),
                                        "v2": Int16(20),
                                        "v3": Int32(30),
                                        "revenue": Int64(40),
                                        "value": Float(32)]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        XCTAssertEqual(tags["browser"] as! String, "chrome")
        XCTAssertEqual(tags["v1"] as! Int, 10)
        XCTAssertEqual(tags["v2"] as! Int, 20)
        XCTAssertEqual(tags["v3"] as! Int, 30)
        XCTAssertEqual(tags["revenue"] as! Int, 40)
        XCTAssertEqual(tags["value"] as! Double, 32)
        XCTAssertEqual(de["revenue"] as! Int, 40, "value must be valid for revenue")
        XCTAssertEqual(de["value"] as! Double, 32, "value must be valid for value")
    }

}

// MARK: - Utils

extension BatchEventBuilderTests_EventTags {

    func getDispatchEvent(dispatcher: FakeEventDispatcher) -> [String: Any]? {
        let eventForDispatch = dispatcher.events.first!
        let json = JSON(eventForDispatch.body)
        let event = json.dictionaryValue
        
        let visitor = event["visitors"]![0].dictionaryValue
        let snapshot = visitor["snapshots"]![0].dictionaryValue
        let dispatchEvent = snapshot["events"]![0].dictionaryObject

        return dispatchEvent
    }
    
}
