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
    static var sampleData: [String: Any] = ["id": "11111",
                                            "key": "background",
                                            "status": "Running",
                                            "layerId": "22222",
                                            "variations": [VariationTests.sampleData],
                                            "trafficAllocation": [TrafficAllocationTests.sampleData],
                                            "audienceIds": ["33333"],
                                            "audienceConditions": ConditionHolderTests.sampleData,
                                            "forcedVariations": ["12345": "1234567890"]]
    
    static var emptyExperimentData: [String: Any] = ["id": "11111",
                                                     "key": "empty",
                                                     "status": "Running",
                                                     "layerId": "22222",
                                                     "variations": [],
                                                     "trafficAllocation": [],
                                                     "audienceIds": [],
                                                     "forcedVariations": []]
}

// MARK: - Decode

extension ExperimentTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ExperimentTests.sampleData
        let model: Experiment = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "11111")
        XCTAssert(model.key == "background")
        XCTAssert(model.status == .running)
        XCTAssert(model.layerId == "22222")
        XCTAssert(model.variations == [try! OTUtils.model(from: VariationTests.sampleData)])
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: TrafficAllocationTests.sampleData)])
        XCTAssert(model.audienceIds == ["33333"])
        XCTAssert(model.audienceConditions == (try! OTUtils.model(from: ConditionHolderTests.sampleData)))
        XCTAssert(model.forcedVariations == ["12345": "1234567890"])
    }
    
    func testDecodeSuccessWithMissingAudienceConditions() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["audienceConditions"] = nil
        
        let model: Experiment = try! OTUtils.model(from: data)

        XCTAssert(model.id == "11111")
        XCTAssert(model.key == "background")
        XCTAssert(model.status == .running)
        XCTAssert(model.layerId == "22222")
        XCTAssert(model.variations == [try! OTUtils.model(from: VariationTests.sampleData)])
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: TrafficAllocationTests.sampleData)])
        XCTAssert(model.audienceIds == ["33333"])
        XCTAssert(model.forcedVariations == ["12345": "1234567890"])
    }

    func testDecodeFailWithMissingId() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["id"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["key"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingStatus() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["status"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingLayerId() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["layerId"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingVariations() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["variations"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingTrafficAllocation() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["trafficAllocation"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingForcedVariations() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["forcedVariations"] = nil
        
        let model: Experiment? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

}

// MARK: - Encode

extension ExperimentTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = ExperimentTests.sampleData
        let modelGiven: Experiment = try! OTUtils.model(from: data)

        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
}

// MARK: - Test Utils

extension ExperimentTests {
    
    func testIsActivated() {
        let data: [String: Any] = ExperimentTests.sampleData
        var model: Experiment = try! OTUtils.model(from: data)
        
        XCTAssertTrue(model.isActivated)

        let allNotActiveStates: [Experiment.Status] = [.launched, .paused, .notStarted, .archived]
        for status in allNotActiveStates {
            model.status = status
            XCTAssertFalse(model.isActivated)
        }
        
        model.status = .running
        XCTAssertTrue(model.isActivated)
    }
}
