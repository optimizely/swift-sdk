//
//  UserAttributeTest.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class UserAttributeTests: XCTestCase {
    let modelType = UserAttribute.self
    
    static var sampleData: [String: Any] = ["name":"geo",
                                            "type":"custom_attribute",
                                            "match":"exact",
                                            "value":30]
}

// MARK: - Decode

extension UserAttributeTests {
    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .exact)
        XCTAssert(model.value == .int(30))
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"gt", "value":30.5]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .gt)
        XCTAssert(model.value == .double(30.5))
    }

    func testDecodeSuccessWithJSONValid3() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exists", "value":true]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .exists)
        XCTAssert(model.value == .bool(true))
    }

    func testDecodeSuccessWithJSONValid4() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"substring", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .substring)
        XCTAssert(model.value == .string("us"))
    }
    
    func testDecodeSuccessWithMissingMatch() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.value == .string("us"))
    }

    func testDecodeSuccessWithMissingName() {
        let json: [String: Any] = ["type":"custom_attribute", "match":"exact", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .exact)
        XCTAssert(model.value == .string("us"))
    }

    func testDecodeSuccessWithMissingType() {
        let json: [String: Any] = ["name":"geo", "match":"exact", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(model.name == "geo")
        XCTAssert(model.matchSupported == .exact)
        XCTAssert(model.value == .string("us"))
    }
    
    func testDecodeSuccessWithMissingValue() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .exact)
    }
    
    func testDecodeSuccessWithWrongValueType() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact", "value": ["a1", "a2"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssert(model.matchSupported == .exact)
        XCTAssert(model.value == .others)
    }
    
    // MARK: - Forward Compatibility
    
    func testDecodeSuccessWithInvalidType() {
        let json: [String: Any] = ["name":"geo", "type":"invalid", "match":"exact", "value": 10]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssertNil(model.typeSupported)
        XCTAssert(model.matchSupported == .exact)
    }
    
    func testDecodeSuccessWithInvalidMatch() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"invalid", "value": 10]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.typeSupported == .customAttribute)
        XCTAssertNil(model.matchSupported)
    }
    
}

// MARK: - Encode

extension UserAttributeTests {
    func testEncodeJSON() {
        let modelGiven = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: .string("us"))
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
}

