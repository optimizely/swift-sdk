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
}

// MARK: - Decode (Legacy Audiences)

extension AudienceTests {

    func testDecodeSuccessWithLegacyAudience() {
        // legacy audience uses stringified conditions
        // - "[\"or\",{\"value\":30,\"type\":\"custom_attribute\",\"match\":\"exact\",\"name\":\"geo\"}]"
        // Audience will decode it to recover to typedAudience formats
        
        let legacyConditionString = OTUtils.jsonStringFromNative(ConditionHolderTests.sampleData)
        
        let data: [String: Any] = ["id": "553339214",
                                   "name": "america",
                                   "conditions": legacyConditionString]
        let model: Audience = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.name == "america")
        XCTAssert(model.conditions == (try! OTUtils.model(from: ConditionHolderTests.sampleData)))
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
        XCTAssert(model.conditions == (try! OTUtils.model(from: UserAttributeTests.sampleData)))
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
