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

class AttributeTests: XCTestCase {
    static var sampleData = ["id": "553339214", "key": "house"]
}

// MARK: - Decode

extension AttributeTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data = ["id": "553339214", "key": "house"]
        let model: Attribute = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data = ["id": "553339214", "key": "house", "extra": "123"]
        let model: Attribute = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "house")
    }

    func testDecodeFailWithMissingKey() {
        let data = ["id": "553339214"]
        let model: Attribute? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingId() {
        let data = ["key": "house"]
        let model: Attribute? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data = [String: String]()
        let model: Attribute? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let modelGiven = Attribute(id: "553339214", key: "house")
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(modelGiven))
    }
}


