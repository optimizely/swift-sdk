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

    func testIsExactMatchBoolFail() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        XCTAssertFalse(try! model.isExactMatch(with: false))
    }
    
    // MARK: - All value types
    
    func testIsExactMatchWithAllNumTypes() {
        let valueInt = 30
        
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertTrue(try! modelInt.isExactMatch(with: test), "error with index = \(idx)")
        }
        for (idx, test) in allValueTypes(value: Double(99)).enumerated() {
            XCTAssertFalse(try! modelInt.isExactMatch(with: test), "error with index = \(idx)")
        }
        
        let valueDouble = 13.0
        
        let modelDouble = try! OTUtils.getAttributeValueFromNative(Double(valueDouble))
        for (idx, test) in allValueTypes(value: Double(valueDouble)).enumerated() {
            XCTAssertTrue(try! modelDouble.isExactMatch(with: test), "error with index = \(idx)")
        }
        for (idx, test) in allValueTypes(value: Double(99)).enumerated() {
            XCTAssertFalse(try! modelDouble.isExactMatch(with: test), "error with index = \(idx)")
        }
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
    
    // MARK: - All value types
    
    func testIsGreaterWithAllNumTypes() {
        let value = 13.5
        let smallerValue = 10.0
        let biggerValue = 20.0
        
        let model = try! OTUtils.getAttributeValueFromNative(value)

        for (idx, test) in allValueTypes(value: smallerValue).enumerated() {
            XCTAssertTrue(try! model.isGreater(than: test), "error with index = \(idx)")
        }

        for (idx, test) in allValueTypes(value: biggerValue).enumerated() {
            XCTAssertFalse(try! model.isGreater(than: test), "error with index = \(idx)")
        }

        // false for equal values
        let valueInt = 30
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertFalse(try! modelInt.isGreater(than: test), "error with index = \(idx)")
        }
    }

    // MARK: - Large numbers
    
    func testIsGreaterSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: positiveMaxValueAllowed as Double))
        XCTAssertNil(try? model.isGreater(than: positiveMaxValueAllowed + 100.0 as Double))
    }
    
    func testIsGreaterSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isGreater(than: negativeMaxValueAllowed as Double))
        XCTAssertNil(try? model.isGreater(than: negativeMaxValueAllowed - 100.0 as Double))
    }
    
    func testIsGreaterSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: Float(positiveMaxValueAllowed)))
        // precision issue; adding 100 is not big enough for overflow
        XCTAssertNil(try? model.isGreater(than: Float(positiveMaxValueAllowed * 2.0)))
    }
    
    func testIsGreaterSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isGreater(than: Int64(positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isGreater(than: Int64(positiveMaxValueAllowed + 100.0)))
    }

}

// MARK: - Evaluate (LessThan)

extension AttributeValueTests_Evaluate {
    
    // MARK: - All value types
    
    func testIsLessWithAllNumTypes() {
        let value = 13.5
        let smallerValue = 10.0
        let biggerValue = 20.0
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        
        for (idx, test) in allValueTypes(value: smallerValue).enumerated() {
            XCTAssertFalse(try! model.isLess(than: test), "error with index = \(idx)")
        }
        
        for (idx, test) in allValueTypes(value: biggerValue).enumerated() {
            XCTAssertTrue(try! model.isLess(than: test), "error with index = \(idx)")
        }
        
        // false for equal values
        let valueInt = 30
        let modelInt = try! OTUtils.getAttributeValueFromNative(valueInt)
        for (idx, test) in allValueTypes(value: Double(valueInt)).enumerated() {
            XCTAssertFalse(try! modelInt.isLess(than: test), "error with index = \(idx)")
        }
    }

    // MARK: - Large numbers
    
    func testIsLessSuccessWithDouble_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: positiveMaxValueAllowed as Double))
        XCTAssertNil(try? model.isLess(than: positiveMaxValueAllowed + 100.0 as Double))
    }
    
    func testIsLessSuccessWithDouble_NegativeLargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertFalse(try! model.isLess(than: negativeMaxValueAllowed as Double))
        XCTAssertNil(try? model.isLess(than: negativeMaxValueAllowed - 100.0 as Double))
    }
    
    func testIsLessSuccessWithFloat_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Float(positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isLess(than: Float(positiveMaxValueAllowed * 2.0)))
    }
    
    func testIsLessSuccessWithInt64_LargeValue() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        XCTAssertTrue(try! model.isLess(than: Int64(positiveMaxValueAllowed)))
        XCTAssertNil(try? model.isLess(than: Int64(positiveMaxValueAllowed + 100.0)))
    }
    
    // MARK: - Utils
    
    var positiveMaxValueAllowed: Double {
        return pow(2, 53)
    }
    
    var negativeMaxValueAllowed: Double {
        return -pow(2, 53)
    }
    
    func allIntTypes(value: Double) -> [Any] {
        return [Int(value), Int8(value), Int16(value), Int32(value), Int64(value),
                UInt(value), UInt8(value), UInt16(value), UInt32(value), UInt64(value)]
    }

    func allNumTypes(value: Double) -> [Any] {
        return [Double(value), Float(value), Float32(value), Float64(value), Float80(value)]
    }
    
    func allValueTypes(value: Double) -> [Any] {
        return allIntTypes(value: value) + allNumTypes(value: value)
    }

}
