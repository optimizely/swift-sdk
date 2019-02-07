//
//  DataModelVariableTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelVariableTests: XCTestCase {
    
    let modelType = OPTVariable.self

    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json = ["id": "553339214", "value": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        let variable = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(variable.id == "553339214")
        XCTAssert(variable.value == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json = ["id": "553339214", "value": "100", "extra": "123"]
        let jsonData = try! JSONEncoder().encode(json)
        let variable = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(variable.id == "553339214")
        XCTAssert(variable.value == "100")
    }
    
    func testDecodeFailWithMissingKey() {
        let json = ["id": "553339214"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingId() {
        let json = ["value": "100"]
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
        let variableGiven = modelType.init(id: "553339214", value: "100")
        
        let jsonData = try! JSONEncoder().encode(variableGiven)
        let variableExp = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(variableExp.id == variableGiven.id)
        XCTAssert(variableExp.value == variableGiven.value)
    }
}
