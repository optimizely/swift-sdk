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
        
        XCTAssert(model == AttributeValue.double(10.0))
    }

    func testDecodeSuccessWithDouble() {
        let model = try! OTUtils.getAttributeValueFromNative(13.5)
        
        XCTAssert(model == AttributeValue.double(13.5))
    }
    
    func testDecodeSuccessWithDouble2() {
        let model = try! OTUtils.getAttributeValueFromNative(Double(13.5))
        
        XCTAssert(model == AttributeValue.double(13.5))
    }

    func testDecodeSuccessWithFloat() {
        // Float automatically parsed to Double OK
        let model = try! OTUtils.getAttributeValueFromNative(Float(13.5))
        
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
    
    func testDecodeSuccessWithInvalidTypeNil() {
        let anyNil: Any? = nil
        let model = try! OTUtils.getAttributeValueFromNative(anyNil)
        
        XCTAssert(model == AttributeValue.others)
    }
    
    // MARK: - NSNumber
    // ObjC client apps can pass NSNumber, NSNull etc
    
    func testDecodeSuccessWithNSNumberTrue() {
        let value = NSNumber(value: true)
        let expValue = AttributeValue.bool(true)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }
    
    func testDecodeSuccessWithNSNumberFalse() {
        let value = NSNumber(value: false)
        let expValue = AttributeValue.bool(false)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }

    func testDecodeSuccessWithNSNumber0() {
        let value = NSNumber(value: 0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1() {
        let value = NSNumber(value: 1)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }

    func testDecodeSuccessWithNSNumber0_0() {
        let value = NSNumber(value: 0.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }

    func testDecodeSuccessWithNSNumber1_0() {
        let value = NSNumber(value: 1.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }
    
    func testDecodeSuccessWithNSNumber1_5() {
        let value = NSNumber(value: 1.5)
        let expValue = AttributeValue.double(1.5)

        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == expValue)
    }

    // MARK: - NSNull
    
    func testDecodeSuccessWithInvalidTypeNSNull() {
        let model = try! OTUtils.getAttributeValueFromNative(NSNull())

        // NSNull as Attribu
        XCTAssert(model == AttributeValue.others)
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

// MARK: - Init

extension AttributeValueTests {
    func testInitSuccessWithString() {
        let model = AttributeValue(value: "geo")
        XCTAssert(model == AttributeValue.string("geo"))
    }
    
    func testIntSuccessWithInt() {
        // Int -> Int, Double -> Double
        let model = AttributeValue(value: 10)
        XCTAssert(model == AttributeValue.int(10))
    }
    
    func testInitSuccessWithDouble() {
        let model = AttributeValue(value: 13.5)
        XCTAssert(model == AttributeValue.double(13.5))
    }
    
    func testInitSuccessWithDouble2() {
        let model = AttributeValue(value: Double(13.5))
        XCTAssert(model == AttributeValue.double(13.5))
    }
    
    func testInitSuccessWithFloat() {
        // Float is converted to Double
        let model = AttributeValue(value: Float(13.5))
        XCTAssert(model == AttributeValue.double(13.5))
    }
    
    func testInitSuccessWithBool() {
        let model = AttributeValue(value: true)
        XCTAssert(model == AttributeValue.bool(true))
    }
    
    func testInitSuccessWithInvalidType() {
        let model = AttributeValue(value: ["invalid type"])
        XCTAssertNil(model)
    }
    
    func testInitSuccessWithInvalidTypeNil() {
        let anyNil: Any? = nil
        let model = AttributeValue(value: anyNil)

        XCTAssertNil(model)
    }
    
    // MARK: - Init with NSNumber
    
    func testInitSuccessWithNSNumberTrue() {
        let value = NSNumber(value: true)
        let expValue = AttributeValue.bool(true)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    func testInitSuccessWithNSNumberFalse() {
        let value = NSNumber(value: false)
        let expValue = AttributeValue.bool(false)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    func testInitSuccessWithNSNumber0() {
        let value = NSNumber(value: 0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    func testInitSuccessWithNSNumber1() {
        let value = NSNumber(value: 1)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    func testInitSuccessWithNSNumber0_0() {
        let value = NSNumber(value: 0.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(0.0)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    func testInitSuccessWithNSNumber1_0() {
        let value = NSNumber(value: 1.0)
        // can be either int or double (we catch as double first)
        let expValue = AttributeValue.double(1.0)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    func testInitSuccessWithNSNumber1_5() {
        let value = NSNumber(floatLiteral: 1.5)
        let expValue = AttributeValue.double(1.5)
        
        let model = AttributeValue(value: value)
        XCTAssert(model == expValue)
    }
    
    // MARK: - Init with NSNull
    
    func testInitSuccessWithInvalidTypeNSNull() {
        // NSNull parsed same as nil
        let model = AttributeValue(value: NSNull())
        XCTAssertNil(model)
    }
}
