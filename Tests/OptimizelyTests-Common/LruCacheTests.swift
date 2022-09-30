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

class LruCacheTests: XCTestCase {
    
    func testMinConfig() {
        var cache = LruCache<String, Any>(size: 1000, timeoutInSecs: 2000)
        XCTAssertEqual(1000, cache.maxSize)
        XCTAssertEqual(2000, cache.timeoutInSecs)

        cache = LruCache<String, Any>(size: 0, timeoutInSecs: 0)
        XCTAssertEqual(0, cache.maxSize)
        XCTAssertEqual(0, cache.timeoutInSecs)
    }
    
    func testSaveAndLookup() {
        let maxSize = 2
        let cache = LruCache<Int, Int>(size: maxSize, timeoutInSecs: 1000)
        
        XCTAssertNil(cache.peek(key: 1))
        cache.save(key: 1, value: 100)              // [1]
        cache.save(key: 2, value: 200)              // [1, 2]
        cache.save(key: 3, value: 300)              // [2, 3]
        XCTAssertNil(cache.peek(key: 1))
        XCTAssertEqual(200, cache.peek(key: 2))
        XCTAssertEqual(300, cache.peek(key: 3))
        
        cache.save(key: 2, value: 201)              // [3, 2]
        cache.save(key: 1, value: 101)              // [2, 1]
        XCTAssertEqual(101, cache.peek(key: 1))
        XCTAssertEqual(201, cache.peek(key: 2))
        XCTAssertNil(cache.peek(key: 3))
                    
        XCTAssertNil(cache.lookup(key: 3))          // [2, 1]
        XCTAssertEqual(201, cache.lookup(key: 2))   // [1, 2]
        cache.save(key: 3, value: 302)              // [2, 3]
        XCTAssertNil(cache.peek(key: 1))
        XCTAssertEqual(201, cache.peek(key: 2))
        XCTAssertEqual(302, cache.peek(key: 3))

        XCTAssertEqual(302, cache.lookup(key: 3))   // [2, 3]
        cache.save(key: 1, value: 103)              // [3, 1]
        XCTAssertEqual(103, cache.peek(key: 1))
        XCTAssertNil(cache.peek(key: 2))
        XCTAssertEqual(302, cache.peek(key: 3))
        
        var node: LruCache.CacheElement? = cache.head
        var count = 0
        while node != nil {
            count += 1
            node = node?.next
        }
        XCTAssertEqual(maxSize, count - 2)   // subtract 2 (head, tail)
        XCTAssertEqual(cache.map.count, cache.maxSize)
    }
    
    func testReset() {
        let maxSize = 2
        let cache = LruCache<Int, Int>(size: maxSize, timeoutInSecs: 1000)
        
        cache.save(key: 1, value: 100)              // [1]
        cache.save(key: 2, value: 200)              // [1, 2]
        sleep(1)
        
        XCTAssertEqual(cache.map.count, 2)
        
        // cache reset
        
        cache.reset()
        sleep(1)
        
        XCTAssertEqual(cache.map.count, 0)
        
        // validate cache fully functional after reset
        
        cache.save(key: 3, value: 300)              // [3]
        cache.save(key: 2, value: 400)              // [3, 2]

        XCTAssertNil(cache.peek(key: 1))
        XCTAssertEqual(400, cache.peek(key: 2))
        XCTAssertEqual(300, cache.peek(key: 3))
        
        cache.save(key: 3, value: 600)              // [2, 3]
        cache.save(key: 1, value: 500)              // [3, 1]
        XCTAssertNil(cache.peek(key: 2))
        XCTAssertEqual(600, cache.peek(key: 3))
        XCTAssertEqual(500, cache.peek(key: 1))
        
        _ = cache.lookup(key: 3)                    // [1, 3]
        cache.save(key: 2, value: 700)              // [3, 2]
        XCTAssertNil(cache.peek(key: 1))
        XCTAssertEqual(600, cache.peek(key: 3))
        XCTAssertEqual(700, cache.peek(key: 2))
    }

    func testSize_zero() {
        let cache = LruCache<Int, Int>(size: 0, timeoutInSecs: 1000)
        
        XCTAssertNil(cache.lookup(key: 1))
        cache.save(key: 1, value: 100)              // [1]
        XCTAssertNil(cache.lookup(key: 1))
        cache.reset()
        XCTAssertNil(cache.lookup(key: 1))
    }
    
    func testThreadSafe() {
        let numThreads = 100
        let numIterationPerThread = 1000
        
        let cache = LruCache<Int, Int>(size: 3, timeoutInSecs: 1)
        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 10) { idx in
            for i in 0..<numIterationPerThread {
                let v = i * 10
                cache.save(key: i, value: v)
                XCTAssertEqual(cache.lookup(key: i), v)
            }
        }
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

}

// tests below will be skipped in CI (travis/actions) since they can be flaky (depend on timing).
#if DEBUG

extension LruCacheTests {

    func testTimeout() {
        let maxTimeout = 1
        let cache = LruCache<Int, Int>(size: 1000, timeoutInSecs: maxTimeout)
        
        cache.save(key: 1, value: 100)              // [1]
        cache.save(key: 2, value: 200)              // [1, 2]
        cache.save(key: 3, value: 300)              // [1, 2, 3]
        sleep(2)  // wait to expire
        cache.save(key: 4, value: 400)              // [1, 2, 3]
        cache.save(key: 1, value: 101)              // [1]
                
        XCTAssertEqual(101, cache.lookup(key: 1))
        XCTAssertNil(cache.lookup(key: 2))
        XCTAssertNil(cache.lookup(key: 3))
        XCTAssertEqual(400, cache.lookup(key: 4))
    }
    
    func testTimeout_zero() {
        let maxTimeout = 0
        let cache = LruCache<Int, Int>(size: 1000, timeoutInSecs: maxTimeout)
        
        cache.save(key: 1, value: 100)              // [1]
        cache.save(key: 2, value: 200)              // [1, 2]
        sleep(2)  // wait to expire
                
        XCTAssertEqual(100, cache.lookup(key: 1), "should not expire when timeout is 0")
        XCTAssertEqual(200, cache.lookup(key: 2))
    }

}

#endif
