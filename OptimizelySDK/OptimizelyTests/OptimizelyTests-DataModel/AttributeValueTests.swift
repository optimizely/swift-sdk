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
        let value = "geo"
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.string(value))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.string(value))
    }
    
    func testDecodeSuccessWithInt() {
        // integer can be parsed as int or double (we catch as double first)
        
        let value = 10

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.int(value))
    }
    
    func testDecodeSuccessWithInt8() {
        let value = 10

        let model = try! OTUtils.getAttributeValueFromNative(Int8(value))
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: Int8(value))
        XCTAssert(model2 == AttributeValue.int(value))
    }

    func testDecodeSuccessWithInt16() {
        let value = 10

        let model = try! OTUtils.getAttributeValueFromNative(Int16(value))
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: Int16(value))
        XCTAssert(model2 == AttributeValue.int(value))
    }

    func testDecodeSuccessWithInt32() {
        let value = 10

        let model = try! OTUtils.getAttributeValueFromNative(Int32(value))
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: Int32(value))
        XCTAssert(model2 == AttributeValue.int(value))
    }

    func testDecodeSuccessWithInt64() {
        let value = 10

        let model = try! OTUtils.getAttributeValueFromNative(Int64(value))
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: Int64(value))
        XCTAssert(model2 == AttributeValue.int(value))
    }
    
    func testDecodeSuccessWithInt64_LargeValue() {
        let value = Int64(pow(2, 60) as Double)
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.int(Int(value)))
    }


    func testDecodeSuccessWithDouble() {
        let value = 13.5

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.double(value))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.double(value))
    }
    
    func testDecodeSuccessWithDouble2() {
        let value = 13.5

        let model = try! OTUtils.getAttributeValueFromNative(Double(value))
        XCTAssert(model == AttributeValue.double(value))
        
        let model2 = AttributeValue(value: Double(value))
        XCTAssert(model2 == AttributeValue.double(value))
    }

    func testDecodeSuccessWithFloat() {
        let value = 13.5

        // Float automatically parsed to Double OK
        let model = try! OTUtils.getAttributeValueFromNative(Float(value))
        XCTAssert(model == AttributeValue.double(value))
        
        let model2 = AttributeValue(value: Float(value))
        XCTAssert(model2 == AttributeValue.double(value))
    }

    func testDecodeSuccessWithBool() {
        let value = true

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.bool(value))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.bool(value))
    }
    
    func testDecodeSuccessWithInvalidType() {
        let value = ["invalid type"]

        let model = try! OTUtils.getAttributeValueFromNative(value)
        
        XCTAssert(model == AttributeValue.others)
        
        let model2 = AttributeValue(value: value)
        XCTAssertNil(model2)
    }
    
    func testDecodeSuccessWithInvalidTypeNil() {
        let anyNil: Any? = nil
        let model = try! OTUtils.getAttributeValueFromNative(anyNil)
        XCTAssert(model == AttributeValue.others)
        
        let model2 = AttributeValue(value: anyNil)
        XCTAssertNil(model2)
    }
    
    // MARK: - NSNumber
    // ObjC client apps can pass NSNumber, NSNull etc
    
    func testDecodeSuccessWithNSNumberTrue() {
        let value = NSNumber(value: true)
        let expValue = AttributeValue.bool(true)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumberFalse() {
        let value = NSNumber(value: false)
        let expValue = AttributeValue.bool(false)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber0() {
        let value = NSNumber(value: 0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1() {
        let value = NSNumber(value: 1)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber0_0() {
        let value = NSNumber(value: 0.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    func testDecodeSuccessWithNSNumber1_0() {
        let value = NSNumber(value: 1.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1_5() {
        let value = NSNumber(value: 1.5)
        let expValue = AttributeValue.double(1.5)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)

        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == expValue)
    }

    // MARK: - NSNull
    
    func testDecodeSuccessWithInvalidTypeNSNull() {
        let model = try! OTUtils.getAttributeValueFromNative(NSNull())

        // NSNull as Attribu
        XCTAssert(model == AttributeValue.others)
        
        // NSNull parsed same as nil
        let model2 = AttributeValue(value: NSNull())
        XCTAssertNil(model2)
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

