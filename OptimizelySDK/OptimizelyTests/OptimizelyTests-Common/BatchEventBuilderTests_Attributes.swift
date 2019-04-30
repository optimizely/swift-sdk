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
import SwiftyJSON

class BatchEventBuilderTests_Attributes: XCTestCase {
    
    let botFilteringKey = Constants.Attributes.OptimizelyBotFilteringAttribute
    
    let experimentKey = "ab_running_exp_audience_combo_exact_foo_or_true__and__42_or_4_2"
    let userId = "test_user_1"
    
    var optimizely: OptimizelyManager!
    var eventDispatcher: FakeEventDispatcher!
    var project: Project!
    
    // MARK: - setup
    
    override func setUp() {
        eventDispatcher = FakeEventDispatcher()
        
        optimizely = OTUtils.createOptimizely(datafileName: "audience_targeting",
                                              clearUserProfileService: true,
                                              eventDispatcher: eventDispatcher)!
        project = optimizely.config!.project!
    }
    
    // MARK: - test attribute contents
    
    func testEventAttributesContents() {
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2,
            "$opt_key_1": "bar",
            ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)

        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        
        var item: [String: Any] = array.filter{ $0["key"].stringValue == "s_foo" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! String, "foo")
        XCTAssertEqual(item["type"] as! String, "custom")
        XCTAssertEqual(item["entity_id"] as! String, "10401066171")
        
        item = array.filter{ $0["key"].stringValue == "b_true" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! Bool, true)
        XCTAssertEqual(item["type"] as! String, "custom")
        XCTAssertEqual(item["entity_id"] as! String, "10401066172")
        
        item = array.filter{ $0["key"].stringValue == "i_42" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! Int, 42)
        XCTAssertEqual(item["type"] as! String, "custom")
        XCTAssertEqual(item["entity_id"] as! String, "10401066172")
        
        item = array.filter{ $0["key"].stringValue == "d_4_2" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! Double, 4.2)
        XCTAssertEqual(item["type"] as! String, "custom")
        XCTAssertEqual(item["entity_id"] as! String, "10401066173")
        
        item = array.filter{ $0["key"].stringValue == "$opt_key_1" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! String, "bar")
        XCTAssertEqual(item["type"] as! String, "custom")
        XCTAssertEqual(item["entity_id"] as! String, "$opt_key_1")
    }
    
    func testEventAttributesContainsProperTypes() {
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2
        ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)

        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        var dict = [String: Any]()
        for item in array {
            dict[item["key"].stringValue] = item["value"].rawValue
        }
        XCTAssert(dict.count == attributes.count)
        
        // make sure type preserved correctly
        XCTAssert(CFGetTypeID(dict["s_foo"] as CFTypeRef) == CFGetTypeID("a" as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["b_true"] as CFTypeRef) == CFGetTypeID(false as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["i_42"] as CFTypeRef) == CFGetTypeID(0 as CFTypeRef))
        XCTAssert(CFGetTypeID(dict["d_4_2"] as CFTypeRef) == CFGetTypeID(1.5 as CFTypeRef))
        
        XCTAssert(dict["s_foo"] as! String == "foo")
        XCTAssert(dict["b_true"] as! Bool == true)
        XCTAssert(dict["i_42"] as! Int == 42)
        XCTAssert(dict["d_4_2"] as! Double == 4.2)
    }
    
    func testEventAttributesWithNotMatchingAttributes() {
        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2,
            "not_match_1": "bar",
            "not_match_2": 10
            ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)
        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        
        var item: [String: Any] = array.filter{ $0["key"].stringValue == "s_foo" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! String, "foo")
        
        item = array.filter{ $0["key"].stringValue == "b_true" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! Bool, true)
        
        item = array.filter{ $0["key"].stringValue == "i_42" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! Int, 42)
        
        item = array.filter{ $0["key"].stringValue == "d_4_2" }.first!.dictionaryObject!
        XCTAssertEqual(item["value"] as! Double, 4.2)
        
        // "not_match_x" not defined in datafile > attributes
        XCTAssertEqual(item.count, 4, "not-matching attributes must be filtered out")
    }

    // MARK: - $opt attributes
    
    func testEventAttributesWithOptKeys() {
        let attributes: [String: Any] = [
            "$opt_key_1": "bar",
            "$opt_key_2": false,
            "$opt_key_3": 142,
            "$opt_key_4": 14.2,
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.2
        ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)

        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        var dict = [String: Any]()
        for item in array {
            dict[item["key"].stringValue] = item["value"].rawValue
        }
        XCTAssert(dict.count == attributes.count)
        
        // make sure type preserved correctly
        
        XCTAssert(dict["$opt_key_1"] as! String == "bar")
        XCTAssert(dict["$opt_key_2"] as! Bool == false)
        XCTAssert(dict["$opt_key_3"] as! Int == 142)
        XCTAssert(dict["$opt_key_4"] as! Double == 14.2)
        
        XCTAssert(dict["s_foo"] as! String == "foo")
        XCTAssert(dict["b_true"] as! Bool == true)
        XCTAssert(dict["i_42"] as! Int == 42)
        XCTAssert(dict["d_4_2"] as! Double == 4.2)
    }
    
    func testEventAttributesWhenAttributesEmpty() {
        // clear all audience conditions to accept empty attributes
        var experiment = optimizely.config!.project!.experiments.filter({$0.key == experimentKey}).first!
        experiment.audienceConditions = nil
        experiment.audienceIds = []
        optimizely.config!.project!.experiments = [experiment]
        
        let attributes: [String: Any] = [:]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)
        

        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"]
        XCTAssert(array.count == 0)
    }
    
    func testEventAttributesWhenAttributesNil() {
        // clear all audience conditions to accept empty attributes
        var experiment = optimizely.config!.project!.experiments.filter({$0.key == experimentKey}).first!
        experiment.audienceConditions = nil
        experiment.audienceIds = []
        optimizely.config!.project!.experiments = [experiment]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: nil)
        
        
        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"]
        XCTAssert(array.count == 0)
    }
    
    // MARK: - compatible with ObjC types
    
    func testEventAttributesContainsProperTypesWithNSNumber() {
        // ObjC data types (NSNumber, NSString,...)
        let attributes: [String: Any] = [
            "s_foo": NSString(string: "foo"),
            "b_true": NSNumber(value: false),
            "i_42": NSNumber(value: 42),
            "d_4_2": NSNumber(value: 4.2)
        ]
        
        _ = try! optimizely.activate(experimentKey: experimentKey,
                                     userId: userId,
                                     attributes: attributes)

        let event = eventDispatcher.events.first!
        let json = JSON(event.body)
        let array = json["visitors"][0]["attributes"].arrayValue
        var dict = [String: Any]()
        for item in array {
            dict[item["key"].stringValue] = item["value"].rawValue
        }
        XCTAssert(dict.count == attributes.count)
        
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
    
}

