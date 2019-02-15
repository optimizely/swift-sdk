//
//  DataModelAudienceTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/14/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DataModelAudienceTests: XCTestCase {

    let modelType = Audience.self
    
    // MARK: - Decode (Legacy Audiences)
    
    
//    func testDecodeSuccessWithLegacyAudience_SingleCondition() {
//        let json = ["id": "553339214",
//                    "name": "america",
//                    "conditions": DataModelUserAttributeTests.baseModelJsonString()]
//        let jsonData = try! JSONEncoder().encode(json)
//        let model = try! JSONDecoder().decode(modelType, from: jsonData)
//        
//        XCTAssert(model.id == "553339214")
//        XCTAssert(model.name == "america")
//        XCTAssert(model.conditions == ConditionHolder.userAttribute(DataModelUserAttributeTests.baseModel())
//    }
//    
//    func testDecodeSuccessWithLegacyAudience_OrCondtition() {
//        let json = ["id": "553339214",
//                    "name": "america",
//                    "conditions": "[\"and\", \()]"]
//        let jsonData = try! JSONEncoder().encode(json)
//        let model = try! JSONDecoder().decode(modelType, from: jsonData)
//        
//        XCTAssert(model.id == "553339214")
//        XCTAssert(model.name == "america")
//        XCTAssert(model.conditions.)
//    }
//
//    func testDecodeSuccessWithLegacyAudience_AndCondtition() {
//        let json = ["id": "553339214",
//                    "name": "america",
//                    "conditions": "[\"or\", {\"match\": \"exact\", \"name\": \"country\", \"type\": \"custom_attribute\", \"value\": \"us\"}]"]
//        let jsonData = try! JSONEncoder().encode(json)
//        let model = try! JSONDecoder().decode(modelType, from: jsonData)
//        
//        XCTAssert(model.id == "553339214")
//        XCTAssert(model.name == "america")
//        XCTAssert(model.conditions.)
//    }
//
//    func testDecodeSuccessWithLegacyAudience_NotCondtition() {
//        let json = ["id": "553339214",
//                    "name": "america",
//                    "conditions": "[\"not\", {\"match\": \"exact\", \"name\": \"country\", \"type\": \"custom_attribute\", \"value\": \"us\"}]"]
//        let jsonData = try! JSONEncoder().encode(json)
//        let model = try! JSONDecoder().decode(modelType, from: jsonData)
//        
//        XCTAssert(model.id == "553339214")
//        XCTAssert(model.name == "america")
//        XCTAssert(model.conditions.)
//    }
//
//    
//    // MARK: - Decode (Typed Audiences)
//    
//    func testDecodeSuccessWithExtraFields() {
//        let json = ["id": "553339214", "key": "house", "extra": "123"]
//        let jsonData = try! JSONEncoder().encode(json)
//        let model = try! JSONDecoder().decode(modelType, from: jsonData)
//        
//        XCTAssert(model.id == "553339214")
//        XCTAssert(model.key == "house")
//    }
//    
//    func testDecodeFailWithMissingKey() {
//        let json = ["id": "553339214"]
//        let jsonData = try! JSONEncoder().encode(json)
//        do {
//            _ = try JSONDecoder().decode(modelType, from: jsonData)
//            XCTAssert(false)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//    
//    func testDecodeFailWithMissingId() {
//        let json = ["key": "house"]
//        let jsonData = try! JSONEncoder().encode(json)
//        do {
//            _ = try JSONDecoder().decode(modelType, from: jsonData)
//            XCTAssert(false)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//    
//    func testDecodeFailWithJSONEmpty() {
//        let json = [String: String]()
//        let jsonData = try! JSONEncoder().encode(json)
//        do {
//            _ = try JSONDecoder().decode(modelType, from: jsonData)
//            XCTAssert(false)
//        } catch {
//            XCTAssert(true)
//        }
//    }
//    
//    // MARK: - Encode
//    
//    func testEncodeJSON() {
//        let modelGiven = modelType.init(id: "553339214", key: "house")
//        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
//    }

}
