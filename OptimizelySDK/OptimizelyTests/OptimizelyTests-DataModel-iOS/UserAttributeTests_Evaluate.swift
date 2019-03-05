//
//  UserAttributeTests_Evaluate.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class UserAttributeTests_Evaluate: XCTestCase {
    
    // MARK: - Evaluate (Exact)
    
    func testEvaluateExactString() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .string("us"))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactInt() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .int(100))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactDouble() {
        let attributes = ["country": 15.3]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .double(15.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactBool() {
        let attributes = ["country": true]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .bool(true))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactBool2() {
        let attributes = ["country": false]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .bool(false))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testEvaluateExactStringFalse() {
        let attributes = ["country": "ca"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactIntFalse() {
        let attributes = ["country": 200]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .int(100))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactDoubleFalse() {
        let attributes = ["country": 15.4]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .double(15.3))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactBoolFalse() {
        let attributes = ["country": false]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .bool(true))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactDifferentTypeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .int(100))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactSameValueButDifferentName() {
        let attributes = ["address": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactSameValueButDifferentName2() {
        let attributes = ["country": "ca", "address": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exact, value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
}

// MARK: - Evaluate (Substring)

extension UserAttributeTests_Evaluate {
    
    func testEvaluateSubstring() {
        let attributes = ["country": "us-gb"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .substring, value: .string("us"))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringFalse() {
        let attributes = ["country": "gb-ca"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .substring, value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringReverseFalse() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .substring, value: .string("us-ca"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

    func testEvaluateSubstringDifferentTypeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .substring, value: .int(100))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringMissingAttributeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "h", type: .customAttribute, match: .substring, value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (Exists)

extension UserAttributeTests_Evaluate {
    
    func testExist() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .exists, value: .string("ca"))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testExistFail() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "h", type: .customAttribute, match: .exists, value: .string("us"))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (GT)

extension UserAttributeTests_Evaluate {
    
    func testGreaterThanIntToInt() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanIntToDouble() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanIntToString() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }

    func testGreaterThanIntToBool() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .bool(true))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testGreaterThanDoubleToInt() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testGreaterThanDoubleToDouble() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanDoubleToIntFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .int(200))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanDoubleToDoubleFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .double(201.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

    func testGreaterThanDoubleToDoubleEqualFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .gt, value: .double(101.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (LT)

extension UserAttributeTests_Evaluate {
    
    func testLessThanIntToInt() {
        let attributes = ["country": 10]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanIntToDouble() {
        let attributes = ["country": 10]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanIntToString() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .string("us"))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testLessThanIntToBool() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .bool(true))
        XCTAssertNil(try? model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToInt() {
        let attributes = ["country": 11.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .int(50))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToDouble() {
        let attributes = ["country": 11.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .double(51.3))
        XCTAssertTrue(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToIntFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .int(20))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToDoubleFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .double(21.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }
    
    func testLessThanDoubleToDoubleEqualFail() {
        let attributes = ["country": 101.2]
        let model = UserAttribute(name: "country", type: .customAttribute, match: .lt, value: .double(101.2))
        XCTAssertFalse(try! model.evaluate(attributes: attributes))
    }

}


