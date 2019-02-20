//
//  TrafficAllocationTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class TrafficAllocationTests: XCTestCase {
    let modelType = TrafficAllocation.self
    
    static var sampleData: [String: Any] = ["entityId": "553339214", "endOfRange": 5000]
}

// MARK: - Decode

extension TrafficAllocationTests {

    func testDecodeSuccessWithJSONValid() {
        let json: [String: Any] = ["entityId": "553339214", "endOfRange": 5000]
        // JSONEncoder not happy with [String: Any]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.entityId == "553339214")
        XCTAssert(model.endOfRange == 5000)
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json: [String: Any] = ["entityId": "553339214", "endOfRange": 5000, "extra": "123"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        let model = try! JSONDecoder().decode(modelType, from: jsonData)

        XCTAssert(model.entityId == "553339214")
        XCTAssert(model.endOfRange == 5000)
    }

    func testDecodeFailWithMissingEntityId() {
        let json: [String: Any] = ["endOfRange": 5000]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])

        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingEndOfRange() {
        let json: [String: Any] = ["entityId": "553339214"]
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithJSONEmpty() {
        let json = [String: Any]()
        let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
        
        do {
            _ = try JSONDecoder().decode(modelType, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
}

// MARK: - Encode

extension TrafficAllocationTests {
    
    func testEncodeJSON() {
        let model = modelType.init(entityId: "553339214", endOfRange: 5000)
        XCTAssert(isEqualWithEncodeThenDecode(model))
    }

}
