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

class VariableTests: XCTestCase {
    static var sampleData = ["id": "553339214", "value": "100"]
}

// MARK: - Decode

extension VariableTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data = ["id": "553339214", "value": "100"]
        let model: Variable = try! OTUtils.model(from: data)
        
        XCTAssert(model.id == "553339214")
        XCTAssert(model.value == "100")
    }
    
    func testDecodeSuccessWithExtraFields() {
        let data = ["id": "553339214", "value": "100", "extra": "123"]
        let model: Variable = try! OTUtils.model(from: data)

        XCTAssert(model.id == "553339214")
        XCTAssert(model.value == "100")
    }
    
    func testDecodeFailWithMissingKey() {
        let data = ["id": "553339214"]
        let model: Variable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithMissingId() {
        let data = ["value": "100"]
        let model: Variable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
    
    func testDecodeFailWithJSONEmpty() {
        let data = [String: String]()
        let model: Variable? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
}
    
    // MARK: - Encode

extension VariableTests {
    
    func testEncodeJSON() {
        let model = Variable(id: "553339214", value: "100")
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(model))
    }
    
}
