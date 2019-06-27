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
        
        let model: Group = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "11111")
        XCTAssert(model.policy == .random)
        XCTAssert(model.trafficAllocation == [try! OTUtils.model(from: TrafficAllocationTests.sampleData)])
        XCTAssert(model.experiments == [try! OTUtils.model(from: ExperimentTests.sampleData)])
    }
    
    func testDecodeFailWithMissingId() {
        var data: [String: Any] = GroupTests.sampleData
        data["id"] = nil
        
        let model: Group? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperiments() {
        var data: [String: Any] = GroupTests.sampleData
        data["experiments"] = nil
        
        let model: Group? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
}

// MARK: - Encode

extension GroupTests {
    
    func testEncodeJSON() {
        let data: [String: Any] = GroupTests.sampleData
        let modelGiven: Group = try! OTUtils.model(from: data)
        
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
    
}
