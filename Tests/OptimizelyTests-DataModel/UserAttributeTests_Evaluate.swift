/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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

class UserAttributeTests_Evaluate: XCTestCase {
    
    // MARK: - Evaluate Errors
    
    func testInvalidType() {
        var err: Error?
        let model = UserAttribute(name: "country", type: "unknown", match: "exact", value: .string("us"))
        do {
            try _ = model.evaluate(attributes: ["":""])
        } catch {
            err = error
        }
        XCTAssertNotNil(err)
    }
    
    func testInvalidMatchType() {
        var err: Error?
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "unknown", value: .string("us"))
        do {
            try _ = model.evaluate(attributes: ["":""])
        } catch {
            err = error
        }
        XCTAssertNotNil(err)
    }
    
    func testInvalidName() {
        var err: Error?
        var model = UserAttribute(name: "", type: "custom_attribute", match: "exact", value: .string("us"))
        model.name = nil
        do {
            try _ = model.evaluate(attributes: ["":""])
        } catch {
            err = error
        }
        XCTAssertNotNil(err)
    }
    
    func testMissingAttributeValue() {
        let attributes = ["country1": "us"]
        var err: Error?
        let name = "country"
        let model = UserAttribute(name: name, type: "custom_attribute", match: "exact", value: .string("us"))
        do {
            try _ = model.evaluate(attributes: attributes)
        } catch {
            err = error
        }
        XCTAssertNotNil(err)
    }
    
    func testNilUserAttributeValue() {
        let attributes = ["country": "us"]
        var err: Error?
        let name = "country"
        let model = UserAttribute(name: name, type: "custom_attribute", match: "exact", value: nil)
        do {
            try _ = model.evaluate(attributes: attributes)
        } catch {
            err = error
        }
        XCTAssertNotNil(err)
    }
    
    func testNilAttributeValue() {
        let attributes: [String : Any?] = ["country": nil]
        var err: Error?
        let name = "country"
        let model = UserAttribute(name: name, type: "custom_attribute", match: "exact", value: .string("us"))
        do {
            try _ = model.evaluate(attributes: attributes)
        } catch {
            err = error
        }
        XCTAssertNotNil(err)
    }
    
    // MARK: - Evaluate (Exact)
    
    func testEvaluateExactString() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .string("us"))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactInt() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .int(100))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactDouble() {
        let attributes = ["country": 15.3]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .double(15.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactBool() {
        let attributes = ["country": true]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .bool(true))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactBool2() {
        let attributes = ["country": false]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .bool(false))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testEvaluateExactStringFalse() {
        let attributes = ["country": "ca"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactIntFalse() {
        let attributes = ["country": 200]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .int(100))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactDoubleFalse() {
        let attributes = ["country": 15.4]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .double(15.3))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactBoolFalse() {
        let attributes = ["country": false]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .bool(true))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactDifferentTypeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .int(100))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactSameValueButDifferentName() {
        let attributes = ["address": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactSameValueButDifferentName2() {
        let attributes = ["country": "ca", "address": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
}

// MARK: - Evaluate (Substring)

extension UserAttributeTests_Evaluate {
    
    func testEvaluateSubstring() {
        let attributes = ["country": "us-gb"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: .string("us"))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringFalse() {
        let attributes = ["country": "gb-ca"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringReverseFalse() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: .string("us-ca"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

    func testEvaluateSubstringDifferentTypeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: .int(100))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringMissingAttributeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "h", type: "custom_attribute", match: "substring", value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (Exists)

extension UserAttributeTests_Evaluate {
    
    func testExist() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exists", value: .string("ca"))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testExistFail() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "h", type: "custom_attribute", match: "exists", value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (GT)

extension UserAttributeTests_Evaluate {
    
    func testGreaterThanIntToInt() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanIntToDouble() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanIntToString() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }

    func testGreaterThanIntToBool() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .bool(true))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testGreaterThanDoubleToInt() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testGreaterThanDoubleToDouble() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanDoubleToIntFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .int(200))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanDoubleToDoubleFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .double(201.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanDoubleToDoubleEqualFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "gt", value: .double(101.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (LT)

extension UserAttributeTests_Evaluate {
    
    func testLessThanIntToInt() {
        let attributes = ["country": 10]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanIntToDouble() {
        let attributes = ["country": 10]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanIntToString() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testLessThanIntToBool() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .bool(true))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToInt() {
        let attributes = ["country": 11.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToDouble() {
        let attributes = ["country": 11.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToIntFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .int(20))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToDoubleFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .double(21.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToDoubleEqualFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "lt", value: .double(101.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

}
