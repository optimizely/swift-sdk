//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        XCTAssert(model.cmab == nil)
    }
    
    func testDecodeSuccessWithCmab() {
        var data: [String: Any] = ExperimentTests.sampleData
        data["cmab"] = ["trafficAllocation": 5000, "attributeIds": ["id_1", "id_2"]]
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
        XCTAssert(model.cmab == (try? OTUtils.model(from: ["trafficAllocation": 5000, "attributeIds": ["id_1", "id_2"]])))
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

// MARK: - audiences serialization

extension ExperimentTests {

    func testAudiencesSerialization() {
        let commonData: [String: Any] = ["id": "11111",
                                         "key": "background",
                                         "status": "Running",
                                         "layerId": "22222",
                                         "variations": [VariationTests.sampleData],
                                         "trafficAllocation": [TrafficAllocationTests.sampleData],
                                         "audienceIds": [],
                                         "audienceConditions": [],
                                         "forcedVariations": ["12345": "1234567890"]]
        
        let audiencesMap = [
            "1": "us",
            "11": "fr",
            "2": "female",
            "12": "male",
            "3": "adult",
            "13": "kid"
        ]
        
        let audiencesInput: [Any] = [
            [],
            ["or", "1", "2"],
            ["and", "1", "2", "3"],
            ["not", "1"],
            ["or", "1"],
            ["and", "1"],
            ["1"],
            ["1", "2"],
            ["and", ["or", "1", "2"], "3"],
            ["and", ["or", "1", ["and", "2", "3"]], ["and", "11", ["or", "12", "13"]]],
            ["not", ["and", "1", "2"]],
            ["or", "1", "100000"],
            ["and", "and"]
        ]
        
        let audiencesOutput: [String] = [
            "",
            "\"us\" OR \"female\"",
            "\"us\" AND \"female\" AND \"adult\"",
            "NOT \"us\"",
            "\"us\"",
            "\"us\"",
            "\"us\"",
            "\"us\" OR \"female\"",
            "(\"us\" OR \"female\") AND \"adult\"",
            "(\"us\" OR (\"female\" AND \"adult\")) AND (\"fr\" AND (\"male\" OR \"kid\"))",
            "NOT (\"us\" AND \"female\")",
            "\"us\" OR \"100000\"",
            ""
        ]
        
        for (idx, audience) in audiencesInput.enumerated() {
            var data = commonData
            data["audienceConditions"] = audience
            var model: Experiment = try! OTUtils.model(from: data)
            model.serializeAudiences(with: audiencesMap)
            XCTAssertEqual(model.audiences, audiencesOutput[idx])
        }
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
