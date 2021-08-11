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
        
        // validate copying not holding reference
        
        let b = AtomicDictionary<String, Int>()
        b["k1"] = 1
        b["k2"] = 2

        let c = AtomicDictionary<String, Int>()
        c.property = b.property
        XCTAssert(c.count == 2)
        XCTAssert(c["k1"] == 1)
        XCTAssert(c["k2"] == 2)
        b["k1"] = 100
        b["k2"] = 200
        XCTAssert(c["k1"] == 1)
        XCTAssert(c["k2"] == 2)
    }
    
    func testConcurrentReadWrite() {
        let a = AtomicDictionary<Int, Int>()

        let numConcurrency = 10
        let numIterations = 1000
        let result = OTUtils.runConcurrent(count: numConcurrency) { idx in
            for i in 0..<numIterations {
                a[i] = i + 1234
            }

            for i in 0..<numIterations {
                XCTAssertEqual(a[i], i + 1234)
            }
            
            XCTAssertEqual(a.count, numIterations)
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
        XCTAssertEqual(a.count, numIterations)
    }
    
    func testConcurrentCopy() {
        let num = 10
        let a = AtomicDictionary<Int, Int>()
        (0..<num).forEach{ a[$0] = $0 + 1234 }
        
        let b = AtomicDictionary<Int, Int>()

        let result = OTUtils.runConcurrent(count: 100) { idx in
            for _ in 0..<100 {
                b.property = a.property
                XCTAssert(b.count == num)
            }
            
            XCTAssert(b.property == a.property)
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

}
