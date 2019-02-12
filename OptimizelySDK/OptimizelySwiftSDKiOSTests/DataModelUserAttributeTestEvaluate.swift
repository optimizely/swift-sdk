//
//  DataModelUserAttribute-EvaluateTest.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelUserAttributeTestEvaluate: XCTestCase {
    
    // MARK: - Evaluate (Exact)
    
    func testEvaluateExactString() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: "us")
        XCTAssert(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactInt() {
        let attributes = ["country": 100]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: 100)
        XCTAssert(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactDouble() {
        let attributes = ["country": 15.3]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: 15.3)
        XCTAssert(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactBool() {
        let attributes = ["country": true]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: true)
        XCTAssert(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactStringFalse() {
        let attributes = ["country": "ca"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: "us")
        XCTAssertFalse(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactIntFalse() {
        let attributes = ["country": 200]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: 100)
        XCTAssertFalse(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactDoubleFalse() {
        let attributes = ["country": 15.4]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: 15.3)
        XCTAssertFalse(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactBoolFalse() {
        let attributes = ["country": false]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: true)
        XCTAssertFalse(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateExactDifferentTypeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "exact", value: 100)
        XCTAssertNil(model.evaluate(attributes: attributes))
    }
    
    func testEvaluateExactMissingAttributeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "house", type: "custom_attribute", match: "exact", value: "us")
        XCTAssertNil(model.evaluate(attributes: attributes))
    }
    
}

// MARK: - Evaluate (Substring)

extension DataModelUserAttributeTestEvaluate {
    
    func testEvaluateSubstring() {
        let attributes = ["country": "us, gb"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: "us")
        XCTAssert(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateSubstringFalse() {
        let attributes = ["country": "gb, ca"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: "us")
        XCTAssertFalse(model.evaluate(attributes: attributes)!)
    }
    
    func testEvaluateSubstringDifferentTypeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "country", type: "custom_attribute", match: "substring", value: 100)
        XCTAssertNil(model.evaluate(attributes: attributes))
    }
    
    func testEvaluateSubstringMissingAttributeNil() {
        let attributes = ["country": "us"]
        let model = UserAttribute(name: "house", type: "custom_attribute", match: "substring", value: "us")
        XCTAssertNil(model.evaluate(attributes: attributes))
    }

}

// MARK: - Evaluate (Exists)

extension DataModelUserAttributeTestEvaluate {
    
}

// MARK: - Evaluate (GT)

extension DataModelUserAttributeTestEvaluate {
    
}

// MARK: - Evaluate (LT)

extension DataModelUserAttributeTestEvaluate {
    
}


