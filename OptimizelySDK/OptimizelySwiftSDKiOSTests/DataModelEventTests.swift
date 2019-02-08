//
//  DataModelEventTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelEventTests: XCTestCase {

    let modelType = Event.self
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"]]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750", "13139830210"])
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let json: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750"])
    }

    func testDecodeSuccessWithJSONValid3() {
        let json: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": []]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == [])
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"], "extra": "123"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750", "13139830210"])
    }
    
    func testDecodeFailWithMissingId() {
        let json: [String: Any] = ["key": "house", "experimentIds": ["12105773750", "13139830210"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingKey() {
        let json: [String: Any] = ["id": "553339214", "experimentIds": ["12105773750", "13139830210"]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingExperimentIds() {
        let json: [String: Any] = ["id": "553339214", "key": "house"]
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
        let modelGiven = modelType.init(id: "553339214", key: "house", experimentIds: ["12105773750", "13139830210"])
        let jsonData = try! JSONEncoder().encode(modelGiven)
        let modelExp = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(modelExp.id == modelGiven.id)
        XCTAssert(modelExp.key == modelGiven.key)
        XCTAssert(modelExp.experimentIds == modelGiven.experimentIds)
    }

}
