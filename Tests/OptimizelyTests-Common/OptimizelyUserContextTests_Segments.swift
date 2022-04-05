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

    var optimizely: OptimizelyClient!
    var user: OptimizelyUserContext!
    let kUserId = "tester"

    override func setUp() {
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        optimizely.audienceSegmentsHandler = MockAudienceSegmentsHandler()
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
        user.fetchQualifiedSegments(apiKey: MockAudienceSegmentsHandler.kApiKeyGood) { error in
            XCTAssertNil(error)
            XCTAssert(self.user.qualifiedSegments == [MockAudienceSegmentsHandler.kApiKeyGood, "$opt_user_id", self.kUserId])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_sdkNotReady() {
        user.optimizely = nil
        
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: MockAudienceSegmentsHandler.kApiKeyGood) { error in
            XCTAssertEqual(OptimizelyError.sdkNotReady.reason, error?.reason)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }
    
    func testFetchQualifiedSegments_fetchFailed() {
        let sem = DispatchSemaphore(value: 0)
        user.fetchQualifiedSegments(apiKey: MockAudienceSegmentsHandler.kApiKeyBad) { error in
            XCTAssertNotNil(error)
            XCTAssertNil(self.user.qualifiedSegments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(3)))
    }

}

class MockAudienceSegmentsHandler: OPTAudienceSegmentsHandler {
    static let kApiKeyGood = "apiKeyGood"
    static let kApiKeyBad = "apiKeyBad"

    func fetchQualifiedSegments(apiKey: String,
                                userKey: String,
                                userValue: String,
                                segmentsToCheck: [String]?,
                                options: [OptimizelySegmentOption],
                                completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            if apiKey == MockAudienceSegmentsHandler.kApiKeyGood {
                let sampleSegments = [apiKey, userKey, userValue]
                completionHandler(sampleSegments, nil)
            } else {
                completionHandler(nil, OptimizelyError.generic)
            }
        }
    }
}

