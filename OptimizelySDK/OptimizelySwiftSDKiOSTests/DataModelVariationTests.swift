//
//  DataModelVariationTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelVariationTests: XCTestCase {

    let modelType = Variation.self
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "featureEnabled": true,
                                   "variables": [["id": "123450", "value": "100"], ["id": "123451", "value": "200"]]]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == true)
        XCTAssert(model.variables![0].id == "123450")
        XCTAssert(model.variables![0].value == "100")
        XCTAssert(model.variables![1].id == "123451")
        XCTAssert(model.variables![1].value == "200")
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "featureEnabled": false,
                                   "variables": []]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == false)
        XCTAssert(model.variables!.count == 0)
    }
    
    func testDecodeSuccessWithJSONValid3() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "featureEnabled": true]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == true)
        XCTAssert(model.variables == nil)
    }
    
    func testDecodeSuccessWithJSONValid4() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "variables": []]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == nil)
        XCTAssert(model.variables!.count == 0)
    }
    
    func testDecodeSuccessWithJSONValid5() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house"]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == nil)
        XCTAssert(model.variables == nil)
    }
    

    func testDecodeFailWithMissingId() {
        let json: [String: Any] = ["key": "house"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingKey() {
        let json: [String: Any] = ["id": "553339214"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithJSONEmpty() {
        let json: [String: Any] = [:]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    // MARK: - Encode

    func testEncodeJSON() {
        let modelGiven = modelType.init(id: "553339214",
                                        key: "house",
                                        featureEnabled: true,
                                        variables: [
                                            Variable(id: "123450", value: "100"),
                                            Variable(id: "123451", value: "200")])
        let jsonData = try! JSONEncoder().encode(modelGiven)
        let modelExp = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(modelExp.id == modelGiven.id)
        XCTAssert(modelExp.key == modelGiven.key)
        XCTAssert(modelExp.featureEnabled == modelGiven.featureEnabled)
        XCTAssert(modelExp.variables![0].id == modelGiven.variables![0].id)
        XCTAssert(modelExp.variables![0].value == modelGiven.variables![0].value)
        XCTAssert(modelExp.variables![1].id == modelGiven.variables![1].id)
        XCTAssert(modelExp.variables![1].value == modelGiven.variables![1].value)
    }
    
}
