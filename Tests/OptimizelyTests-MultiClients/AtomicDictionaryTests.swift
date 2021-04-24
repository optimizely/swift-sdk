//
// Copyright 2021, Optimizely, Inc. and contributors 
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

class AtomicDictionaryTests: XCTestCase {

    func testAtomicDictionary() {
        let a = AtomicDictionary<String, Int>()
        XCTAssert(a.count == 0)
        XCTAssert(a["k1"] == nil)
        
        a["k1"] = 100
        a["k2"] = 2
        a["k1"] = 1
        
        XCTAssert(a.count == 2)
        XCTAssert(a["k1"] == 1)
        XCTAssert(a["k2"] == 2)

        a["k1"] = nil

        XCTAssert(a.count == 1)
        XCTAssert(a["k1"] == nil)
        XCTAssert(a["k2"] == 2)
    }
    
}
