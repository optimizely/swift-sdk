//
//  DMFeatureFlagTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/8/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DMFeatureFlagTests: XCTestCase {

    let modelType = FeatureFlag.self
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":["12345", "12346"],
                                   "rolloutId":"34567",
                                   "variables":[
                                    [
                                        "defaultValue":"20",
                                        "type":"integer",
                                        "id":"56789",
                                        "key":"price"
                                    ],
                                    [
                                        "defaultValue":"Jack",
                                        "type":"string",
                                        "id":"56780",
                                        "key":"name"
                                    ]]]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12345", "12346"])
        XCTAssert(model.rolloutId == "34567")
        XCTAssert(model.variables[0].id == "56789")
        XCTAssert(model.variables[0].key == "price")
        XCTAssert(model.variables[0].type == "integer")
        XCTAssert(model.variables[0].defaultValue == "20")
        XCTAssert(model.variables[1].id == "56780")
        XCTAssert(model.variables[1].key == "name")
        XCTAssert(model.variables[1].type == "string")
        XCTAssert(model.variables[1].defaultValue == "Jack")
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == [])
        XCTAssert(model.rolloutId == "34567")
        XCTAssert(model.variables.count == 0)
    }

    func testDecodeFailWithMissingId() {
        let json: [String: Any] = ["key": "house",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingKey() {
        let json: [String: Any] = ["id": "553339214",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingRolloutId() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":[],
                                   "variables":[]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithMissingExperimentIds() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "rolloutId":"34567",
                                   "variables":[]]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingVariables() {
        let json: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "rolloutId":"34567",
                                   "experimentIds":[]]
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
        let model = modelType.init(id: "553339214",
                                   key: "house",
                                   experimentIds: ["12345", "12346"],
                                   rolloutId: "34567",
                                   variables: [
                                    FeatureVariable(id:"56789", key:"price", type:"integer", defaultValue:"20"),
                                    FeatureVariable(id:"56780", key:"name", type:"string", defaultValue:"Jack")])
        XCTAssert(isEqualWithEncodeThenDecode(model))
    }

}
