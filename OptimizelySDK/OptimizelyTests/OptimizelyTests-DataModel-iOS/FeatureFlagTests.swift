//
//  FeatureFlagTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/8/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class FeatureFlagTests: XCTestCase {
    static var sampleData: [String: Any] = ["id": "553339214",
                                            "key": "house",
                                            "experimentIds":["12345", "12346"],
                                            "rolloutId":"34567",
                                            "variables":[FeatureVariableTests.sampleData]]
}

// MARK: - Decode

extension FeatureFlagTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = FeatureFlagTests.sampleData
        let model: FeatureFlag = try! modelFromNative(data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12345", "12346"])
        XCTAssert(model.rolloutId == "34567")
        XCTAssert(model.variables == [try! modelFromNative(FeatureVariableTests.sampleData)])
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag = try! modelFromNative(data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == [])
        XCTAssert(model.rolloutId == "34567")
        XCTAssert(model.variables.count == 0)
    }

    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["key": "house",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        let data: [String: Any] = ["id": "553339214",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingRolloutId() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":[],
                                   "variables":[]]
        let model: FeatureFlag? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperimentIds() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingVariables() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "rolloutId":"34567",
                                   "experimentIds":[]]
        let model: FeatureFlag? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
}

// MARK: - Encode

extension FeatureFlagTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = FeatureFlagTests.sampleData
        let modelGiven: FeatureFlag = try! modelFromNative(data)
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }

}
