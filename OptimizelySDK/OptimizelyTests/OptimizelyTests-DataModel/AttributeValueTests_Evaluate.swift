//
//  AttributeValueTests_Evaluate.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Evaluate (Equal)

class AttributeValueTests_Evaluate: XCTestCase {
    
    func testIsExactMatchString() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(try! model.isExactMatch(with: "us"))
    }
    
    func testIsExactMatchInt() {
        let model = try! OTUtils.getAttributeValueFromNative(10)
        XCTAssertTrue(try! model.isExactMatch(with: 10))
    }

    func testIsExactMatchDouble() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isExactMatch(with: 13.5))
    }

    func testIsExactMatchDoubleWithInt() {
        let model = try! OTUtils.getAttributeValueFromNative(Double(13))
        XCTAssertTrue(try! model.isExactMatch(with: Int(13)))
    }

    func testIsExactMatchBool() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertTrue(try! model.isExactMatch(with: true))
    }

    func testIsExactMatchBool2() {
        let model = try! OTUtils.getAttributeValueFromNative(false)
        XCTAssertTrue(try! model.isExactMatch(with: false))
    }

    func testIsExactMatchStringFail() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertFalse(try! model.isExactMatch(with: "ca"))
    }

    func testIsExactMatchIntFail() {
        let model = try! OTUtils.getAttributeValueFromNative(10)
        XCTAssertFalse(try! model.isExactMatch(with: 20))
    }

    func testIsExactMatchDoubleFail() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isExactMatch(with: 20.1))
    }

    func testIsExactMatchBoolFail() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertFalse(try! model.isExactMatch(with: false))
    }
}

// MARK: - Evaluate (Substring)

extension AttributeValueTests_Evaluate {

    func testIsSubstringSuccessSame() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(try! model.isSubstring(of: "us"))
    }

    func testIsSubstringSuccessContains() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertTrue(try! model.isSubstring(of: "us-ca"))
    }

    func testIsSubstringFail() {
        let model = try! OTUtils.getAttributeValueFromNative("us-ca")
        XCTAssertFalse(try! model.isSubstring(of: "us"))
    }
    
    func testIsSubstringFailWithInt() {
        let model = try! OTUtils.getAttributeValueFromNative("us")
        XCTAssertNil(try? model.isSubstring(of: 10))
    }

    func testIsSubstringFailWithBool() {
        let model = try! OTUtils.getAttributeValueFromNative("true")
        XCTAssertNil(try? model.isSubstring(of: true))
    }

    func testIsSubstringFailForWrongType() {
        let model = try! OTUtils.getAttributeValueFromNative(10)
        XCTAssertNil(try? model.isSubstring(of: "us"))
    }

}

// MARK: - Evaluate (GreaterThan)

extension AttributeValueTests_Evaluate {

    func testIsGreaterSuccess() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: 10.0))
    }
    
    func testIsGreaterSuccessWithInt() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: Int(10)))
    }

    func testIsGreaterFail() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: 20.0))
    }
    
    func testIsGreaterFailSame() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: 13.5))
    }
    
    // MARK: - Int8/16/32/64
    
    func testIsGreaterSuccessWithInt8() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: Int8(10)))
    }

    func testIsGreaterSuccessWithInt16() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: Int16(10)))
    }

    func testIsGreaterSuccessWithInt32() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: Int32(10)))
    }

    func testIsGreaterSuccessWithInt64() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: Int64(10)))
    }

    // MARK: - Large numbers
    
    func testIsGreaterSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isGreater(than: pow(2, 61) as Double))
    }
    
    func testIsGreaterSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isGreater(than: -pow(2, 61) as Double))
    }
    
    func testIsGreaterSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isGreater(than: pow(2, 61) as Float))
    }
    
    func testIsGreaterSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isGreater(than: Int64(pow(2, 61) as Double)))
    }
}

// MARK: - Evaluate (LessThan)

extension AttributeValueTests_Evaluate {
    
    func testIsLessSuccess() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: 20.0))
    }
    
    func testisLessSuccessWithInt() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int(20)))
    }
    
    func testisLessFail() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isLess(than: 10.0))
    }
    
    func testisLessFailSame() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isLess(than: 13.5))
    }
    
    // MARK: - Int8/16/32/64
    
    func testIsLessSuccessWithInt8() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int8(20)))
    }
    
    func testIsLessSuccessWithInt16() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int16(20)))
    }
    
    func testIsLessSuccessWithInt32() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int32(20)))
    }
    
    func testIsLessSuccessWithInt64() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int64(20)))
    }
    
    // MARK: - Large numbers
    
    func testIsLessSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isLess(than: pow(2, 61) as Double))
    }
    
    func testIsLessSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isLess(than: -pow(2, 61) as Double))
    }
    
    func testIsLessSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isLess(than: pow(2, 61) as Float))
    }
    
    func testIsLessSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertNil(try? model.isLess(than: Int64(pow(2, 61) as Double)))
    }

    
}
