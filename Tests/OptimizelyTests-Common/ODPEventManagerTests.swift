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

class ODPEventManagerTests: XCTestCase {
    var manager: ODPEventManager!
    var odpConfig: OptimizelyODPConfig!
    
    var options = [OptimizelySegmentOption]()
    
    var userKey = "vuid"
    var userValue = "test-user"
    static var receivedApiKey: String?
    static var receivedApiHost: String?
    
    let customData: [String: Any] = ["key-1": "value-1",
                                     "key-2": 12.5,
                                     "model": "overruled"]

    override func setUp() {
        OTUtils.createDocumentDirectoryIfNotAvailable()

        // no valid apiKey, so flush will return immediately
        odpConfig = OptimizelyODPConfig()
        
        manager = ODPEventManager(sdkKey: "any",
                                  odpConfig: odpConfig,
                                  apiManager: MockZaiusApiManager())
    }
    
    override func tearDown() {
        OTUtils.clearAllEventQueues()
    }
    
    // MARK: - sendEvent

    func testSendEvent_noApiKey() {
        manager.sendEvent(type: "t1",
                          action: "a1",
                          identifiers: ["id-key-1": "id-value-1"],
                          data: customData)

        XCTAssertEqual(1, manager.eventQueue.count)
        sleep(3)
        XCTAssertEqual(1, manager.eventQueue.count, "not flushed since apiKey is not ready")
        
        let evt = manager.eventQueue.getFirstItem()!
        XCTAssertEqual("t1", evt.type)
        XCTAssertEqual("a1", evt.action)
        XCTAssertEqual(["id-key-1": "id-value-1"], evt.identifiers)
        validateData(evt.data, customData: customData)
    }
    
    func testRegisterVUID_noApiKey() {
        manager.registerVUID(vuid: "v1")
        
        XCTAssertEqual(1, manager.eventQueue.count)
        let evt = manager.eventQueue.getFirstItem()!
        XCTAssertEqual("fullstack", evt.type)
        XCTAssertEqual("client_initialized", evt.action)
        XCTAssertEqual(["vuid": "v1"], evt.identifiers)
        validateData(evt.data, customData: [:])
    }
    
    func testIdentifyUser_noApiKey() {
        manager.identifyUser(vuid: "v1", userId: "u1")
        
        XCTAssertEqual(1, manager.eventQueue.count)
        let evt = manager.eventQueue.getFirstItem()!
        XCTAssertEqual("fullstack", evt.type)
        XCTAssertEqual("identified", evt.action)
        XCTAssertEqual(["vuid": "v1", "fs_user_id": "u1"], evt.identifiers)
        validateData(evt.data, customData: [:])
    }
    
    func testSendEvent_apiKey() {
        odpConfig = OptimizelyODPConfig()
        odpConfig.apiKey = "valid"
        odpConfig.apiHost = "host"
        
        manager = ODPEventManager(sdkKey: "any",
                                  odpConfig: odpConfig,
                                  apiManager: MockZaiusApiManager())
        manager.sendEvent(type: "t1",
                          action: "a1",
                          identifiers: ["id-key-1": "id-value-1"],
                          data: customData)
        
        XCTAssertEqual(1, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count, "flushed since apiKey is ready")
    }
    
    // MARK: - flush

    func testFlush_apiKey() {
        let event = ODPEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        
        // apiKey is not ready
        
        manager.dispatch(event)
        manager.dispatch(event)
        manager.dispatch(event)
                
        XCTAssertEqual(3, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(3, manager.eventQueue.count, "not flushed since apiKey is not ready")

        // apiKey is ready
        
        odpConfig.apiKey = "valid"
        odpConfig.apiHost = "host"
        
        manager.flush()
        
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count)
    }
    
    func testFlush_batch_1() {
        XCTFail()
    }
 
    func testFlush_batch_3() {
        XCTFail()
    }

    func testFlush_batch_moreThanBatchSize() {
        XCTFail()
    }

    func testFlush_emptyQueue() {
        XCTFail()
    }

    // MARK: - Errors

    func testFlushError_retry() {
        XCTFail()
    }
    
    func testFlushError_noRetry() {
        XCTFail()
    }

    // MARK: - OdpConfig
    
    func testOdpConfig() {
        odpConfig.apiHost = "test-host"
        odpConfig.apiKey = "test-key"
        
        manager = ODPEventManager(sdkKey: "any",
                                  odpConfig: odpConfig,
                                  apiManager: MockZaiusApiManager())

        let event = ODPEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        manager.dispatch(event)
        manager.flush()
        
        XCTAssertEqual("test-host", ODPEventManagerTests.receivedApiHost)
        XCTAssertEqual("test-key", ODPEventManagerTests.receivedApiKey)
    }
    
    // MARK: - Utils
    
    func validateData(_ data: [String: Any], customData: [String: Any]) {
        XCTAssert((data["idempotence_id"] as! String).count > 3)
        XCTAssert((data["data_source_type"] as! String) == "sdk")
        XCTAssert((data["data_source"] as! String) == "swift-sdk")
        XCTAssert((data["data_source_version"] as! String).count > 3)
        XCTAssert((data["os"] as! String) == "iOS")
        XCTAssert((data["os_version"] as! String).count > 3)
        XCTAssert((data["device_type"] as! String).count > 3)
        
        // overruled prop
        if customData.isEmpty {
            XCTAssert((data["model"] as! String).count > 3)
        } else {
            XCTAssert((data["model"] as! String) == "overruled")
        }
        
        // other custom data
        XCTAssert((data["key-1"] as! String) == "value-1")
        XCTAssert((data["key-2"] as! Double) == 12.5)
    }
    
    // MARK: - MockZaiusApiManager

    class MockZaiusApiManager: ZaiusRestApiManager {
        
        override func sendODPEvents(apiKey: String,
                                    apiHost: String,
                                    events: [ODPEvent],
                                    completionHandler: @escaping (OptimizelyError?) -> Void) {
            ODPEventManagerTests.receivedApiKey = apiKey
            ODPEventManagerTests.receivedApiHost = apiHost
            
            DispatchQueue.global().async {
                if apiKey == "invalid-key-no-retry" {
                    completionHandler(OptimizelyError.odpEventFailed("403", false))
                } else if apiKey == "valid-key-retry-error" {
                        completionHandler(OptimizelyError.odpEventFailed("network error", true))
                } else {
                    completionHandler(nil)
                }
            }
        }
    }
    
}
