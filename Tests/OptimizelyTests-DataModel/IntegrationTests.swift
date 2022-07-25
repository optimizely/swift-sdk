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

class IntegrationTests: XCTestCase {
    static var sampleData: [String: Any] = ["key": "partner",
                                            "host": "https://google.com",
                                            "publicKey": "abc123"]
}

// MARK: - Decode

extension IntegrationTests {
    
    func testDecodeSuccessWithJSONValid() {
        let data: [String: Any] = ["key": "partner",
                                   "host": "https://google.com",
                                   "publicKey": "abc123"]
        let model: Integration = try! OTUtils.model(from: data)
        
        XCTAssert(model.key == "partner")
        XCTAssert(model.host == "https://google.com")
        XCTAssert(model.publicKey == "abc123")
    }
    
    func testDecodeSuccessWithJSONValid2() {
        let data: [String: Any] = ["key": "partner",
                                   "host": "https://google.com"]
        let model: Integration = try! OTUtils.model(from: data)
        
        XCTAssert(model.key == "partner")
        XCTAssert(model.host == "https://google.com")
        XCTAssertNil(model.publicKey)
    }
    
    func testDecodeSuccessWithJSONValid3() {
        let data: [String: Any] = ["key": "partner"]
        let model: Integration = try! OTUtils.model(from: data)
        
        XCTAssert(model.key == "partner")
        XCTAssertNil(model.host)
        XCTAssertNil(model.publicKey)
    }
    
    func testDecodeSuccessWithJSONValid4() {
        let data: [String: Any] = ["key": "partner", "any-int": 10, "any-bool": true, "any-string": "any-str"]
        let model: Integration = try! OTUtils.model(from: data)
        
        XCTAssert(model.key == "partner")
        XCTAssertNil(model.host)
        XCTAssertNil(model.publicKey)
    }

    func testDecodeFailWithMissingKey() {
        let data: [String: Any] = ["host": "https://google.com"]
        let model: Integration? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }

    func testDecodeFailWithJSONEmpty() {
        let data: [String: Any] = [:]
        let model: Integration? = try? OTUtils.model(from: data)
        XCTAssertNil(model)
    }
}

// MARK: - Encode

extension IntegrationTests {
    
    func testEncodeJSON() {
        let model = Integration(key: "key",
                                host: "host",
                                publicKey: "public-key")
        XCTAssert(OTUtils.isEqualWithEncodeThenDecode(model))
    }
    
}
