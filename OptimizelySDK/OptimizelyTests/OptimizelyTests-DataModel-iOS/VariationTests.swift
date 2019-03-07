//
//  VariationTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class VariationTests: XCTestCase {
    static var sampleData: [String: Any] = ["id": "553339214",
                                            "key": "house",
                                            "featureEnabled": true,
                                            "variables": [VariableTests.sampleData]]
}

// MARK: - Decode

extension VariationTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "featureEnabled": true,
                                   "variables": [["id": "123450", "value": "100"], ["id": "123451", "value": "200"]]]
        let model: Variation = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == true)
        XCTAssert(model.variables![0].id == "123450")
        XCTAssert(model.variables![0].value == "100")
        XCTAssert(model.variables![1].id == "123451")
        XCTAssert(model.variables![1].value == "200")
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "featureEnabled": false,
                                   "variables": []]
        let model: Variation = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == false)
        XCTAssert(model.variables!.count == 0)
    }
    
    func testDecodeSuccessWithJSONValid3() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "featureEnabled": true]
        let model: Variation = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == true)
        XCTAssert(model.variables == nil)
    }
    
    func testDecodeSuccessWithJSONValid4() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "variables": []]
        let model: Variation = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == nil)
        XCTAssert(model.variables!.count == 0)
    }
    
    func testDecodeSuccessWithJSONValid5() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house"]
        let model: Variation = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.featureEnabled == nil)
        XCTAssert(model.variables == nil)
    }
    

    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["key": "house"]
        let model: Variation? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingKey() {
        let data: [String: Any] = ["id": "553339214"]
        let model: Variation? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithJSONEmpty() {
        let data: [String: Any] = [:]
        let model: Variation? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
}

// MARK: - Encode

extension VariationTests {
    
    func testEncodeJSON() {
        let model = Variation(id: "553339214",
                                   key: "house",
                                   featureEnabled: true,
                                   variables: [
                                    Variable(id: "123450", value: "100"),
                                    Variable(id: "123451", value: "200")])
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(model))
    }
    
}
