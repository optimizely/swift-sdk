//
//  DMAudienceTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/14/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class DMAudienceTests: XCTestCase {
    let modelType = Audience.self

    static var sampleData: [String: Any] = ["id": "553339214",
                                            "name": "america",
                                            "conditions": DMConditionHolderTests.sampleData]
    
    func testDecodeSample() {
        let model: Audience = try! modelFromNative(DMAudienceTests.sampleData)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! modelFromNative(DMConditionHolderTests.sampleData)))
    }
}

// MARK: - Decode (Legacy Audiences)

extension DMAudienceTests {

    func testDecodeSuccessWithLegacyAudience() {
        // legacy audience uses stringified conditions
        // - "[\"or\",{\"value\":30,\"type\":\"custom_attribute\",\"match\":\"exact\",\"name\":\"geo\"}]"
        // Audience will decode it to recover to typedAudience formats
        
        let legacyConditionString = jsonStringFromNative(DMConditionHolderTests.sampleData)
        
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": legacyConditionString]
        let model: Audience = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! modelFromNative(DMConditionHolderTests.sampleData)))
    }
    
}

// MARK: - Decode (Typed Audience)

extension DMAudienceTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": DMConditionHolderTests.sampleData]
        let model: Audience = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! modelFromNative(DMConditionHolderTests.sampleData)))
    }
    
    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["name": "america",
                                   "conditions": DMConditionHolderTests.sampleData]
        let model: Audience? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingName() {
        let data: [String: Any] = ["id": "553339214",
                                   "conditions": DMConditionHolderTests.sampleData]
        let model: Audience? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingConditions() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america"]
        let model: Audience? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
}

// MARK: - Encode

extension DMAudienceTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": DMConditionHolderTests.sampleData]
        let modelGiven: Audience = try! modelFromNative(data)

        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }

}
