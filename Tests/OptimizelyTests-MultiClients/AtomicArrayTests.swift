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

class AtomicArrayTests: XCTestCase {

    func testAtomicArray() {
        let a = AtomicArray<Int>([0, 1, 2, 3, 4])
        XCTAssert(a.count == 5)
        XCTAssert(a[0] == 0)
        XCTAssert(a[4] == 4)
        a[0] = 100
        a[4] = 400
        XCTAssert(a[0] == 100)
        XCTAssert(a[4] == 400)
        
        let b = AtomicArray<Int>([0, 1, 2, 3, 4])
        b.append(5)
        XCTAssert(b.count == 6)
        XCTAssert(b[0] == 0)
        XCTAssert(b[4] == 4)
        XCTAssert(b[5] == 5)
        
        b.append(contentsOf: [10, 20, 30])
        XCTAssert(b.count == 9)
        XCTAssert(b[0] == 0)
        XCTAssert(b[4] == 4)
        XCTAssert(b[5] == 5)
        XCTAssert(b[6] == 10)
        XCTAssert(b[7] == 20)
        XCTAssert(b[8] == 30)
    }
    
}
