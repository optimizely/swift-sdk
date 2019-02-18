//
//  FeatureVariableTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class FeatureVariableTests: XCTestCase {
    
    let modelType = FeatureVariable.self
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "price")
        XCTAssert(model.type == "integer")
        XCTAssert(model.defaultValue == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100", "extra": "123"]
        let jsonData = try! JSONEncoder().encode(json)
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "price")
        XCTAssert(model.type == "integer")
        XCTAssert(model.defaultValue == "100")
    }
    
    func testDecodeFailWithMissingId() {
        let json = ["key": "price", "type": "integer", "defaultValue": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingKey() {
        let json = ["id": "553339214", "type": "integer", "defaultValue": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingType() {
        let json = ["id": "553339214", "key": "price", "defaultValue": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingDefaultValue() {
        let json = ["id": "553339214", "key": "price", "type": "integer"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithJSONEmpty() {
        let json = [String: String]()
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let model = modelType.init(id: "553339214", key: "price", type: "integer", defaultValue: "100")
        XCTAssert(isEqualWithEncodeThenDecode(model))
   }
}
