//
//  DataModelUserAttributeTest.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelUserAttributeTest: XCTestCase {
    
    let modelType = UserAttribute.self
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exact", "value":30]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "exact")
        XCTAssert(model.value as! Double == 30)
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"gt", "value":30.5]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "gt")
        XCTAssert(model.value as! Double == 30.5)
    }

    func testDecodeSuccessWithJSONValid3() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"exists", "value":true]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "exists")
        XCTAssert(model.value as! Bool == true)
    }

    func testDecodeSuccessWithJSONValid4() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"substring", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.match == "substring")
        XCTAssert(model.value as! String == "us")
    }
    
    func testDecodeSuccessWithMissingMatch() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "value":"us"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.name == "geo")
        XCTAssert(model.type == "custom_attribute")
        XCTAssert(model.value as! String == "us")
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

extension DataModelUserAttributeTest {
    func testEncodeJSON() {
        let modelGiven = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
}

// MARK: - Equatable

extension DataModelUserAttributeTest {
    
    func testEqual() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        XCTAssertEqual(model1, model2)
    }
    
    func testEqual2() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 100)
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 100)
        XCTAssertEqual(model1, model2)
    }
    
    func testEqual3() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 15.3)
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 15.3)
        XCTAssertEqual(model1, model2)
    }
    
    func testEqual4() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: true)
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: true)
        XCTAssertEqual(model1, model2)
    }
    
    func testNotEqual() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        let model2 = modelType.init(name: "geoNE", type: "custom_attribute", match: "exact", value: "us")
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual2() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        let model2 = modelType.init(name: "geo", type: "custom_attributeNE", match: "exact", value: "us")
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual3() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exactNE", value: "us")
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual4() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "usNE")
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual5() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 10)
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 20)
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual6() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 15.3)
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 15.4)
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual7() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: true)
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: false)
        XCTAssertNotEqual(model1, model2)
    }
    
    func testNotEqual8() {
        let model1 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: "us")
        let model2 = modelType.init(name: "geo", type: "custom_attribute", match: "exact", value: 100)
        XCTAssertNotEqual(model1, model2)
    }
    
}

