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

class OptimizelyUserContextTests_ODP: XCTestCase {

    var optimizely: OptimizelyClient!
    var user: OptimizelyUserContext!
    let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
    var odpManager: MockOdpManager!

    let kUserId = "tester"
    let kUserKey = "custom_id"
    let kUserValue = "custom_id_value"
    let sdkKey = OTUtils.randomSdkKey
    
    override func setUp() {
        odpManager = MockOdpManager(sdkKey: sdkKey, enable: true, cacheSize: 10, cacheTimeoutInSecs: 10)

        optimizely = OptimizelyClient(sdkKey: sdkKey)
        optimizely.odpManager = odpManager

        user = optimizely.createUserContext(userId: kUserId)
    }
    
    // MARK: - isQualifiedFor

    func testIsQualifiedFor() {
        XCTAssertFalse(user.isQualifiedFor(segment: "a"))

        user.qualifiedSegments = ["a", "b"]
        XCTAssertTrue(user.isQualifiedFor(segment: "a"))
        XCTAssertFalse(user.isQualifiedFor(segment: "x"))
        
        user.qualifiedSegments = []
        XCTAssertFalse(user.isQualifiedFor(segment: "a"))
    }
        
    // MARK: - Success
    
    func testFetchQualifiedSegments_successDefaultUser() {
        try? optimizely.start(datafile: datafile)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            XCTAssertNil(error)
            XCTAssert(segments == ["segment-1"])
            XCTAssert(self.user.qualifiedSegments == segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    // MARK: - Failure
    
    func testFetchQualifiedSegments_sdkNotReady() {
        user.optimizely = nil
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            XCTAssertEqual(OptimizelyError.sdkNotReady.reason, error?.reason)
            XCTAssertNil(segments)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_fetchFailed() {
        let sem = DispatchSemaphore(value: 0)
        
        // ODP apiKey is not available
                
        user.fetchQualifiedSegments { segments, error in
            XCTAssertNotNil(error)
            XCTAssertNil(segments)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    // MARK: - SegmentsToCheck
    
    func testFetchQualifiedSegments_segmentsToCheck_validAfterStart() {
        try? optimizely.start(datafile: datafile)
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(odpManager.segmentsToCheck!))
    }
    
    func testFetchQualifiedSegments_segmentsNotUsed() {
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        try? optimizely.start(datafile: datafile)
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, [])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
        
    // MARK: - Customisze OdpManager
    
    func testCustomizeOdpManager()  {
        let sdkSettings = OptimizelySdkSettings(segmentsCacheSize: 12, segmentsCacheTimeoutInSecs: 345)
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                          settings: sdkSettings)

        XCTAssertEqual(12, optimizely.odpManager.segmentManager?.segmentsCache.size)
        XCTAssertEqual(345, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
    }

}

// MARK: - Optional parameters

extension OptimizelyUserContextTests_ODP {
    
    func testFetchQualifiedSegments_parameters() {
        try? optimizely.start(datafile: datafile)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(options: [.ignoreCache]) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, ["segment-1"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))

        XCTAssertEqual(kUserId, odpManager.userId, "userId should be used as a default")
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(odpManager.segmentsToCheck!), "segmentsToCheck should be all-in-project by default")
        XCTAssertEqual([.ignoreCache], odpManager.options)
    }
    
    func testFetchQualifiedSegments_configReady() {
        XCTAssertNil(odpManager.odpConfig.apiKey)
        XCTAssertNil(odpManager.odpConfig.apiHost)

        try? optimizely.start(datafile: "invalid")

        XCTAssertNil(odpManager.odpConfig.apiKey)
        XCTAssertNil(odpManager.odpConfig.apiHost)
        
        try! optimizely.start(datafile: datafile)

        XCTAssertEqual("W4WzcEs-ABgXorzY7h1LCQ", odpManager.odpConfig.apiKey)
        XCTAssertEqual("https://api.zaius.com", odpManager.odpConfig.apiHost)
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!   // no integration in this datafile
        try! optimizely.start(datafile: datafile)

        XCTAssertNil(odpManager.odpConfig.apiKey)
        XCTAssertNil(odpManager.odpConfig.apiHost)
    }
    
}

// MARK: - Tests with real ODP server

// tests below will be skipped in CI (travis/actions) since they use the live ODP server.
#if DEBUG

extension OptimizelyUserContextTests_ODP {
    // {"vuid": "00TEST00VUID00FULLSTACK", "fs_user_id": "tester-101"} bound in ODP server for testing
    var testOdpUserKey: String { return "fs_user_id" }
    var testOdpUserId: String { return "tester-101"}

    func testLiveOdpGraphQL() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
        let user = optimizely.createUserContext(userId: testOdpUserId)
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual([], segments, "none of the test segments in the live ODP server")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    func testLiveOdpGraphQL_noDatafile() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let user = optimizely.createUserContext(userId: testOdpUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            XCTAssertNil(error)
            XCTAssert(segments!.contains("has_email"), "segmentsToCheck are not passed to ODP, so fetching all segments.")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    func testLiveOdpGraphQL_defaultParameters_userNotRegistered() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
        let user = optimizely.createUserContext(userId: "not-registered-user")

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            if case .fetchSegmentsFailed("segments not in json") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }

}

#endif

// MARK: - MockOdpManager

class MockOdpManager: OdpManager {
    var userId: String?
    var segmentsToCheck: [String]!
    var options: [OptimizelySegmentOption]!
    
    var apiKey: String?
    var apiHost: String?
    
    override func fetchQualifiedSegments(userId: String,
                                         segmentsToCheck: [String],
                                         options: [OptimizelySegmentOption],
                                         completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        self.userId = userId
        self.segmentsToCheck = segmentsToCheck
        self.options = options
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            if self.odpConfig.apiKey == nil {
                completionHandler(nil, OptimizelyError.generic)
            } else {
                let sampleSegments = ["segment-1"]
                completionHandler(sampleSegments, nil)
            }
        }
    }
    
}

