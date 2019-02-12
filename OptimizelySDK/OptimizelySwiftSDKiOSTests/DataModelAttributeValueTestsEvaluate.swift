//
//  DataModelAttributeValueTestsEvaluate.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Evaluate (Equal)

class DataModelAttributeValueTestsEvaluate: XCTestCase {
    
    func testIsExactMatchString() {
        let model = try! getAttributeValueFromNative("us")
        XCTAssert(model.isExactMatch(with: "us")!)
    }
    
    func testIsExactMatchInt() {
        let model = try! getAttributeValueFromNative(10)
        XCTAssert(model.isExactMatch(with: 10)!)
    }

    func testIsExactMatchDouble() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssert(model.isExactMatch(with: 13.5)!)
    }

    func testIsExactMatchDoubleWithInt() {
        let model = try! getAttributeValueFromNative(Double(13))
        XCTAssert(model.isExactMatch(with: Int(13))!)
    }

    func testIsExactMatchBool() {
        let model = try! getAttributeValueFromNative(true)
        XCTAssert(model.isExactMatch(with: true)!)
    }

    func testIsExactMatchBool2() {
        let model = try! getAttributeValueFromNative(false)
        XCTAssert(model.isExactMatch(with: false)!)
    }

    func testIsExactMatchStringFail() {
        let model = try! getAttributeValueFromNative("us")
        XCTAssertFalse(model.isExactMatch(with: "ca")!)
    }

    func testIsExactMatchIntFail() {
        let model = try! getAttributeValueFromNative(10)
        XCTAssertFalse(model.isExactMatch(with: 20)!)
    }

    func testIsExactMatchDoubleFail() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isExactMatch(with: 20.1)!)
    }

    func testIsExactMatchBoolFail() {
        let model = try! getAttributeValueFromNative(true)
        XCTAssertFalse(model.isExactMatch(with: false)!)
    }
}

// MARK: - Evaluate (Substring)

extension DataModelAttributeValueTestsEvaluate {

    func testIsSubstringSuccessSame() {
        let model = try! getAttributeValueFromNative("us")
        XCTAssert(model.isSubstring(of: "us")!)
    }

    func testIsSubstringSuccessContains() {
        let model = try! getAttributeValueFromNative("us")
        XCTAssert(model.isSubstring(of: "us-ca")!)
    }

    func testIsSubstringFail() {
        let model = try! getAttributeValueFromNative("us-ca")
        XCTAssertFalse(model.isSubstring(of: "us")!)
    }
    
    func testIsSubstringFailWithInt() {
        let model = try! getAttributeValueFromNative("us")
        XCTAssertNil(model.isSubstring(of: 10))
    }

    func testIsSubstringFailWithBool() {
        let model = try! getAttributeValueFromNative("true")
        XCTAssertNil(model.isSubstring(of: true))
    }

    func testIsSubstringFailForWrongType() {
        let model = try! getAttributeValueFromNative(10)
        XCTAssertNil(model.isSubstring(of: "us"))
    }

}

// MARK: - Evaluate (GreaterThan)

extension DataModelAttributeValueTestsEvaluate {

    func testIsGreaterSuccess() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssert(model.isGreater(than: 10.0)!)
    }
    
    func testIsGreaterSuccessWithInt() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssert(model.isGreater(than: Int(10))!)
    }

    func testIsGreaterFail() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isGreater(than: 20.0)!)
    }
    
    func testIsGreaterFailSame() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isGreater(than: 13.5)!)
    }
    
}

// MARK: - Evaluate (LessThan)

extension DataModelAttributeValueTestsEvaluate {
    
    func testIsLessSuccess() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssert(model.isLess(than: 20.0)!)
    }
    
    func testisLessSuccessWithInt() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssert(model.isLess(than: Int(20))!)
    }
    
    func testisLessFail() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isLess(than: 10.0)!)
    }
    
    func testisLessFailSame() {
        let model = try! getAttributeValueFromNative(13.5)
        XCTAssertFalse(model.isLess(than: 13.5)!)
    }
    
}
