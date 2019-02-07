//
//  DataModelVariableTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelVariableTests: XCTestCase {
    
    let modelType = Variable.self

    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json = ["id": "553339214", "value": "100"]
        let jsonData = try! JSONEncoder().encode(json)
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.value == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json = ["id": "553339214", "value": "100", "extra": "123"]
        let jsonData = try! JSONEncoder().encode(json)
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.value == "100")
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
        let modelGiven = modelType.init(id: "553339214", value: "100")
        
        let jsonData = try! JSONEncoder().encode(modelGiven)
        let modelExp = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(modelExp.id == modelGiven.id)
        XCTAssert(modelExp.value == modelGiven.value)
    }
}
