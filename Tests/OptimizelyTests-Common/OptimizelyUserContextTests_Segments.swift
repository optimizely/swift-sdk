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

class OptimizelyUserContextTests_Segments: XCTestCase {

    var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
    var segmentHandler = MockAudienceSegmentsHandler(cacheSize: 100, cacheTimeoutInSecs: 100)
    var user: OptimizelyUserContext!
    let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!

    let kUserId = "tester"
    let kApiKey = "any-key"
    let kApiHost = "any-host"
    let kUserKey = "custom_id"
    let kUserValue = "custom_id_value"

    override func setUp() {
        optimizely.audienceSegmentsHandler = segmentHandler
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
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey, apiHost: kApiHost) { segments, error in
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
        user.fetchQualifiedSegments(apiKey: kApiKey, apiHost: kApiHost) { segments, error in
            XCTAssertEqual(OptimizelyError.sdkNotReady.reason, error?.reason)
            XCTAssertNil(segments)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_fetchFailed() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: "invalid-key", apiHost: kApiHost) { segments, error in
            XCTAssertNotNil(error)
            XCTAssertNil(segments)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    // MARK: - SegmentsToCheck
    
    func testFetchQualifiedSegments_segmentsToCheck_emptyBeforeStart() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey, apiHost: kApiHost) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertNil(segmentHandler.segmentsToCheck)
    }
    
    func testFetchQualifiedSegments_segmentsToCheck_validAfterStart() {
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        try? optimizely.start(datafile: datafile)
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey, apiHost: kApiHost) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(segmentHandler.segmentsToCheck!))
    }
    
    func testFetchQualifiedSegments_segmentsToCheck_segmentsNotUsed() {
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        try? optimizely.start(datafile: datafile)
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey, apiHost: kApiHost) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertNil(segmentHandler.segmentsToCheck, "empty segmentsToCheck case should be filtered out before calling segmentHandler")
        XCTAssertEqual([], user.qualifiedSegments)
    }
        
    // MARK: - Customisze AudienceSegmentHandler
    
    func testCustomizeAudienceSegmentsHandler()  {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                          periodicDownloadInterval: 60,
                                          segmentsCacheSize: 12,
                                          segmentsCacheTimeout: 123)

        XCTAssertEqual(12, optimizely.audienceSegmentsHandler.segmentsCache.size)
        XCTAssertEqual(123, optimizely.audienceSegmentsHandler.segmentsCache.timeoutInSecs)
    }

}

// MARK: - Optional parameters

extension OptimizelyUserContextTests_Segments {
    
    func testFetchQualifiedSegments_parameters() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey,
                                    apiHost: kApiHost,
                                    userKey: kUserKey,
                                    userValue: kUserValue,
                                    options: [.ignoreCache]) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))

        XCTAssertEqual(kApiKey, segmentHandler.apiKey)
        XCTAssertEqual(kApiHost, segmentHandler.apiHost)
        XCTAssertEqual(kUserKey, segmentHandler.userKey)
        XCTAssertEqual(kUserValue, segmentHandler.userValue)
        XCTAssertNil(segmentHandler.segmentsToCheck)
        XCTAssertEqual([.ignoreCache], segmentHandler.options)
    }
    
    func testFetchQualifiedSegments_defaults_configReady() {
        try! optimizely.start(datafile: datafile)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments() { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, ["segment-1"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertEqual("W4WzcEs-ABgXorzY7h1LCQ", optimizely.config?.publicKeyForODP, "apiKey from datafile should be used as a default")
        XCTAssertEqual("https://api.zaius.com", optimizely.config?.hostForODP, "apiHost from datafile should be used as a default")
        XCTAssertEqual("$opt_user_id", segmentHandler.userKey, "the reserved user-key should be used as a default")
        XCTAssertEqual(kUserId, segmentHandler.userValue, "userId should be used as a default")
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(segmentHandler.segmentsToCheck!), "segmentsToCheck should be all-in-project by default")
        XCTAssertEqual([], segmentHandler.options)
    }

    func testFetchQualifiedSegments_missingApiKey_configNotReady() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments() { segments, error in
            if let error = error, case OptimizelyError.fetchSegmentsFailed(let hint) = error {
                XCTAssertEqual("apiKey not defined", hint)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }

    func testFetchQualifiedSegments_missingApiHost_configNotReady() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey) { segments, error in
            if let error = error, case OptimizelyError.fetchSegmentsFailed(let hint) = error {
                XCTAssertEqual("apiHost not defined", hint)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_defaults_configReady_missingIntegration() {
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!   // no integration in this datafile
        try! optimizely.start(datafile: datafile)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments() { segments, error in
            if let error = error, case OptimizelyError.fetchSegmentsFailed(let hint) = error {
                XCTAssertEqual("apiKey not defined", hint)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }

}

// MARK: - MockAudienceSegmentsHandler

class MockAudienceSegmentsHandler: AudienceSegmentsHandler {
    var apiKey: String?
    var apiHost: String?
    var userKey: String?
    var userValue: String?
    var segmentsToCheck: [String]?
    var options: [OptimizelySegmentOption]?
        
    override func fetchQualifiedSegments(apiKey: String,
                                         apiHost: String,
                                         userKey: String,
                                         userValue: String,
                                         segmentsToCheck: [String]?,
                                         options: [OptimizelySegmentOption],
                                         completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        
        self.apiKey = apiKey
        self.apiHost = apiHost
        self.userKey = userKey
        self.userValue = userValue
        self.segmentsToCheck = segmentsToCheck
        self.options = options

        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            if apiKey == "invalid-key" {
                completionHandler(nil, OptimizelyError.generic)
            } else {
                let sampleSegments = ["segment-1"]
                completionHandler(sampleSegments, nil)
            }
        }
    }
}

// MARK: - Tests with real ODP server
// TODO: this test can be flaky. replace it with a good test account or remove it later.

extension OptimizelyUserContextTests_Segments {
    var testODPApiHost: String { return "https://api.zaius.com" }
    var testODPApiKeyForAudienceSegments: String { return "W4WzcEs-ABgXorzY7h1LCQ" }
    var testODPUserKey: String { return "vuid" }
    var testODPUserValue: String { return "d66a9d81923d4d2f99d8f64338976322" }

    func testLiveODPGraphQL() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
        let user = optimizely.createUserContext(userId: kUserId)
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: testODPApiKeyForAudienceSegments,
                                    apiHost: testODPApiHost,
                                    userKey: testODPUserKey,
                                    userValue: testODPUserValue) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual([], segments, "none of the test segments in the live ODP server")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    func testLiveODPGraphQL_defaultParameters() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
        let user = optimizely.createUserContext(userId: kUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(userKey: testODPUserKey,
                                    userValue: testODPUserValue) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual([], segments, "none of the test segments in the live ODP server")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    func testLiveODPGraphQL_noDatafile() {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let user = optimizely.createUserContext(userId: kUserId)

        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: testODPApiKeyForAudienceSegments,
                                    apiHost: testODPApiHost,
                                    userKey: testODPUserKey,
                                    userValue: testODPUserValue) { segments, error in
            XCTAssertNil(error)
            XCTAssert(segments!.contains("has_email"), "test segments are not passed to ODP, so fetching all segments.")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }

}
