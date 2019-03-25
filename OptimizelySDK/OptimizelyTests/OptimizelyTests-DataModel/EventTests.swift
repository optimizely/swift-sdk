//
//  EventTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class EventTests: XCTestCase {
    static var sampleData: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"]]
}

// MARK: - Decode

extension EventTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"]]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750", "13139830210"])
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750"]]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750"])
    }
    
    func testDecodeSuccessWithJSONValid3() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": []]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == [])
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"], "extra": "123"]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750", "13139830210"])
    }
    
    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["key": "house", "experimentIds": ["12105773750", "13139830210"]]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        let data: [String: Any] = ["id": "553339214", "experimentIds": ["12105773750", "13139830210"]]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperimentIds() {
        let data: [String: Any] = ["id": "553339214", "key": "house"]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data: [String: Any] = [:]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
        
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let model = Event(id: "553339214",
                          key: "house",
                          experimentIds: ["12105773750", "13139830210"])
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(model))
    }
    
}
