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
        // integer can be parsed as int or double (we catch as double first)
        XCTAssert(model.value == .double(30.0))
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

// MARK: - Others

extension UserAttributeTests {
    
    func testDecodeFailureWithInvalidData() {
        let jsonInvalid: [String: Any] = ["name": true, "type": 123]
        let jsonDataInvalid = try! JSONSerialization.data(withJSONObject: jsonInvalid, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonDataInvalid)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testEvaluateWithMissingName() {
        let json: [String: Any] = ["type":"custom_attribute", "match":"exact", "value":"us"]
        let model: UserAttribute = try! OTUtils.model(from: json)

        do {
            _ = try model.evaluate(attributes: ["country": "us"])
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testEvaluateWithInvalidMatch() {
        let json: [String: Any] = ["name":"geo", "type":"custom_attribute", "match":"invalid", "value": 10]
        let model: UserAttribute = try! OTUtils.model(from: json)

        do {
            _ = try model.evaluate(attributes: ["name": "geo"])
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

}
