//
//  GroupTests.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/19/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class GroupTests: XCTestCase {
    static var sampleData: [String: Any] = ["id": "11111",
                                            "policy": "random",
                                            "trafficAllocation": [TrafficAllocationTests.sampleData],
                                            "experiments": [ExperimentTests.sampleData]]
}

// MARK: - Decode

extension GroupTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = GroupTests.sampleData
        
        let model: Group = try! modelFromNative(data)
        
        XCTAssert(model.id == "11111")
        XCTAssert(model.policy == .random)
        XCTAssert(model.trafficAllocation == [try! modelFromNative(TrafficAllocationTests.sampleData)])
        XCTAssert(model.experiments == [try! modelFromNative(ExperimentTests.sampleData)])
    }
    
    func testDecodeFailWithMissingId() {
        var data: [String: Any] = GroupTests.sampleData
        data["id"] = nil
        
        let model: Group? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperiments() {
        var data: [String: Any] = GroupTests.sampleData
        data["experiments"] = nil
        
        let model: Group? = try? modelFromNative(data)
        XCTAssertNil(model)
    }
    
}

// MARK: - Encode

extension GroupTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = GroupTests.sampleData
        let modelGiven: Group = try! modelFromNative(data)
        
        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
    }
    
}

