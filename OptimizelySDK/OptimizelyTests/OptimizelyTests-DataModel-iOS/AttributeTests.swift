//
//  AttributeTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class AttributeTests: XCTestCase {
    static var sampleData = ["id": "553339214", "key": "house"]
}

// MARK: - Decode

extension AttributeTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data = ["id": "553339214", "key": "house"]
        let model: Attribute = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data = ["id": "553339214", "key": "house", "extra": "123"]
        let model: Attribute = try! modelFromNative(data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
    }

    func testDecodeFailWithMissingKey() {
        let data = ["id": "553339214"]
        let model: Attribute? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingId() {
        let data = ["key": "house"]
        let model: Attribute? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data = [String: String]()
        let model: Attribute? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let modelGiven = Attribute(id: "553339214", key: "house")
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
}


