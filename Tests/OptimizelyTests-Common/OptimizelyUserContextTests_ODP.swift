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
        odpManager = MockOdpManager(sdkKey: sdkKey, disable: false, cacheSize: 10, cacheTimeoutInSecs: 10)

        optimizely = OptimizelyClient(sdkKey: sdkKey)
        optimizely.odpManager = odpManager
    }
    
    // MARK: - identify
    
    func testIdentifyCalledAutomatically() {
        user = optimizely.createUserContext(userId: kUserId)
        sleep(1)
        XCTAssert(odpManager.identifyCalled, "identifyUser is implicitly called on UserContext init")
        XCTAssertEqual(kUserId, odpManager.userId)
    }
    
    func testIdentifyNotCalledForLegacyAPIs() {
        try? optimizely.start(datafile: datafile)
        _ = try? optimizely.activate(experimentKey: "experiment-segment", userId: kUserId)
        _ = try? optimizely.getVariation(experimentKey: "experiment-segment", userId: kUserId)
        _ = try? optimizely.getAllFeatureVariables(featureKey: "flag-segment", userId: kUserId)
        _ = optimizely.isFeatureEnabled(featureKey: "flag-segment", userId: kUserId)
        try? optimizely.track(eventKey: "event1", userId: kUserId)
        
        sleep(1)
        XCTAssertFalse(odpManager.identifyCalled, "identifyUser is implicitly called on UserContext init")
    }
    
    // MARK: - isQualifiedFor

    func testIsQualifiedFor() {
        user = optimizely.createUserContext(userId: kUserId)

        XCTAssertFalse(user.isQualifiedFor(segment: "a"))

        user.qualifiedSegments = ["a", "b"]
        XCTAssert(user.isQualifiedFor(segment: "a"))
        XCTAssertFalse(user.isQualifiedFor(segment: "x"))
        
        user.qualifiedSegments = []
        XCTAssertFalse(user.isQualifiedFor(segment: "a"))
    }
    
}

// MARK: - fetchQualifiedSegments (non-blocking)

extension OptimizelyUserContextTests_ODP {
        
    // MARK: - Success
    
    func testFetchQualifiedSegments_successDefaultUser() {
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.user.qualifiedSegments, ["odp-segment-1"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    // MARK: - Failure
    
    func testFetchQualifiedSegments_sdkNotReady() {
        user = optimizely.createUserContext(userId: kUserId)
        user.optimizely = nil
        user.qualifiedSegments = ["dummy"]
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { error in
            XCTAssertEqual(OptimizelyError.sdkNotReady.reason, error?.reason)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_fetchFailed() {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = ["dummy"]

        // ODP apiKey is not available
                
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { error in
            XCTAssertNotNil(error)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    // MARK: - SegmentsToCheck
    
    func testFetchQualifiedSegments_segmentsToCheck_validAfterStart() {
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(odpManager.odpConfig.segmentsToCheck))
    }
    
    func testFetchQualifiedSegments_segmentsNotUsed() {
        let datafile = OTUtils.loadJSONDatafile("odp_integrated_no_segments")!
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { error in
            XCTAssertNil(error)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
        
}

// MARK: - fetchQualifiedSegments (blocking)

extension OptimizelyUserContextTests_ODP {
        
    // MARK: - Success
    
    func testFetchQualifiedSegments_blocking_successDefaultUser() {
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)

        do {
            try user.fetchQualifiedSegments()
            XCTAssertEqual(user.qualifiedSegments, ["odp-segment-1"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    // MARK: - Failure
    
    func testFetchQualifiedSegments_blocking_sdkNotReady() {
        user = optimizely.createUserContext(userId: kUserId)
        user.optimizely = nil
        user.qualifiedSegments = ["dummy"]
        
        do {
            try user.fetchQualifiedSegments()
            XCTFail("expected to fail")
        } catch OptimizelyError.sdkNotReady {
            XCTAssertNil(user.qualifiedSegments)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testFetchQualifiedSegments_blocking_fetchFailed() {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = ["dummy"]

        // ODP apiKey is not available
          
        do {
            try user.fetchQualifiedSegments()
            XCTFail("expected to fail")
        } catch OptimizelyError.fetchSegmentsFailed {
            XCTAssertNil(self.user.qualifiedSegments)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
            
}

// MARK: - Optional parameters

extension OptimizelyUserContextTests_ODP {
    
    func testFetchQualifiedSegments_parameters() {
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(options: [.ignoreCache]) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.user.qualifiedSegments, ["odp-segment-1"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))

        XCTAssertEqual(kUserId, odpManager.userId, "userId should be used as a default")
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(odpManager.odpConfig.segmentsToCheck), "segmentsToCheck should be all-in-project by default")
        XCTAssertEqual([.ignoreCache], odpManager.options)
    }
    
    func testFetchQualifiedSegments_configReady() {
        XCTAssertNil(odpManager.odpConfig.apiKey)
        XCTAssertNil(odpManager.odpConfig.apiHost)

        try? optimizely.start(datafile: "invalid")
        user = optimizely.createUserContext(userId: kUserId)

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

// MARK: - Tests with live ODP server

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
        user.fetchQualifiedSegments { error in
            XCTAssertNil(error)
            XCTAssertEqual([], user.qualifiedSegments, "none of the test segments in the live ODP server")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    /*
     this test is not good since createUserContext with not-registered-user will auto register the user.
     the same live odp test with not-registered-user will be done in OdpSegmentApiManagerTests, so skipped here.
     
    func testLiveOdpGraphQL_defaultParameters_userNotRegistered() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
        let user = optimizely.createUserContext(userId: "not-registered-user")

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments { segments, error in
            if case .invalidSegmentIdentifier = error {
                XCTAssert(true)
            
            // [TODO] ODP server will fix to add this "InvalidSegmentIdentifier" later.
            //        Until then, use the old error format ("DataFetchingException").
                
            } else if case .fetchSegmentsFailed("DataFetchingException") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
     */
}

#endif

// MARK: - MockOdpManager

class MockOdpManager: OdpManager {
    var userId: String?
    var options: [OptimizelySegmentOption]!
    var identifyCalled = false
    
    init(sdkKey: String, disable: Bool, cacheSize: Int, cacheTimeoutInSecs: Int) {
        super.init(sdkKey: sdkKey, disable: disable, cacheSize: cacheSize, cacheTimeoutInSecs: cacheTimeoutInSecs)
        self.segmentManager?.apiMgr = MockOdpSegmentApiManager()
    }
    
    override func fetchQualifiedSegments(userId: String,
                                         options: [OptimizelySegmentOption],
                                         completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        self.userId = userId
        self.options = options
        super.fetchQualifiedSegments(userId: userId, options: options, completionHandler: completionHandler)
    }
        
    override func identifyUser(userId: String) {
        self.userId = userId
        self.identifyCalled = true
    }
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
        
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            let qualified = segmentsToCheck.isEmpty ? [] : [segmentsToCheck.sorted{ $0 < $1 }.first!]
            completionHandler(qualified, nil)
        }
    }
}