// MARK: - bot filtering

extension BatchEventBuilderTests_Attributes {
    
    func testBotFilteringWhenTrue() {
        eventDispatcher = FakeEventDispatcher()
        optimizely = OTUtils.createOptimizely(datafileName: "bot_filtering_enabled",
                                              clearUserProfileService: true,
                                              eventDispatcher: eventDispatcher)
        _ = try! optimizely?.activate(experimentKey: "ab_running_exp_untargeted",
                                      userId: "test_user_1")

        let eventForDispatch = eventDispatcher.events.first
        let event: BatchEvent = try! OTUtils.model(fromData: eventForDispatch!.body)
        
        if let botAttribute = event.getEventAttribute(key: botFilteringKey),
            botAttribute.entityID == botFilteringKey
        {
            XCTAssertEqual(botAttribute.value, .bool(true))
        } else {
            XCTAssert(false, "$opt_bot_filtering should be included")
        }
    }
    
    func testBotFilteringWhenFalse() {
        eventDispatcher = FakeEventDispatcher()
        optimizely = OTUtils.createOptimizely(datafileName: "bot_filtering_enabled",
                                              clearUserProfileService: true,
                                              eventDispatcher: eventDispatcher)
        optimizely!.config!.project.botFiltering = false
        
        _ = try! optimizely?.activate(experimentKey: "ab_running_exp_untargeted",
                                      userId: "test_user_1")
        
        
        let eventForDispatch = eventDispatcher.events.first
        let event: BatchEvent = try! OTUtils.model(fromData: eventForDispatch!.body)
        
        if let botAttribute = event.getEventAttribute(key: botFilteringKey),
            botAttribute.entityID == botFilteringKey
        {
            XCTAssertEqual(botAttribute.value, .bool(false))
        } else {
            XCTAssert(false, "$opt_bot_filtering should be included")
        }
    }
    
    func testBotFilteringWhenNil() {
        eventDispatcher = FakeEventDispatcher()
        optimizely = OTUtils.createOptimizely(datafileName: "bot_filtering_enabled",
                                              clearUserProfileService: true,
                                              eventDispatcher: eventDispatcher)
        optimizely!.config!.project.botFiltering = nil
        
        _ = try! optimizely?.activate(experimentKey: "ab_running_exp_untargeted",
                                      userId: "test_user_1")
        
        
        let eventForDispatch = eventDispatcher.events.first
        let event: BatchEvent = try! OTUtils.model(fromData: eventForDispatch!.body)
        
        if let botAttribute = event.getEventAttribute(key: botFilteringKey),
            botAttribute.entityID == botFilteringKey
        {
            XCTAssert(false, "$opt_bot_filtering should not be included")
        } else {
            XCTAssert(true)
        }
    }
    
}
