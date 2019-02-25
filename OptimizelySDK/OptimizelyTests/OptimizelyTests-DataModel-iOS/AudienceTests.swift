//
//  AudienceTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/14/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class AudienceTests: XCTestCase {
    let modelType = Audience.self

    static var sampleData: [String: Any] = ["id": "553339214",
                                            "name": "america",
                                            "conditions": ConditionHolderTests.sampleData]
}

// MARK: - Decode (Legacy Audiences)

extension AudienceTests {

    func testDecodeSuccessWithLegacyAudience() {
        // legacy audience uses stringified conditions
        // - "[\"or\",{\"value\":30,\"type\":\"custom_attribute\",\"match\":\"exact\",\"name\":\"geo\"}]"
        // Audience will decode it to recover to typedAudience formats
        
        let legacyConditionString = jsonStringFromNative(ConditionHolderTests.sampleData)
        
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": legacyConditionString]
        let model: Audience = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! modelFromNative(ConditionHolderTests.sampleData)))
    }
    
}

// MARK: - Decode (Typed Audience)

extension AudienceTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": ConditionHolderTests.sampleData]
        let model: Audience = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! modelFromNative(ConditionHolderTests.sampleData)))
    }
    
    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["name": "america",
                                   "conditions": ConditionHolderTests.sampleData]
        let model: Audience? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingName() {
        let data: [String: Any] = ["id": "553339214",
                                   "conditions": ConditionHolderTests.sampleData]
        let model: Audience? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingConditions() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america"]
        let model: Audience? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    // not-array at top level of conditions (UserAttribute)
    
    func testDecodeSuccessWithNonArrayConditions() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": UserAttributeTests.sampleData]
        let model: Audience = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! modelFromNative(UserAttributeTests.sampleData)))
    }
    
}

// MARK: - Encode

extension AudienceTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": ConditionHolderTests.sampleData]
        let modelGiven: Audience = try! modelFromNative(data)

        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }

}
