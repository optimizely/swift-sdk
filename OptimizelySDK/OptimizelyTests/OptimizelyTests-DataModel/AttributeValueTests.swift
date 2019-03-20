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
    
    func testDocodeSuccessWithAllIntTypes() {
        let value = 10
        
        let tests = [
            [Int(value), Double(value), Int64(value)],
            [Int8(value), Double(value), Int64(value)],
            [Int16(value), Double(value), Int64(value)],
            [Int32(value), Double(value), Int64(value)],
            [Int64(value), Double(value), Int64(value)],
            [UInt(value), Double(value), Int64(value)],
            [UInt8(value), Double(value), Int64(value)],
            [UInt16(value), Double(value), Int64(value)],
            [UInt32(value), Double(value), Int64(value)],
            [UInt64(value), Double(value), Int64(value)]
        ]
        
        for (idx, test) in tests.enumerated() {
            let inputValue = test[0]
            let expModelValue = test[1] as! Double
            let expModel2Value = test[2] as! Int64
            
            // integer can be parsed as int or double (we catch as double first)
            let model = try! OTUtils.getAttributeValueFromNative(inputValue)
            XCTAssert(model == AttributeValue.double(expModelValue), "int type error with index = \(idx)")
            
            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.int(expModel2Value), "int type error with index = \(idx)")
        }
    }
    
    func testDocodeSuccessWithAllNumberTypes() {
        let value = 13.5
        
        let tests = [
            [Double(value), Double(value), Double(value)],
            [Float(value), Double(value), Double(value)],
            [Float32(value), Double(value), Double(value)],
            [Float64(value), Double(value), Double(value)]
        ]
        
        for (idx, test) in tests.enumerated() {
            let inputValue = test[0]
            let expModelValue = test[1] as! Double
            let expModel2Value = test[2] as! Double
            
            let model = try! OTUtils.getAttributeValueFromNative(inputValue)
            XCTAssert(model == AttributeValue.double(expModelValue), "num type error with index = \(idx)")

            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.double(expModel2Value), "num type error with index = \(idx)")
        }
        
        // Float80 is not supported JSON parser (it's not expected to see this from datafile, but it still
        // can be passed as attribute values from client app
        let testsAttributesOnly = [
            [Float80(value), Double(value)]
        ]
        
        for (idx, test) in testsAttributesOnly.enumerated() {
            let inputValue = test[0]
            let expModel2Value = test[1] as! Double
            
            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.double(expModel2Value), "num type error with index = \(idx)")
        }
    }
    
    func testDecodeSuccessWithAllBoolTypes() {
        let tests = [
            [true, true, true],
            [false, false, false]
        ]
        
        for (idx, test) in tests.enumerated() {
            let inputValue = test[0]
            let expModelValue = test[1]
            let expModel2Value = test[2]
            
            // integer can be parsed as int or double (we catch as double first)
            let model = try! OTUtils.getAttributeValueFromNative(inputValue)
            XCTAssert(model == AttributeValue.bool(expModelValue), "bool type error with index = \(idx)")
            
            let model2 = AttributeValue(value: inputValue)
            XCTAssert(model2 == AttributeValue.bool(expModel2Value), "bool type error with index = \(idx)")
        }
     }
    
    func testDecodeSuccessWithInt64_LargeValue() {
        let value = Int64(pow(2, 60) as Double)
        
        let model = try! OTUtils.getAttributeValueFromNative(value)
        XCTAssert(model == AttributeValue.double(Double(value)))
        
        let model2 = AttributeValue(value: value)
        XCTAssert(model2 == AttributeValue.int(Int64(value)))
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

