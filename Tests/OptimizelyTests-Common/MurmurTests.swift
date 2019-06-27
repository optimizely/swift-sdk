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

class MurmurTests: XCTestCase {
    
    private let utf8Charset = CharacterSet.alphanumerics

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func doString32(s: String) {
        doString32(s: s, pre: 0, post: 0)
    }
    
    private func doString32(s: String, pre: Int, post: Int) {
        let utf8 = s.utf8.map({$0})
        let hash1 = MurmurHash3.hash32Bytes(key: utf8, maxBytes: s.count - pre - post, seed: 123456789)
        var hash2 = MurmurHash3.hash32(key: s, seed: 123456789)
        var hash3 = MurmurHash3.hash32CChar(key: s.cString(using: .utf8)!, maxBytes: s.count - pre - post, seed: 123456789)
        if (hash1 != hash2) {
        // second time for debugging...
            hash2 = MurmurHash3.hash32(key: s, seed: 123456789)
        }
        if (hash2 != hash3) {
            hash3 = MurmurHash3.hash32CChar(key: s.cString(using: .utf8)!, maxBytes: s.count - pre - post, seed: 123456789)
        }
        XCTAssertEqual(hash1, hash2)
        XCTAssertEqual(hash2, hash3)
    }

    private func doString128(s: String) {
        doString128(s: s, pre: 0, post: 0)
    }
    
    private func doString128(s: String, pre: Int, post: Int) {
        let utf8 = s.utf8.map({$0})
        let hash1 = MurmurHash3.hash128Bytes(key: utf8, maxBytes: s.count - pre - post, seed: 123456789)
        var hash2 = MurmurHash3.hash128(key: s, seed: 123456789)
        var hash3 = MurmurHash3.hash128CChar(key: s.cString(using: .utf8)!, maxBytes: s.count - pre - post, seed: 123456789)
        if (hash1 != hash2) {
            // second time for debugging...
            hash2 = MurmurHash3.hash128(key: s, seed: 123456789)
        }
        if (hash2 != hash3) {
            hash3 = MurmurHash3.hash128CChar(key: s.cString(using: .utf8)!, maxBytes: s.count - pre - post, seed: 123456789)
        }
        XCTAssertEqual(hash1.h1, hash2.h1)
        XCTAssertEqual(hash1.h2, hash2.h2)
        XCTAssertEqual(hash2.h1, hash3.h1)
        XCTAssertEqual(hash2.h2, hash3.h2)
    }

    func testMurmur32() {
        doString32(s: "hello!")
        doString32(s: "ABCD")
        doString32(s: "0123")
        doString32(s: "2345")
        doString32(s: "23451234")
        
    }

    func testMurmur128() {
        doString128(s: "hello!")
        doString128(s: "ABCD")
        doString128(s: "0123")
        doString128(s: "2345")
        doString128(s: "23451234")
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
