//
// Copyright 2019, 2021-2022, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

class BatchEventBuilderTests_EventTags: XCTestCase {

    let userId = "test_user_1"
    let eventKey = "event_single_targeted_exp"

    var optimizely: OptimizelyClient!
    var eventDispatcher: MockEventDispatcher!
    var project: Project!
    
    override func setUp() {
        eventDispatcher = MockEventDispatcher()
        
        optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                                  clearUserProfileService: true,
                                                  eventDispatcher: eventDispatcher)!
        project = optimizely.config!.project
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
                                        "future": [1, 2, 3]]
        
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
        XCTAssert(isEqualTooBigDoubles(tags["tooBig"] as! Double, OTUtils.positiveTooBigValue))
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

    func testEventTagsWhenRevenueAndValueWhenInvalidBigNumbers() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["revenue": Int64(OTUtils.positiveTooBigValue),
                                        "value": OTUtils.positiveTooBigValue]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        // range should not be checked for event tags including revenue/value (JIRA #4449)
        
        XCTAssertEqual(tags["revenue"] as! Int64, Int64(OTUtils.positiveTooBigValue))
        XCTAssertEqual(de["revenue"] as! Int64, Int64(OTUtils.positiveTooBigValue))
        XCTAssert(isEqualTooBigDoubles(tags["value"] as! Double, OTUtils.positiveTooBigValue))
        XCTAssert(isEqualTooBigDoubles(de["value"] as! Double, OTUtils.positiveTooBigValue))
    }

    func testEventTagsWhenRevenueAndValueWhenInvalidBigNumbersNegative() {
        let eventKey = "event_single_targeted_exp"
        let eventTags: [String: Any] = ["revenue": Int64(OTUtils.negativeTooBigValue),
                                        "value": OTUtils.negativeTooBigValue]
        
        try! optimizely.track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
        
        let de = getDispatchEvent(dispatcher: eventDispatcher)!
        let tags = de["tags"] as! [String: Any]
        
        // range should not be checked for event tags including revenue/value (JIRA #4449)
        
        XCTAssertEqual(tags["revenue"] as! Int64, Int64(OTUtils.negativeTooBigValue))
        XCTAssertEqual(de["revenue"] as! Int64, Int64(OTUtils.negativeTooBigValue))
        XCTAssert(isEqualTooBigDoubles(tags["value"] as! Double, OTUtils.negativeTooBigValue))
        XCTAssert(isEqualTooBigDoubles(de["value"] as! Double, OTUtils.negativeTooBigValue))
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
    
    func testEventTagsWithRevenueAndValue_toJSON() {
        
        // valid revenue/value types
        
        let conversion1 = BatchEventBuilder.createConversionEvent(config: (optimizely?.config)!, eventKey: eventKey, userId: userId, attributes: [:],
                                                                  eventTags: ["browser": "chrome",
                                                                              "revenue": 123,
                                                                              "value": 32.5])
        
        // invalid revenue/value types
        
        let conversion2 = BatchEventBuilder.createConversionEvent(config: (optimizely?.config)!, eventKey: eventKey, userId: userId, attributes: [:],
                                                                  eventTags: ["browser": "chrome",
                                                                              "revenue": true,
                                                                              "value": "invalid"])
        
        // deserialized from JSON
        let batchEvent1 = try? JSONDecoder().decode(BatchEvent.self, from: conversion1!)
        let batchEvent2 = try? JSONDecoder().decode(BatchEvent.self, from: conversion2!)
        
        XCTAssertEqual(batchEvent1?.visitors[0].visitorID, userId)
        XCTAssertEqual(batchEvent1?.visitors[0].snapshots[0].events[0].revenue, 123)
        XCTAssertEqual(batchEvent1?.visitors[0].snapshots[0].events[0].value, 32.5)
        
        XCTAssertEqual(batchEvent2?.visitors[0].visitorID, userId)
        XCTAssertNil(batchEvent2?.visitors[0].snapshots[0].events[0].revenue, "invalid type not extracted")
        XCTAssertNil(batchEvent2?.visitors[0].snapshots[0].events[0].value, "invalid type not extracted")
    }
    
}

// MARK: - Utils

extension BatchEventBuilderTests_EventTags {

    func getDispatchEvent(dispatcher: MockEventDispatcher) -> [String: Any]? {
        optimizely.eventLock.sync{}
        let eventForDispatch = dispatcher.events.first!
        
        let json = try! JSONSerialization.jsonObject(with: eventForDispatch.body, options: .allowFragments) as! [String: Any]
        let event = json
        
        let visitor = (event["visitors"] as! Array<Dictionary<String, Any>>)[0]
        let snapshot = (visitor["snapshots"] as! Array<Dictionary<String, Any>>)[0]
        let dispatchEvent = (snapshot["events"] as! Array<Dictionary<String, Any>>)[0] 

        return dispatchEvent
    }
    
    // SwiftyJSON returns inaccurate double value for iOS9- (precision issue)
    // Convert to Float to ignore tails
    func isEqualTooBigDoubles(_ num1: Double, _ num2: Double) -> Bool {
        return Float(num1) == Float(num2)
    }
    
}
