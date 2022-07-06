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

class ODPManagerTests: XCTestCase {
    var manager: ODPManager!
    let sdkKey = "any"
    let odpConfig = OptimizelyODPConfig()
    
    func testFetchQualifiedSegments() {
        let segmentManager = MockODPSegmentManager(odpConfig: odpConfig)
        manager = ODPManager(sdkKey: sdkKey, odpConfig: odpConfig, segmentManager: segmentManager)
        
        let vuid = "VUID_123"
        manager.fetchQualifiedSegments(userId: vuid, segmentsToCheck: ["seg-1"], options: [.ignoreCache]) { _, _ in }
        
        XCTAssertEqual(segmentManager.receivedUserKey, "vuid")
        XCTAssertEqual(segmentManager.receivedUserValue, vuid)
        XCTAssertEqual(segmentManager.receivedSegmentsToCheck, ["seg-1"])
        XCTAssertEqual(segmentManager.receivedOptions, [.ignoreCache])

        let userId = "user-1"
        manager.fetchQualifiedSegments(userId: userId, segmentsToCheck: [], options: []) { _, _ in }

        XCTAssertEqual(segmentManager.receivedUserKey, "fs_user_id")
        XCTAssertEqual(segmentManager.receivedUserValue, "user-1")
        XCTAssertEqual(segmentManager.receivedSegmentsToCheck, [])
        XCTAssertEqual(segmentManager.receivedOptions, [])
    }
    
    func testRegisterVUIDCalled() {
        let eventManager = MockODPEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
        manager = ODPManager(sdkKey: sdkKey, odpConfig: odpConfig, eventManager: eventManager)

        // registerVUID is implicitly called on ODPManager init
        
        XCTAssertEqual(eventManager.receivedVuid, manager.vuid)
    }

    func testIdentifyUser() {
        let eventManager = MockODPEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
        manager = ODPManager(sdkKey: sdkKey, odpConfig: odpConfig, eventManager: eventManager)
        
        manager.identifyUser(userId: "user-1")
        
        XCTAssertEqual(eventManager.receivedVuid, manager.vuid)
        XCTAssertEqual(eventManager.receivedUserId, "user-1")
    }
    
    func testSendEvent() {
        let eventManager = MockODPEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
        manager = ODPManager(sdkKey: sdkKey, odpConfig: odpConfig, eventManager: eventManager)
        
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
    
    func testUpdateODPConfig() {
        let eventManager = MockODPEventManager(sdkKey: sdkKey, odpConfig: odpConfig)
        manager = ODPManager(sdkKey: sdkKey, odpConfig: odpConfig, eventManager: eventManager)
        
        // flush on valid apiKey updated (apiKey/apiHost propagated into submanagers)
        
        manager.updateODPConfig(apiKey: "key-1", apiHost: "host-1")
        XCTAssertTrue(eventManager.flushCalled)
                
        XCTAssertEqual(manager.segmentManager.odpConfig.apiKey, "key-1")
        XCTAssertEqual(manager.segmentManager.odpConfig.apiHost, "host-1")
        XCTAssertTrue(manager.segmentManager.odpConfig.enabled)
        XCTAssertEqual(manager.eventManager.odpConfig.apiKey, "key-1")
        XCTAssertEqual(manager.eventManager.odpConfig.apiHost, "host-1")
        XCTAssertTrue(manager.eventManager.odpConfig.enabled)
        
        // odp disabled with invalid apiKey (apiKey/apiHost propagated into submanagers)
        
        manager.updateODPConfig(apiKey: nil, apiHost: nil)
        XCTAssertTrue(eventManager.flushCalled)
        
        XCTAssertEqual(manager.segmentManager.odpConfig.apiKey, nil)
        XCTAssertEqual(manager.segmentManager.odpConfig.apiHost, nil)
        XCTAssertFalse(manager.segmentManager.odpConfig.enabled)
        XCTAssertEqual(manager.eventManager.odpConfig.apiKey, nil)
        XCTAssertEqual(manager.eventManager.odpConfig.apiHost, nil)
        XCTAssertFalse(manager.eventManager.odpConfig.enabled)
    }
    
    func testVuid() {
        manager = ODPManager(sdkKey: sdkKey, odpConfig: odpConfig)
        XCTAssertEqual(manager.vuid, manager.vuidManager.vuid)
    }

    // MARK: - Helpers
    
    class MockODPEventManager: ODPEventManager {
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
    
    class MockODPSegmentManager: ODPSegmentManager {
        var receivedUserKey: String!
        var receivedUserValue: String!
        var receivedSegmentsToCheck: [String]!
        var receivedOptions: [OptimizelySegmentOption]!
        
        override func fetchQualifiedSegments(userKey: String,
                                             userValue: String,
                                             segmentsToCheck: [String],
                                             options: [OptimizelySegmentOption],
                                             completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
            self.receivedUserKey = userKey
            self.receivedUserValue = userValue
            self.receivedSegmentsToCheck = segmentsToCheck
            self.receivedOptions = options
        }
    }

}
