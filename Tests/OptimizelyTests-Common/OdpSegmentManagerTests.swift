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

class OdpSegmentManagerTests: XCTestCase {
    var manager: OdpSegmentManager!
    var odpConfig: OdpConfig!
    var apiManager = MockOdpSegmentApiManager()
    
    var options = [OptimizelySegmentOption]()
    
    var userKey = "vuid"
    var userValue = "test-user"
    
    override func setUp() {
        odpConfig = OdpConfig()
        
        manager = OdpSegmentManager(cacheSize: 10,
                                    cacheTimeoutInSecs: 10,
                                    odpConfig: odpConfig,
                                    apiManager: apiManager)
    }
    
    func testFetchSegmentsSuccess_cacheMiss() {
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: ["new-customer"])

        setCache(userKey, "123", ["a"])

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userKey: userKey,
                                       userValue: userValue,
                                       options: options) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(["new-customer"], segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
        
        XCTAssertEqual("valid", apiManager.receivedApiKey)
        XCTAssertEqual("host", apiManager.receivedApiHost)
    }
    
    func testFetchSegmentsSuccess_cacheHit() {
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: ["new-customer"])

        setCache(userKey, userValue, ["a"])

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userKey: userKey,
                                       userValue: userValue,
                                       options: options) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(["a"], segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchSegmentsError() {
        _ = odpConfig.update(apiKey: "invalid-key", apiHost: "host", segmentsToCheck: ["new-customer"])

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userKey: userKey,
                                       userValue: userValue,
                                       options: []) { segments, error in
            XCTAssertNotNil(error)
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    // MARK: - OptimizelySegmentOption
    
    func testOptions_ignoreCache() {
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: ["new-customer"])

        setCache(userKey, userValue, ["a"])
        options = [.ignoreCache]

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userKey: userKey,
                                       userValue: userValue,
                                       options: options) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(["new-customer"], segments, "cache lookup should be skipped")
            XCTAssertEqual(1, self.cacheCount, "cache save should be skipped as well")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testOptions_resetCache() {
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: ["new-customer"])

        setCache(userKey, userValue, ["a"])
        setCache(userKey, "123", ["a"])
        setCache(userKey, "456", ["a"])
        options = [.resetCache]

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userKey: userKey,
                                       userValue: userValue,
                                       options: options) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(["new-customer"], segments, "cache lookup should be skipped")
            XCTAssertEqual(segments, self.peekCache(self.userKey, self.userValue))
            XCTAssertEqual(1, self.cacheCount, "cache should be reset and then add a new one")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testMakeCacheKey() {
        XCTAssertEqual("vuid-$-test-user", manager.makeCacheKey(userKey, userValue))
    }

    // MARK: - Utils
    
    func setCache(_ userKey: String, _ userValue: String, _ value: [String]) {
        let cacheKey = manager.makeCacheKey(userKey, userValue)
        manager.segmentsCache.save(key: cacheKey, value: value)
    }
    
    func peekCache(_ userKey: String, _ userValue: String) -> [String]? {
        let cacheKey = manager.makeCacheKey(userKey, userValue)
        return manager.segmentsCache.peek(key: cacheKey)
    }
    
    var cacheCount: Int {
        return manager.segmentsCache.map.count
    }

    // MARK: - MockOdpSegmentApiManager

    class MockOdpSegmentApiManager: OdpSegmentApiManager {
        var receivedApiKey: String!
        var receivedApiHost: String!

        override func fetchSegments(apiKey: String,
                                    apiHost: String,
                                    userKey: String,
                                    userValue: String,
                                    segmentsToCheck: [String],
                                    completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
            receivedApiKey = apiKey
            receivedApiHost = apiHost
            
            DispatchQueue.global().async {
                if apiKey == "invalid-key" {
                    completionHandler(nil, OptimizelyError.fetchSegmentsFailed("403"))
                } else {
                    completionHandler(segmentsToCheck, nil)
                }
            }
        }
    }
    
}
