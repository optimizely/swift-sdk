//
//  RolloutTests.swift
//  OptimizelySwiftSDK-iOSTests
//
//  Created by Jae Kim on 2/12/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class RolloutTests: XCTestCase {
    static var sampleData: [String: Any] = ["id": "11111",
                                            "experiments": [ExperimentTests.sampleData]]
}

// MARK: - Decode

extension RolloutTests {

    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = RolloutTests.sampleData
        
        let model: Rollout = try! modelFromNative(data)
        
        XCTAssert(model.id == "11111")
        XCTAssert(model.experiments == [try! modelFromNative(ExperimentTests.sampleData)])
    }
    
    func testDecodeFailWithMissingId() {
        var data: [String: Any] = RolloutTests.sampleData
        data["id"] = nil
        
        let model: Rollout? = try? modelFromNative(data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingExperiments() {
        var data: [String: Any] = RolloutTests.sampleData
        data["experiments"] = nil
        
        let model: Rollout? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
}

// MARK: - Encode

extension RolloutTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = RolloutTests.sampleData
        let modelGiven: Rollout = try! modelFromNative(data)
        
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
    
}

