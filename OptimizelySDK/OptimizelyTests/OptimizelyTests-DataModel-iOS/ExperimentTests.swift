//
//  ExperimentTests.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/17/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

// MARK: - Sample Data

class ExperimentTests: XCTestCase {
    let modelType = Experiment.self
    
    
    static var sampleData: [String: Any] = ["id": "11111",
                                            "key": "background",
                                            "status": "Running",
                                            "layerId": "22222",
                                            "variations": [],
                                            "trafficAllocation": [],
                                            "audienceIds": ["33333"],
                                            //"audienceConditions": ConditionHolder?
                                            "forcedVariations": ["12345": "1234567890"]]

    func testDecodeSample() {
        let model: Experiment = try! modelFromNative(ExperimentTests.sampleData)
        
        XCTAssert(model.id == "11111")
    }
}

// MARK: - Decode

extension ExperimentTests {
    
//    func testDecodeSuccessWithJSONValid() {
//        let data: [String: Any] = ["id": "553339214",
//                                   "name": "america",
//                                   "conditions": ConditionHolderTests.sampleData]
//        let model: Audience = try! modelFromNative(data)
//        
//        XCTAssert(model.id == "553339214")
//        XCTAssert(model.name == "america")
//        XCTAssert(model.conditions == (try! modelFromNative(ConditionHolderTests.sampleData)))
//    }
//    
//    func testDecodeFailWithMissingId() {
//        let data: [String: Any] = ["name": "america",
//                                   "conditions": ConditionHolderTests.sampleData]
//        let model: Audience? = try? modelFromNative(data)
//        XCTAssertNil(model)
//    }
//    
//    func testDecodeFailWithMissingName() {
//        let data: [String: Any] = ["id": "553339214",
//                                   "conditions": ConditionHolderTests.sampleData]
//        let model: Audience? = try? modelFromNative(data)
//        XCTAssertNil(model)
//    }
//    
//    func testDecodeFailWithMissingConditions() {
//        let data: [String: Any] = ["id": "553339214",
//                                   "name": "america"]
//        let model: Audience? = try? modelFromNative(data)
//        XCTAssertNil(model)
//    }
}

// MARK: - Encode

extension ExperimentTests {
    
//    func testEncodeJSON() {
//        let data: [String: Any] = ["id": "553339214",
//                                   "name": "america",
//                                   "conditions": ConditionHolderTests.sampleData]
//        let modelGiven: Audience = try! modelFromNative(data)
//
//        XCTAssert(isEqualWithEncodeThenDecode(modelGiven))
//    }
    
}
