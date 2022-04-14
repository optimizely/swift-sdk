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

class AudienceTests: XCTestCase {
    let modelType = Audience.self

    static var sampleData: [String: Any] = ["id": "553339214",
                                            "name": "america",
                                            "conditions": ConditionHolderTests.sampleData]
    static let legacyConditionString = OTUtils.jsonStringFromNative(ConditionHolderTests.sampleData)
    static var legacySampleData: [String: Any] = ["id": "553339214",
                                                  "name": "america",
                                                  "conditions": legacyConditionString]
}

// MARK: - Decode (Legacy Audiences)

extension AudienceTests {

    func testDecodeSuccessWithLegacyAudience() {
        // legacy audience uses stringified conditions
        // - "[\"or\",{\"value\":30,\"type\":\"custom_attribute\",\"match\":\"exact\",\"name\":\"geo\"}]"
        // Audience will decode it to recover to typedAudience formats
        
        
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": AudienceTests.legacyConditionString]
        let model: Audience = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditionHolder == (try! OTUtils.model(from: ConditionHolderTests.sampleData)))
        XCTAssert(model.conditions == AudienceTests.legacyConditionString)
    }
    
}

// MARK: - Decode (Typed Audience)

extension AudienceTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": ConditionHolderTests.sampleData]
        let model: Audience = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditionHolder == (try! OTUtils.model(from: ConditionHolderTests.sampleData)))
    
        if let modelConditions = try? JSONDecoder().decode(ConditionHolder.self,
                                                           from: model.conditions.data(using: .utf8)!),
            let expectedConditions = try? JSONDecoder().decode(ConditionHolder.self,
                                                               from: AudienceTests.legacyConditionString.data(using: .utf8)!) {
            XCTAssertEqual(modelConditions, expectedConditions)
        } else {
            XCTFail()
        }
    }
    
    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["name": "america",
                                   "conditions": ConditionHolderTests.sampleData]
        let model: Audience? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingName() {
        let data: [String: Any] = ["id": "553339214",
                                   "conditions": ConditionHolderTests.sampleData]
        let model: Audience? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingConditions() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america"]
        let model: Audience? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    // not-array at top level of conditions (UserAttribute)
    
    func testDecodeSuccessWithNonArrayConditions() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": UserAttributeTests.sampleData]
        let model: Audience = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditionHolder == (try! OTUtils.model(from: UserAttributeTests.sampleData)))
    }
    
}

// MARK: - Encode

extension AudienceTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": ConditionHolderTests.sampleData]
        let modelGiven: Audience = try! OTUtils.model(from: data)

        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }

}

// MARK: - Others

extension AudienceTests {
    
    func testGetSegments() {
        let seg1 = ["name": "odp.audiences", "type": "third_party_dimension", "match": "qualified", "value": "seg1"]
        let seg2 = ["name": "odp.audiences", "type": "third_party_dimension", "match": "qualified", "value": "seg2"]
        let seg3 = ["name": "odp.audiences", "type": "third_party_dimension", "match": "qualified", "value": "seg3"]
        let other = ["name": "other", "type": "custom_attribute", "match": "eq", "value": "a"]
        
        var audience = makeAudience([seg1])
        XCTAssertEqual(["seg1"], Set(audience.getSegments()))

        audience = makeAudience(["or", seg1])
        XCTAssertEqual(["seg1"], Set(audience.getSegments()))

        audience = makeAudience(["and", ["or", seg1]])
        XCTAssertEqual(["seg1"], Set(audience.getSegments()))
        
        audience = makeAudience(["and", ["or", seg1], ["or", seg2], ["and", other]])
        XCTAssertEqual(["seg1", "seg2"], Set(audience.getSegments()))
        
        audience = makeAudience(["and", ["or", seg1, other, seg2]])
        XCTAssertEqual(["seg1", "seg2"], Set(audience.getSegments()))
        
        audience = makeAudience(["and", ["or", seg1, other, seg2], ["and", seg1, seg2, seg3]])
        XCTAssertEqual(3, audience.getSegments().count)
        XCTAssertEqual(["seg1", "seg2", "seg3"], Set(audience.getSegments()))
    }
    
    func makeAudience(_ conditions: [Any]) -> Audience {
        let data: [String: Any] = ["id": "12345", "name": "group-a", "conditions": conditions]
        return try! OTUtils.model(from: data)
    }
    
}
