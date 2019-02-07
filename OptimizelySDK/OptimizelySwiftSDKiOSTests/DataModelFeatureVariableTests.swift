//
//  DataModelFeatureVariableTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelFeatureVariableTests: XCTestCase {
    
    let modelType = OPTFeatureVariable.self
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        let variable = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(variable.id == "553339214")
        XCTAssert(variable.key == "price")
        XCTAssert(variable.type == "integer")
        XCTAssert(variable.defaultValue == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100", "extra": "123"]
        let jsonData = try! JSONEncoder().encode(json)
        let variable = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(variable.id == "553339214")
        XCTAssert(variable.key == "price")
        XCTAssert(variable.type == "integer")
        XCTAssert(variable.defaultValue == "100")
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
        let variableGiven = modelType.init(id: "553339214", key: "price", type: "integer", defaultValue: "100")
        
        let jsonData = try! JSONEncoder().encode(variableGiven)
        let variableExp = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(variableExp.id == variableGiven.id)
        XCTAssert(variableExp.key == variableGiven.key)
        XCTAssert(variableExp.type == variableGiven.type)
        XCTAssert(variableExp.defaultValue == variableGiven.defaultValue)
   }
}
