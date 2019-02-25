//
//  FeatureVariableTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class FeatureVariableTests: XCTestCase {
    static var sampleData = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100"]
}

// MARK: - Decode

extension FeatureVariableTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100"]
        let model: FeatureVariable = try! modelFromNative(data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "price")
        XCTAssert(model.type == "integer")
        XCTAssert(model.defaultValue == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100", "extra": "123"]
        let model: FeatureVariable = try! modelFromNative(data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "price")
        XCTAssert(model.type == "integer")
        XCTAssert(model.defaultValue == "100")
    }
    
    func testDecodeFailWithMissingId() {
        let data = ["key": "price", "type": "integer", "defaultValue": "100"]
        let model: FeatureVariable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        let data = ["id": "553339214", "type": "integer", "defaultValue": "100"]
        let model: FeatureVariable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingType() {
        let data = ["id": "553339214", "key": "price", "defaultValue": "100"]
        let model: FeatureVariable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingDefaultValue() {
        let data = ["id": "553339214", "key": "price", "type": "integer"]
        let model: FeatureVariable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data = [String: String]()
        let model: FeatureVariable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let model = FeatureVariable(id: "553339214", key: "price", type: "integer", defaultValue: "100")
        XCTAssert(isEqualWithEncodeThenDecode(model))
   }
}
