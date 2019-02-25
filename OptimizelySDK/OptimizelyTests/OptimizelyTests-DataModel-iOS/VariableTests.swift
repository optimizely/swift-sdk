//
//  VariableTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class VariableTests: XCTestCase {
    static var sampleData = ["id": "553339214", "value": "100"]
}

// MARK: - Decode

extension VariableTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data = ["id": "553339214", "value": "100"]
        let model: Variable = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.value == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data = ["id": "553339214", "value": "100", "extra": "123"]
        let model: Variable = try! modelFromNative(data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.value == "100")
    }
    
    func testDecodeFailWithMissingKey() {
        let data = ["id": "553339214"]
        let model: Variable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingId() {
        let data = ["value": "100"]
        let model: Variable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data = [String: String]()
        let model: Variable? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
}
    
    // MARK: - Encode

extension VariableTests {
    
    func testEncodeJSON() {
        let model = Variable(id: "553339214", value: "100")
        XCTAssert(isEqualWithEncodeThenDecode(model))
    }
    
}
