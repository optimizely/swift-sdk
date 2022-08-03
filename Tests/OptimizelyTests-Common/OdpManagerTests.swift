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

class OdpManagerTests: XCTestCase {
    let sdkKey = "any"
    let odpConfig = OdpConfig()
    let cacheSize = 10
    let cacheTimeout = 20
    var segmentManager: MockOdpSegmentManager!
    var eventManager: MockOdpEventManager!
    var manager: OdpManager!

    override func setUp() {
        OTUtils.clearAllEventQueues()
        segmentManager = MockOdpSegmentManager(cacheSize: cacheSize,
                                               cacheTimeoutInSecs: cacheTimeout,
                                               odpConfig: odpConfig)
        eventManager = MockOdpEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
        manager = OdpManager(sdkKey: sdkKey,
                             disable: false,
                             cacheSize: cacheSize,
                             cacheTimeoutInSecs: cacheTimeout,
                             segmentManager: segmentManager,
                             eventManager: eventManager)
    }
    
    override func tearDown() {
        OTUtils.clearAllEventQueues()
    }

    // MARK: - Configurables
    
    func testConfigurations_cache() {
        let manager = OdpManager(sdkKey: sdkKey,
                                 disable: false,
                                 cacheSize: cacheSize,
                                 cacheTimeoutInSecs: cacheTimeout)
        XCTAssertEqual(manager.segmentManager?.segmentsCache.size,  cacheSize)
        XCTAssertEqual(manager.segmentManager?.segmentsCache.timeoutInSecs, cacheTimeout)
    }
    
    func testConfigurations_disableOdp() {
        let manager = OdpManager(sdkKey: sdkKey,
                                 disable: true,
                                 cacheSize: cacheSize,
                                 cacheTimeoutInSecs: cacheTimeout)
        
        XCTAssertTrue(manager.vuid.starts(with: "vuid_"), "vuid should be serverved even when ODP is disabled.")

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userId: "user1", options: []) { segments, error in
            XCTAssertNil(segments)
            XCTAssertEqual(error?.reason, OptimizelyError.odpNotEnabled.reason)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
        
        manager.updateOdpConfig(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        XCTAssertNil(manager.odpConfig.apiKey)
        XCTAssertNil(manager.odpConfig.apiHost)

        // these calls should be dropped gracefully with nil
        
        manager.identifyUser(userId: "user1")
        manager.sendEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        
        XCTAssertNil(manager.eventManager)
        XCTAssertNil(manager.segmentManager)
    }
    
    // MARK: - APIs
    
    func testFetchQualifiedSegments() {
        let vuid = "vuid_123"
        manager.fetchQualifiedSegments(userId: vuid, options: [.ignoreCache]) { _, _ in }
        
        XCTAssertEqual(segmentManager.receivedUserKey, "vuid")
        XCTAssertEqual(segmentManager.receivedUserValue, vuid)
        XCTAssertEqual(segmentManager.receivedOptions, [.ignoreCache])

        let userId = "user-1"
        manager.fetchQualifiedSegments(userId: userId, options: []) { _, _ in }

        XCTAssertEqual(segmentManager.receivedUserKey, "fs_user_id")
        XCTAssertEqual(segmentManager.receivedUserValue, "user-1")
        XCTAssertEqual(segmentManager.receivedOptions, [])
    }
    
    func testRegisterVUIDCalledAutomatically() {
        XCTAssertEqual(eventManager.receivedVuid, manager.vuid, "registerVUID is implicitly called on OdpManager init")
    }

    func testIdentifyUser() {
        manager.identifyUser(userId: "user-1")
        
        XCTAssertEqual(eventManager.receivedVuid, manager.vuid, "vuid should be added implicitly")
        XCTAssertEqual(eventManager.receivedUserId, "user-1")
    }
    
    func testSendEvent() {
        // vuid is implicitly added to identifers
        
        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id-key1": "id-val-1"], data: ["key1" : "val1"])
        
        XCTAssertEqual(eventManager.receivedType, "t1")
        XCTAssertEqual(eventManager.receivedAction, "a1")
        XCTAssertEqual(eventManager.receivedIdentifiers, ["vuid": manager.vuid,"id-key1": "id-val-1"])
        XCTAssert(eventManager.receivedData.count == 1)
        XCTAssert((eventManager.receivedData["key1"] as! String) == "val1")
        
        // user-provided vuid should not be replaced
        
        manager.sendEvent(type: "t1", action: "a1", identifiers: ["vuid": "vuid-fixed", "id-key1": "id-val-1"], data: ["key1" : "val1"])

        XCTAssertEqual(eventManager.receivedIdentifiers, ["vuid": "vuid-fixed", "id-key1": "id-val-1"])
    }
    
    func testUpdateOdpConfig_flushCalled() {
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertTrue(eventManager.flushCalled)
                
        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        XCTAssertTrue(eventManager.flushCalled)
    }
    
    func testUpdateOdpConfig_odpConfigPropagatedProperly() {
        let manager = OdpManager(sdkKey: sdkKey,
                                 disable: false,
                                 cacheSize: cacheSize,
                                 cacheTimeoutInSecs: cacheTimeout)

        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
                
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiKey, "key-1")
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiHost, "host-1")
        XCTAssertEqual(manager.segmentManager?.odpConfig.odpServiceIntegrated, true)
        XCTAssertEqual(manager.eventManager?.odpConfig.apiKey, "key-1")
        XCTAssertEqual(manager.eventManager?.odpConfig.apiHost, "host-1")
        XCTAssertEqual(manager.eventManager?.odpConfig.odpServiceIntegrated, true)
        
        // odp disabled with invalid apiKey (apiKey/apiHost propagated into submanagers)
        
        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiKey, nil)
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiHost, nil)
        XCTAssertEqual(manager.segmentManager?.odpConfig.odpServiceIntegrated, false)
        XCTAssertEqual(manager.eventManager?.odpConfig.apiKey, nil)
        XCTAssertEqual(manager.eventManager?.odpConfig.apiHost, nil)
        XCTAssertEqual(manager.eventManager?.odpConfig.odpServiceIntegrated, false)
    }

    
    func testVuid() {
        XCTAssertEqual(manager.vuid, manager.vuidManager.vuid)
    }

    // MARK: - Helpers
    
    class MockOdpEventManager: OdpEventManager {
        var receivedVuid: String!
        var receivedUserId: String!
        
        var receivedType: String!
        var receivedAction: String!
        var receivedIdentifiers: [String: String]!
        var receivedData: [String: Any]!
        
        var flushCalled = false
        
        override func registerVUID(vuid: String) {
            self.receivedVuid = vuid
        }
        
        override func identifyUser(vuid: String, userId: String) {
            self.receivedVuid = vuid
            self.receivedUserId = userId
        }
        
        override func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any]) {
            self.receivedType = type
            self.receivedAction = action
            self.receivedIdentifiers = identifiers
            self.receivedData = data
        }
        
        override func flush() {
            self.flushCalled = true
        }
    }
    
    class MockOdpSegmentManager: OdpSegmentManager {
        var receivedUserKey: String!
        var receivedUserValue: String!
        var receivedOptions: [OptimizelySegmentOption]!
        
        override func fetchQualifiedSegments(userKey: String,
                                             userValue: String,
                                             options: [OptimizelySegmentOption],
                                             completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
            self.receivedUserKey = userKey
            self.receivedUserValue = userValue
            self.receivedOptions = options
        }
    }

}
