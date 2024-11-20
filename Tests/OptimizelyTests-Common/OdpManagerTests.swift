//
// Copyright 2022-2023, Optimizely, Inc. and contributors 
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
                                               cacheTimeoutInSecs: cacheTimeout)
        eventManager = MockOdpEventManager(sdkKey: sdkKey)
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
    
    // MARK: - disable ODP
    
    func testConfigurations_disableOdp() {
        let manager = OdpManager(sdkKey: sdkKey,
                                 disable: true,
                                 cacheSize: cacheSize,
                                 cacheTimeoutInSecs: cacheTimeout)

        let sem = DispatchSemaphore(value: 0)
        manager.fetchQualifiedSegments(userId: "user1", options: []) { segments, error in
            XCTAssertNil(segments)
            XCTAssertEqual(error?.reason, OptimizelyError.odpNotEnabled.reason)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
        
        manager.updateOdpConfig(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        XCTAssertNil(manager.odpConfig)

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
    
    
    func testRegisterVUIDDoesNotCallAutomatically_vuidDisabled() {
        let newEventManager = MockOdpEventManager(sdkKey: sdkKey)
        
        _ = OdpManager(sdkKey: sdkKey,
                       disable: false,
                       cacheSize: cacheSize,
                       cacheTimeoutInSecs: cacheTimeout,
                       segmentManager: segmentManager,
                       eventManager: newEventManager)
        
        XCTAssertNil(newEventManager.receivedRegisterVuid)
    }
    
    func testRegisterVUIDCalledAutomatically_odpDisabled() {
        let newEventManager = MockOdpEventManager(sdkKey: sdkKey)
        
        _ = OdpManager(sdkKey: sdkKey,
                       disable: true,
                       cacheSize: cacheSize,
                       cacheTimeoutInSecs: cacheTimeout,
                       segmentManager: segmentManager,
                       eventManager: newEventManager)
        
        XCTAssertNil(newEventManager.receivedRegisterVuid, "registerVUID should not implicitly called when ODP disabled")
    }
    
    // MARK: - identifyUser

    func testIdentifyUser_datafileNotReady() {
        manager.identifyUser(userId: "user-1")
        
        XCTAssertEqual(eventManager.receivedIdentifyUserId, "user-1")
    }
    
    func testIdentifyUser_odpIntegrated() {
        let vuid = "vuid_123"
        manager.vuid = vuid
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        manager.identifyUser(userId: "user-1")
        
        XCTAssert(VuidManager.isVuid(eventManager.receivedIdentifyVuid))
        XCTAssertEqual(eventManager.receivedIdentifyUserId, "user-1")
    }
    
    func testIdentifyUser_odpIntegrated_vuidAsUserId() {
        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        
        let vuidAsUserId = VuidManager.newVuid
        manager.identifyUser(userId: vuidAsUserId)
        
        XCTAssertEqual(eventManager.receivedIdentifyVuid, vuidAsUserId)
        XCTAssertNil(eventManager.receivedIdentifyUserId)
    }
    
    func testIdentifyUser_odpNotIntegrated() {
        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        manager.identifyUser(userId: "user-1")
        
        XCTAssertNil(eventManager.receivedIdentifyUserId, "identifyUser event requeut should be discarded if ODP not integrated.")
    }

    func testIdentifyUser_odpDisabled() {
        manager.enabled = false
        manager.identifyUser(userId: "user-1")
        
        XCTAssertNil(eventManager.receivedIdentifyUserId, "identifyUser event requeut should be discarded if ODP disabled.")
    }
    
    // MARK: - sendEvent
    
    func testSendEvent_datafileNotReady() {
        let vuid = "vuid_123"
        manager.vuid = vuid
        
        try? manager.sendEvent(type: "t1", action: "a1", identifiers: ["id-key1": "id-val-1"], data: ["key1" : "val1"])
        
        XCTAssertEqual(eventManager.receivedType, "t1")
        XCTAssertEqual(eventManager.receivedAction, "a1")
        XCTAssertEqual(eventManager.receivedIdentifiers, ["vuid": "vuid_123","id-key1": "id-val-1"])
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
    
    func testSendEvent_emptyAction() {
        do {
            try manager.sendEvent(type: nil, action: "", identifiers: [:], data: [:])
            XCTFail()
        } catch OptimizelyError.odpInvalidAction {
            XCTAssert(true)
        } catch {
            XCTFail("OptimizelyError expected if data has an empty action.")
        }
    }

    func testSendEvent_emptyOrNilType() {
        try? manager.sendEvent(type: nil, action: "a1", identifiers: [:], data: [:])
        XCTAssertEqual(eventManager.receivedType, "fullstack")
        
        try? manager.sendEvent(type: "", action: "a1", identifiers: [:], data: [:])
        XCTAssertEqual(eventManager.receivedType, "fullstack")
    }

    func testSendEvent_aliasIdentifiers() {
        let vuid = "vuid_123"
        manager.vuid = vuid
        
        try? manager.sendEvent(type: nil, action: "a1", identifiers: ["fs_user_id": "v1"], data: [:])
        XCTAssertEqual(eventManager.receivedIdentifiers, ["fs_user_id": "v1", "vuid": vuid])
        
        try? manager.sendEvent(type: nil, action: "a1", identifiers: ["fs-user-id": "v1"], data: [:])
        XCTAssertEqual(eventManager.receivedIdentifiers, ["fs_user_id": "v1", "vuid": vuid])

        try? manager.sendEvent(type: nil, action: "a1", identifiers: ["FS_USER_ID": "v1"], data: [:])
        XCTAssertEqual(eventManager.receivedIdentifiers, ["fs_user_id": "v1", "vuid": vuid])

        try? manager.sendEvent(type: nil, action: "a1", identifiers: ["FS-USER-ID": "v1"], data: [:])
        XCTAssertEqual(eventManager.receivedIdentifiers, ["fs_user_id": "v1", "vuid": vuid])
        
        try? manager.sendEvent(type: nil, action: "a1", identifiers: ["email": "e1", "FS-USER-ID": "v1"], data: [:])
        XCTAssertEqual(eventManager.receivedIdentifiers, ["email": "e1", "fs_user_id": "v1", "vuid": vuid])
    }

    // MARK: - updateConfig
    
    func testUpdateOdpConfig_segmentResetCalled() {
        // initially
        // - apiKey = nil
        // - apiHost = nil
        // - segmentsToCheck = []

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
        // initially
        // - apiKey = nil
        // - apiHost = nil
        // - segmentsToCheck = []

        manager.updateOdpConfig(apiKey: "key-1", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 1, "flush called before")
        XCTAssertEqual(eventManager.flushApiKeys[0], nil)

        eventManager.flushApiKeys.removeAll()
        eventManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 1)
        XCTAssertEqual(eventManager.flushApiKeys[0], "key-1", "old events must be flushed with the old odp key")

        eventManager.flushApiKeys.removeAll()
        eventManager.resetCalled = false

        manager.updateOdpConfig(apiKey: "key-2", apiHost: "host-1", segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 1)
        XCTAssertEqual(eventManager.flushApiKeys[0], "key-2")

        eventManager.flushApiKeys.removeAll()
        eventManager.resetCalled = false

        manager.updateOdpConfig(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        XCTAssertEqual(eventManager.flushApiKeys.count, 1)
        XCTAssertEqual(eventManager.flushApiKeys[0], "key-2")
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
    
    // MARK: - flush on EnterBackground
    
    func testFlushWhenAppGoesToBackground() {
        XCTAssertEqual(eventManager.flushApiKeys.count, 0)
        manager.applicationDidEnterBackground()
        XCTAssertEqual(eventManager.flushApiKeys.count, 1, "flush called when app goes to background")
    }


    // MARK: - Helpers
    
    class MockOdpEventManager: OdpEventManager {
        var receivedRegisterVuid: String!
        
        var receivedIdentifyVuid: String!
        var receivedIdentifyUserId: String?

        var receivedType: String!
        var receivedAction: String!
        var receivedIdentifiers: [String: String]!
        var receivedData: [String: Any?]!
        
        var flushApiKeys = [String?]()
        
        var resetCalled = false

        override func sendInitializedEvent(vuid: String) {
            self.receivedRegisterVuid = vuid
        }
        
        override func identifyUser(vuid: String?, userId: String?) {
            self.receivedIdentifyVuid = vuid
            self.receivedIdentifyUserId = userId
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
        
        override func reset() {
            self.resetCalled = true
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
