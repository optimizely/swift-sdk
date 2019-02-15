//
//  DataModelUserAttributeTest.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelUserAttributeTests: XCTestCase {
    
    let modelType = UserAttribute.self
    
    
    static func baseModel() -> UserAttribute {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30]
        return jsonDecodeFromDict(json)
    }
    
    static func baseModelJsonString() -> String {
        let data = try! JSONEncoder().encode(baseModel())
        return String(data: data, encoding: .utf8)!
    }
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "exact")
        XCTAssert(model.value == .int(30))
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"gt", "value":30.5]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "gt")
        XCTAssert(model.value == .double(30.5))
    }

    func testDecodeSuccessWithJSONValid3() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exists", "value":true]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "exists")
        XCTAssert(model.value == .bool(true))
    }

    func testDecodeSuccessWithJSONValid4() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"substring", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "substring")
        XCTAssert(model.value == .string("us"))
    }
    
    func testDecodeSuccessWithMissingMatch() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.value == .string("us"))
    }

    func testDecodeFailWithMissingName() {
        let json: [String: Any] = ["type":"custom_attribute", "match":"exact", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])

        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingType() {
        let json: [String: Any] = ["name":"geo", "match":"exact", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingValue() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithWrongValueType() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact", "value": ["a1", "a2"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
}

// MARK: - Encode

extension DataModelUserAttributeTests {
    func testEncodeJSON() {
        let modelGiven = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: .string("us"))
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
}

