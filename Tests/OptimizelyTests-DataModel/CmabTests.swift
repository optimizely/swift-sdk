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

class CmabTests: XCTestCase {
    static var sampleData: [String: Any] = ["trafficAllocation": 10000, "attributeIds": ["id_1", "id_2"]]
    
    func testDecodeSuccessValidJson() {
        let data = Self.sampleData
        let cmab: Cmab = try! OTUtils.model(from: data)
        XCTAssertEqual(cmab.attributeIds, ["id_1", "id_2"])
        XCTAssertEqual(cmab.trafficAllocation, 10000)   
    }
    
    func testDecodeSuccessEmptyIds() {
        var data = Self.sampleData
        data["attributeIds"] = []
        let cmab: Cmab = try! OTUtils.model(from: data)
        XCTAssertEqual(cmab.attributeIds, [])
        XCTAssertEqual(cmab.trafficAllocation, 10000)
    }
    
    func testDecodFailedWithoutTrafficAllocation() {
        let data = ["attributeIds": ["id_1", "id_2"]]
        let cmab: Cmab? = try? OTUtils.model(from: data)
        XCTAssertNil(cmab)
    }
    
    func testDecodFailedWithoutAttributeIds() {
        let data =  ["trafficAllocation": 10000]
        let cmab: Cmab? = try? OTUtils.model(from: data)
        XCTAssertNil(cmab)
    }
}
