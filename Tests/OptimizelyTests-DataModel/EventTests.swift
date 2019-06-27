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

class EventTests: XCTestCase {
    static var sampleData: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"]]
}

// MARK: - Decode

extension EventTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"]]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750", "13139830210"])
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750"]]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750"])
    }
    
    func testDecodeSuccessWithJSONValid3() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": []]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == [])
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data: [String: Any] = ["id": "553339214", "key": "house", "experimentIds": ["12105773750", "13139830210"], "extra": "123"]
        let model: Event = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
        XCTAssert(model.experimentIds == ["12105773750", "13139830210"])
    }
    
    func testDecodeFailWithMissingId() {
        let data: [String: Any] = ["key": "house", "experimentIds": ["12105773750", "13139830210"]]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        let data: [String: Any] = ["id": "553339214", "experimentIds": ["12105773750", "13139830210"]]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingExperimentIds() {
        let data: [String: Any] = ["id": "553339214", "key": "house"]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data: [String: Any] = [:]
        let model: Event? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
        
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let model = Event(id: "553339214",
                          key: "house",
                          experimentIds: ["12105773750", "13139830210"])
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(model))
    }
    
}
