//
// Copyright 2022, Optimizely, Inc. and contributors 
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

class HoldoutTests: XCTestCase {
    static var variationData: [String: Any] = ["id": "553339214",
                                               "key": "house",
                                               "featureEnabled": false]
    
    static var trafficAllocationData: [String: Any] = ["entityId": "553339214", "endOfRange": 5000]
    
    static var conditionHolderData: [Any] = ["or", ["name": "geo",
                                           "type": "custom_attribute",
                                           "match": "exact",
                                           "value": 30]]
    
    /// Global holoout without  included and excluded key
    static var sampleData: [String: Any] = ["id": "11111",
                                            "key": "background",
                                            "status": "Running",
                                            "layerId": "22222",
                                            "variations": [HoldoutTests.variationData],
                                            "trafficAllocation": [HoldoutTests.trafficAllocationData],
                                            "audienceIds": ["33333"],
                                            "audienceConditions": HoldoutTests.conditionHolderData]
    
    static var sampleDataWithIncludedFlags: [String: Any] = ["id": "55555",
                                            "key": "background",
                                            "status": "Running",
                                            "layerId": "22222",
                                            "variations": [HoldoutTests.variationData],
                                            "trafficAllocation": [HoldoutTests.trafficAllocationData],
                                            "audienceIds": ["33333"],
                                            "audienceConditions": HoldoutTests.conditionHolderData,
                                            "includedFlags": ["4444", "5555"]]
    
    static var sampleDataWithExcludedFlags: [String: Any] = ["id": "3333",
                                                             "key": "background",
                                                             "status": "Running",
                                                             "layerId": "22222",
                                                             "variations": [HoldoutTests.variationData],
                                                             "trafficAllocation": [HoldoutTests.trafficAllocationData],
                                                             "audienceIds": ["33333"],
                                                             "audienceConditions": HoldoutTests.conditionHolderData,
                                                             "excludedFlags": ["8888", "9999"]]
    
    
    
}

// MARK: - Decode

extension HoldoutTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = HoldoutTests.sampleData
        let model: Holdout = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "11111")
        XCTAssert(model.key == "background")
        XCTAssert(model.status == .running)
        XCTAssert(model.layerId == "22222")
        XCTAssert(model.variations == [try! OTUtils.model(from: HoldoutTests.variationData)])
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: HoldoutTests.trafficAllocationData)])
        XCTAssert(model.audienceIds == ["33333"])
        XCTAssert(model.audienceConditions == (try! OTUtils.model(from: HoldoutTests.conditionHolderData)))
    }
    
    func testDecodeSuccessWithIncludedFlags() {
        let data: [String: Any] = HoldoutTests.sampleDataWithIncludedFlags
        
        let model: Holdout = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "55555")
        XCTAssert(model.key == "background")
        XCTAssert(model.status == .running)
        XCTAssert(model.layerId == "22222")
        XCTAssert(model.variations == [try! OTUtils.model(from: HoldoutTests.variationData)])
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: HoldoutTests.trafficAllocationData)])
        XCTAssert(model.audienceIds == ["33333"])
        XCTAssert(model.audienceConditions == (try! OTUtils.model(from: HoldoutTests.conditionHolderData)))
        XCTAssertEqual(model.includedFlags, ["4444", "5555"])
    }
    
    func testDecodeSuccessWithExcludedFlags() {
        let data: [String: Any] = HoldoutTests.sampleDataWithExcludedFlags
        
        let model: Holdout = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "3333")
        XCTAssert(model.key == "background")
        XCTAssert(model.status == .running)
        XCTAssert(model.layerId == "22222")
        XCTAssert(model.variations == [try! OTUtils.model(from: HoldoutTests.variationData)])
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: HoldoutTests.trafficAllocationData)])
        XCTAssert(model.audienceIds == ["33333"])
        XCTAssert(model.audienceConditions == (try! OTUtils.model(from: HoldoutTests.conditionHolderData)))
        XCTAssertEqual(model.includedFlags, [])
        XCTAssertEqual(model.excludedFlags, ["8888", "9999"])
    }
    

    func testDecodeSuccessWithMissingAudienceConditions() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["audienceConditions"] = nil
        
        let model: Holdout = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "11111")
        XCTAssert(model.key == "background")
        XCTAssert(model.status == .running)
        XCTAssert(model.layerId == "22222")
        XCTAssert(model.variations == [try! OTUtils.model(from: HoldoutTests.variationData)])
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: HoldoutTests.trafficAllocationData)])
        XCTAssert(model.audienceIds == ["33333"])
    }
    
    func testDecodeFailWithMissingId() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["id"] = nil
        
        let model: Holdout? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["key"] = nil
        
        let model: Holdout? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingStatus() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["status"] = nil
        
        let model: Holdout? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingLayerId() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["layerId"] = nil
        
        let model: Holdout? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingVariations() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["variations"] = nil
        
        let model: Holdout? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingTrafficAllocation() {
        var data: [String: Any] = HoldoutTests.sampleData
        data["trafficAllocation"] = nil
        
        let model: Holdout? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
}

// MARK: - Encode

extension HoldoutTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = HoldoutTests.sampleData
        let modelGiven: Holdout = try! OTUtils.model(from: data)
        
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
}

// MARK: - audiences serialization

extension HoldoutTests {
    
    func testAudiencesSerialization() {
        let commonData: [String: Any] = ["id": "11111",
                                         "key": "background",
                                         "status": "Running",
                                         "layerId": "22222",
                                         "variations": [HoldoutTests.variationData],
                                         "trafficAllocation": [HoldoutTests.trafficAllocationData],
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
            var model: Holdout = try! OTUtils.model(from: data)
            model.serializeAudiences(with: audiencesMap)
            XCTAssertEqual(model.audiences, audiencesOutput[idx])
        }
    }
    
}

// MARK: - Test Utils

extension HoldoutTests {
    
    func testIsActivated() {
        let data: [String: Any] = HoldoutTests.sampleData
        var model: Holdout = try! OTUtils.model(from: data)
        
        XCTAssertTrue(model.isActivated)
        
        let allNotActiveStates: [Holdout.Status] = [.draft, .concluded, .archived]
        for status in allNotActiveStates {
            model.status = status
            XCTAssertFalse(model.isActivated)
        }
        
        model.status = .running
        XCTAssertTrue(model.isActivated)
    }
}

