//
// Copyright 2023, Optimizely, Inc. and contributors 
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final class OptimizelyUserContextTests_ODP_Aync_Await: XCTestCase {
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
    
    // MARK: - fetchQualifiedSegments (non-blocking)
    
    // MARK: - Success
    
    func testFetchQualifiedSegments_successDefaultUser() async throws {
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)
        
        var _error: OptimizelyError?
        
        do {
            try await user.fetchQualifiedSegments()
        } catch {
            _error = error as? OptimizelyError
        }
        XCTAssertNil(_error)
        XCTAssertEqual(self.user.qualifiedSegments, ["odp-segment-1"])
    }
    
    // MARK: - Failure
    
    func testFetchQualifiedSegments_sdkNotReady()  async throws {
        user = optimizely.createUserContext(userId: kUserId)
        user.optimizely = nil
        user.qualifiedSegments = ["dummy"]
        
        var _error: OptimizelyError?
        
        do {
            try await user.fetchQualifiedSegments()
        } catch {
            _error = error as? OptimizelyError
        }
        XCTAssertEqual(OptimizelyError.sdkNotReady.reason, _error?.reason)
        XCTAssertNil(self.user.qualifiedSegments)
        
    }
    
    func testFetchQualifiedSegments_fetchFailed() async throws {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = ["dummy"]
        
        var _error: OptimizelyError?
        
        do {
            try await user.fetchQualifiedSegments()
        } catch {
            _error = error as? OptimizelyError
        }
        XCTAssertNotNil(_error)
        XCTAssertNil(self.user.qualifiedSegments)
        
    }
    
    // MARK: - SegmentsToCheck
    
    func testFetchQualifiedSegments_segmentsToCheck_validAfterStart() async throws {
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)
        
        try await user.fetchQualifiedSegments()
        
        XCTAssertEqual(Set(["odp-segment-1", "odp-segment-2", "odp-segment-3"]), Set(odpManager.odpConfig.segmentsToCheck))
    }
    
    func testFetchQualifiedSegments_segmentsNotUsed() async throws  {
        let datafile = OTUtils.loadJSONDatafile("odp_integrated_no_segments")!
        try? optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)
        
        var _error: OptimizelyError?
        
        do {
            try await user.fetchQualifiedSegments()
        } catch {
            _error = error as? OptimizelyError
        }
        XCTAssertNil(_error)
    }
    
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension OptimizelyUserContextTests_ODP_Aync_Await {
    
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
}

