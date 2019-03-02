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
        let model = try! OTUtils.getAttributeValueFromNative(10)
        
        XCTAssert(model == AttributeValue.int(10))
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
        do {
            _ = try OTUtils.getAttributeValueFromNative(["invalid type"])
            XCTAssert(false)
        } catch is DecodingError {
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
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
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
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

