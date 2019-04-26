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

class FeatureVariableTests: XCTestCase {
    static var sampleData = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100"]

    // MARK: - Decode

    func testDecodeSuccessWithJSONValid() {
        let data = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100"]
        let model: FeatureVariable = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "price")
        XCTAssert(model.type == "integer")
        XCTAssert(model.defaultValue == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data = ["id": "553339214", "key": "price", "type": "integer", "defaultValue": "100", "extra": "123"]
        let model: FeatureVariable = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.key == "price")
        XCTAssert(model.type == "integer")
        XCTAssert(model.defaultValue == "100")
    }
    
    func testDecodeFailWithMissingId() {
        let data = ["key": "price", "type": "integer", "defaultValue": "100"]
        let model: FeatureVariable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingKey() {
        let data = ["id": "553339214", "type": "integer", "defaultValue": "100"]
        let model: FeatureVariable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithMissingType() {
        let data = ["id": "553339214", "key": "price", "defaultValue": "100"]
        let model: FeatureVariable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    // TODO: [Jae] validate this test
//    func testDecodeFailWithMissingDefaultValue() {
//        let data = ["id": "553339214", "key": "price", "type": "integer"]
//        let model: FeatureVariable? = try? OTUtils.model(from: data)
//        XCTAssertNotNil(model)
//    }
    
    func testDecodeFailWithJSONEmpty() {
        let data = [String: String]()
        let model: FeatureVariable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    // MARK: - Encode
    
    func testEncodeJSON() {
        let model = FeatureVariable(id: "553339214", key: "price", type: "integer", defaultValue: "100")
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(model))
   }
}
