//
//  AttributeValueTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class AttributeValueTests: XCTestCase {
    
    // MARK: - Decode
    
    func testDecodeSuccessWithString() {
        let model = try! OTUtils.getAttributeValueFromNative("geo")
        
        XCTAssert(model == AttributeValue.string("geo"))
    }
    
    func testDecodeSuccessWithInt() {
        // integer can be parsed as int or double (we catch as double first)
        let model = try! OTUtils.getAttributeValueFromNative(10)
        
        XCTAssert(model == AttributeValue.int(10) ||
                model == AttributeValue.double(10.0))
    }

    func testDecodeSuccessWithDouble() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        
        XCTAssert(model == AttributeValue.double(13.5))
    }

    func testDecodeSuccessWithBool() {
        let model = try! OTUtils.getAttributeValueFromNative(true)
        
        XCTAssert(model == AttributeValue.bool(true))
    }
    
    func testDecodeSuccessWithInvalidType() {
        let model = try! OTUtils.getAttributeValueFromNative(["invalid type"])
        
        XCTAssert(model == AttributeValue.others)
    }
    
    // MARK: - NSNumber
    
    func testDecodeSuccessWithNSNumberTrue() {
        let value = NSNumber(value: true)
        let expValue = AttributeValue.bool(true)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumberFalse() {
        let value = NSNumber(value: false)
        let expValue = AttributeValue.bool(false)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber0() {
        let value = NSNumber(value: 0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1() {
        let value = NSNumber(value: 1)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber0_0() {
        let value = NSNumber(value: 0.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber1_0() {
        let value = NSNumber(value: 1.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1_5() {
        let value = NSNumber(value: 1.5)
        let expValue = AttributeValue.double(1.5)

        let model1 = AttributeValue(value: value)
        XCTAssert(model1 == expValue)
        
        let model2 = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model2 == expValue)
    }


}

// MARK: - Encode

extension AttributeValueTests {
    func testEncodeJSON() {
        let modelGiven = [AttributeValue.string("us")]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
    func testEncodeJSON2() {
        let modelGiven = [AttributeValue.int(10)]
        let doubleResult = [AttributeValue.double(10.0)]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven) ||    OTUtils.isEqualWithEncodeThenDecode(doubleResult))
    }
    
    func testEncodeJSON3() {
        let modelGiven = [AttributeValue.double(13.5)]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
    func testEncodeJSON4() {
        let modelGiven = [AttributeValue.bool(true)]
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
}

