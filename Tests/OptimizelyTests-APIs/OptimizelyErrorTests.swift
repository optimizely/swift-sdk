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

class OptimizelyErrorTests: XCTestCase {

    func testReason() {
        let error = OptimizelyError.sdkNotReady
        XCTAssert(error.reason.contains("Optimizely SDK not configured properly yet"))
    }
    
    func testErrorDescription() {
        let error = OptimizelyError.sdkNotReady
        XCTAssert(error.reason == error.errorDescription)
    }
    
    func testDescription() {
        let error = OptimizelyError.sdkNotReady
        XCTAssert(error.description.contains("[Optimizely][Error]"))
        XCTAssert(error.description.contains(error.reason))
    }
    
    func testLocalizedDescription() {
        let error = OptimizelyError.sdkNotReady
        XCTAssert(error.description == error.localizedDescription)
    }
}
