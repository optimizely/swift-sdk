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
    let kApiKey = "any-key"
    let kUserId = "tester"
    let kUserIdKey = "$opt_user_id"

    override func setUp() {
        optimizely.audienceSegmentsHandler = segmentHandler
        user = optimizely.createUserContext(userId: kUserId)
    }
    
    func testIsQualifiedFor() {
        XCTAssertFalse(user.isQualifiedFor(segment: "a"))

        user.qualifiedSegments = ["a", "b"]
        XCTAssertTrue(user.isQualifiedFor(segment: "a"))
        XCTAssertFalse(user.isQualifiedFor(segment: "x"))
        
        user.qualifiedSegments = []
        XCTAssertFalse(user.isQualifiedFor(segment: "a"))
    }
    
    func testFetchQualifiedSegments_successDefaultUser() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey) { error in
            XCTAssertNil(error)
            XCTAssert(self.user.qualifiedSegments == [self.kApiKey, self.kUserIdKey, self.kUserId])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_sdkNotReady() {
        user.optimizely = nil
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey) { error in
            XCTAssertEqual(OptimizelyError.sdkNotReady.reason, error?.reason)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_fetchFailed() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: "invalid-key") { error in
            XCTAssertNotNil(error)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_segmentsToCheck_emptyBeforeStart() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey) { error in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertNil(segmentHandler.segmentsToCheck)
    }
    
    func testFetchQualifiedSegments_segmentsToCheck_validAfterStart() {
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        try? optimizely.start(datafile: datafile)

        // fetch segments after SDK initialized, so segmentsToCheck will be used.
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: kApiKey) { error in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
        
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(segmentHandler.segmentsToCheck!))
    }
    
    func testCustomizeAudienceSegmentsHandler()  {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                          periodicDownloadInterval: 60,
                                          segmentsCacheSize: 12,
                                          segmentsCacheTimeout: 123)

        XCTAssertEqual(12, optimizely.audienceSegmentsHandler.segmentsCache.size)
        XCTAssertEqual(123, optimizely.audienceSegmentsHandler.segmentsCache.timeoutInSecs)
    }

}

// MARK: - MockAudienceSegmentsHandler

class MockAudienceSegmentsHandler: AudienceSegmentsHandler {
    var segmentsToCheck: [String]?
    
    override func fetchQualifiedSegments(apiKey: String,
                                userKey: String,
                                userValue: String,
                                segmentsToCheck: [String]?,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            self.segmentsToCheck = segmentsToCheck
            
            if apiKey == "invalid-key" {
                completionHandler(nil, OptimizelyError.generic)
            } else {
                // pass back [key, userKey, userValue] in segments for validation
                let sampleSegments = [apiKey, userKey, userValue]
                completionHandler(sampleSegments, nil)
            }
        }
    }
}

