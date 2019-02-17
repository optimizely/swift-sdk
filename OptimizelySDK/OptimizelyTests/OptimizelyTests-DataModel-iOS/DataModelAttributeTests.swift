//
//  DataModelAttributeTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelAttributeTests: XCTestCase {
    
    let modelType = Attribute.self

    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json = ["id": "553339214", "key": "house"]
        let jsonData = try! JSONEncoder().encode(json)
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json = ["id": "553339214", "key": "house", "extra": "123"]
        let jsonData = try! JSONEncoder().encode(json)
        let model = try! JSONDecoder().decode(modelType, from: jsonData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
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
        let json = ["key": "house"]
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
        let modelGiven = modelType.init(id: "553339214", key: "house")
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
}


