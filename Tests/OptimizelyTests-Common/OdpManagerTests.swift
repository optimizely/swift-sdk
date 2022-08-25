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
    let cacheSize = 10
    let cacheTimeout = 20
    var segmentManager: MockOdpSegmentManager!
    var eventManager: MockOdpEventManager!
    var manager: OdpManager!

    override func setUp() {
        OTUtils.clearAllEventQueues()
        segmentManager = MockOdpSegmentManager(cacheSize: cacheSize,
                                               cacheTimeoutInSecs: cacheTimeout,
                                               odpConfig: OdpConfig())
        eventManager = MockOdpEventManager(sdkKey: sdkKey, odpConfig: OdpConfig())
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
        XCTAssertEqual(manager.segmentManager?.segmentsCache.maxSize, cacheSize)
        XCTAssertEqual(manager.segmentManager?.segmentsCache.timeoutInSecs, cacheTimeout)
    }
    
    // MARK: - diable ODP
    
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
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        
        XCTAssertNil(manager.eventManager)
        XCTAssertNil(manager.segmentManager)
    }
    
    // MARK: - fetchQualifiedSegments
    
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
    
    // MARK: - registerVuid
    
    func testRegisterVUIDCalledAutomatically() {
        XCTAssertEqual(eventManager.receivedVuid, manager.vuid, "registerVUID is implicitly called on OdpManager init")
    }

    func testRegisterVUIDCalledAutomatically_odpDisabled() {
        let newEventManager = MockOdpEventManager(sdkKey: sdkKey, odpConfig: OdpConfig())
        
        _ = OdpManager(sdkKey: sdkKey,
                       disable: true,
                       cacheSize: cacheSize,
                       cacheTimeoutInSecs: cacheTimeout,
                       segmentManager: segmentManager,
                       eventManager: newEventManager)
        
        XCTAssertNil(newEventManager.receivedVuid, "registerVUID should not implicitly called when ODP disabled")
    }
    
    // MARK: - identifyUser

    func testIdentifyUser_datafileNotReady() {
        manager.identifyUser(userId: "user-1")
        
        XCTAssertEqual(eventManager.receivedUserId, "user-1")
    }
    
    func testIdentifyUser_odpIntegrated() {
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        manager.identifyUser(userId: "user-1")
        
        XCTAssertEqual(eventManager.receivedUserId, "user-1")
    }
    
    func testIdentifyUser_odpNotIntegrated() {
        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        manager.identifyUser(userId: "user-1")
        
        XCTAssertNil(eventManager.receivedUserId, "identifyUser event requeut should be discarded if ODP not integrated.")
    }

    func testIdentifyUser_odpDisabled() {
        manager.enabled = false
        manager.identifyUser(userId: "user-1")
        
        XCTAssertNil(eventManager.receivedUserId, "identifyUser event requeut should be discarded if ODP disabled.")
    }
    
    // MARK: - sendEvent
    
    func testSendEvent_datafileNotReady() {
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: ["id-key1": "id-val-1"], data: ["key1" : "val1"])
        
        XCTAssertEqual(eventManager.receivedType, "t1")
        XCTAssertEqual(eventManager.receivedAction, "a1")
        XCTAssertEqual(eventManager.receivedIdentifiers, ["vuid": manager.vuid,"id-key1": "id-val-1"])
        XCTAssert(eventManager.receivedData.count == 1)
        XCTAssert((eventManager.receivedData["key1"] as! String) == "val1")
        
        // user-provided vuid should not be replaced
        
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: ["vuid": "vuid-fixed", "id-key1": "id-val-1"], data: ["key1" : "val1"])

        XCTAssertEqual(eventManager.receivedIdentifiers, ["vuid": "vuid-fixed", "id-key1": "id-val-1"])
    }
    
    func testSendEvent_odpIntegrated() {
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: ["id-key1": "id-val-1"], data: ["key1" : "val1"])

        XCTAssertEqual(eventManager.receivedType, "t1")
    }
    
    func testSendEvent_odpNotIntegrated() {
        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: ["id-key1": "id-val-1"], data: ["key1" : "val1"])

        XCTAssertNil(eventManager.receivedType, "sendEvent requeut should be discarded if ODP not integrated.")
    }

    func testSendEvent_odpDisabled() {
        manager.enabled = false
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: ["id-key1": "id-val-1"], data: ["key1" : "val1"])

        XCTAssertNil(eventManager.receivedType, "sendEvent requeut should be discarded if ODP disabled.")
    }

    // MARK: - updateConfig
    
    func testUpdateOdpConfig_resetCalled() {
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertTrue(segmentManager.resetCalled)
        
        segmentManager.resetCalled = false
        
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertFalse(segmentManager.resetCalled, "no change, so reset should not be called")

        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertTrue(segmentManager.resetCalled)

        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-2", segmentsToCheck: [])
        XCTAssertTrue(segmentManager.resetCalled)

        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-2", segmentsToCheck: ["a"])
        XCTAssertTrue(segmentManager.resetCalled)

        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-2", segmentsToCheck: ["a", "b"])
        XCTAssertTrue(segmentManager.resetCalled)

        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-2", segmentsToCheck: ["c"])
        XCTAssertTrue(segmentManager.resetCalled)
        
        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-2", segmentsToCheck: ["c"])
        XCTAssertFalse(segmentManager.resetCalled, "no change, so reset should not be called")
        
        segmentManager.resetCalled = false

        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        XCTAssertTrue(segmentManager.resetCalled)
    }

    func testUpdateOdpConfig_flushCalled() {
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 2, "flush called before and after update")
        XCTAssertEqual(eventManager.flushApiKeys[0], nil)
        XCTAssertEqual(eventManager.flushApiKeys[1], "key-1")
        
        eventManager.flushApiKeys.removeAll()

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 2)
        XCTAssertEqual(eventManager.flushApiKeys[0], "key-1", "old events must be flushed with the old odp key")
        XCTAssertEqual(eventManager.flushApiKeys[1], "key-2", "remaining events must be flushed with the new odp key")

        eventManager.flushApiKeys.removeAll()

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 1, "flush called once when no change")
        XCTAssertEqual(eventManager.flushApiKeys[0], "key-2")

        eventManager.flushApiKeys.removeAll()

        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 2)
        XCTAssertEqual(eventManager.flushApiKeys[0], "key-2")
        XCTAssertEqual(eventManager.flushApiKeys[1], nil)
    }
    
    func testUpdateOdpConfig_odpConfigPropagatedProperly() {
        let manager = OdpManager(sdkKey: sdkKey,
                                 disable: false,
                                 cacheSize: cacheSize,
                                 cacheTimeoutInSecs: cacheTimeout)

        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
                
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiKey, "key-1")
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiHost, "host-1")
        XCTAssertEqual(manager.segmentManager?.odpConfig.eventQueueingAllowed, true)
        XCTAssertEqual(manager.eventManager?.odpConfig.apiKey, "key-1")
        XCTAssertEqual(manager.eventManager?.odpConfig.apiHost, "host-1")
        XCTAssertEqual(manager.eventManager?.odpConfig.eventQueueingAllowed, true)
        
        // odp disabled with invalid apiKey (apiKey/apiHost propagated into submanagers)
        
        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiKey, nil)
        XCTAssertEqual(manager.segmentManager?.odpConfig.apiHost, nil)
        XCTAssertEqual(manager.segmentManager?.odpConfig.eventQueueingAllowed, false)
        XCTAssertEqual(manager.eventManager?.odpConfig.apiKey, nil)
        XCTAssertEqual(manager.eventManager?.odpConfig.apiHost, nil)
        XCTAssertEqual(manager.eventManager?.odpConfig.eventQueueingAllowed, false)
    }

    // MARK: - vuid
    
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
        var receivedData: [String: Any?]!
        
        var flushApiKeys = [String?]()
        
        override func registerVUID(vuid: String) {
            self.receivedVuid = vuid
        }
        
        override func identifyUser(vuid: String, userId: String) {
            self.receivedVuid = vuid
            self.receivedUserId = userId
        }
        
        override func sendEvent(type: String, action: String, identifiers: [String: String], data: [String: Any?]) {
            self.receivedType = type
            self.receivedAction = action
            self.receivedIdentifiers = identifiers
            self.receivedData = data
        }
        
        override func flush() {
            self.flushApiKeys.append(odpConfig.apiKey)
        }
    }
    
    class MockOdpSegmentManager: OdpSegmentManager {
        var receivedUserKey: String!
        var receivedUserValue: String!
        var receivedOptions: [OptimizelySegmentOption]!
        
        var resetCalled = false

        override func fetchQualifiedSegments(userKey: String,
                                             userValue: String,
                                             options: [OptimizelySegmentOption],
                                             completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
            self.receivedUserKey = userKey
            self.receivedUserValue = userValue
            self.receivedOptions = options
        }
        
        override func reset() {
            self.resetCalled = true
        }
    }

}
