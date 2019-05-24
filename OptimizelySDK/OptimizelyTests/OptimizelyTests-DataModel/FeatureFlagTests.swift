/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

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
        let model: FeatureFlag = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12345", "12346"])
        XCTAssert(model.rolloutId == "34567")
        XCTAssert(model.variables == [try! OTUtils.model(from: FeatureVariableTests.sampleData)])
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag = try! OTUtils.model(from: data)

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
        let model: FeatureFlag? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        let data: [String: Any] = ["id": "553339214",
                                   "experimentIds":[],
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingRolloutId() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "experimentIds":[],
                                   "variables":[]]
        let model: FeatureFlag? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperimentIds() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "rolloutId":"34567",
                                   "variables":[]]
        let model: FeatureFlag? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingVariables() {
        let data: [String: Any] = ["id": "553339214",
                                   "key": "house",
                                   "rolloutId":"34567",
                                   "experimentIds":[]]
        let model: FeatureFlag? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
}

// MARK: - Encode

extension FeatureFlagTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = FeatureFlagTests.sampleData
        let modelGiven: FeatureFlag = try! OTUtils.model(from: data)
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }

}
