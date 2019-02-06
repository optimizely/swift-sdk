//
//  DataModelAttributeTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/6/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelAttributeTests: XCTestCase {
    
    // MARK: - Decode
    
    func testDecodeSuccessWithJSONValid() {
        let json = ["id": "553339214", "key": "house"]
        let jsonData = try! JSONEncoder().encode(json)
        let attribute = try! JSONDecoder().decode(OPTAttribute.self, from: jsonData)
        
        XCTAssert(attribute.id == "553339214")
        XCTAssert(attribute.key == "house")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let json = ["id": "553339214", "key": "house", "extra": "123"]
        let jsonData = try! JSONEncoder().encode(json)
        let attribute = try! JSONDecoder().decode(OPTAttribute.self, from: jsonData)
        
        XCTAssert(attribute.id == "553339214")
        XCTAssert(attribute.key == "house")
    }

    func testDecodeFailWithMissingKey() {
        let json = ["id": "553339214"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(OPTAttribute.self, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testDecodeFailWithMissingId() {
        let json = ["key": "house"]
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(OPTAttribute.self, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    func testDecodeFailWithJSONEmpty() {
        let json = [String: String]()
        let jsonData = try! JSONEncoder().encode(json)
        do {
            _ = try JSONDecoder().decode(OPTAttribute.self, from: jsonData)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let attributeGiven = OPTAttribute(id: "553339214", key: "house")
        
        let jsonData = try! JSONEncoder().encode(attributeGiven)
        let attributeExp = try! JSONDecoder().decode(OPTAttribute.self, from: jsonData)

        XCTAssert(attributeExp.id == attributeGiven.id)
        XCTAssert(attributeExp.key == attributeGiven.key)
    }


}
