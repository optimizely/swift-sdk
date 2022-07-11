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

class OdpEventManagerTests: XCTestCase {
    var manager: OdpEventManager!
    var odpConfig: OdpConfig!
    var apiManager = MockZaiusApiManager()

    var options = [OptimizelySegmentOption]()
    
    var userKey = "vuid"
    var userValue = "test-user"
    
    let customData: [String: Any] = ["key-1": "value-1",
                                     "key-2": 12.5,
                                     "model": "overruled"]

    override func setUp() {
        OTUtils.clearAllEventQueues()
        OTUtils.createDocumentDirectoryIfNotAvailable()

        // no valid apiKey, so flush will return immediately
        odpConfig = OdpConfig()
        
        manager = OdpEventManager(sdkKey: "any",
                                  odpConfig: odpConfig,
                                  apiManager: apiManager)
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
        odpConfig = OdpConfig()
        odpConfig.update(apiKey: "valid", apiHost: "host")
        
        manager = OdpEventManager(sdkKey: "any",
                                  odpConfig: odpConfig,
                                  apiManager: apiManager)
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
        let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        
        // apiKey is not ready
        
        manager.dispatch(event)
        manager.dispatch(event)
        manager.dispatch(event)
                
        XCTAssertEqual(3, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(3, manager.eventQueue.count, "not flushed since apiKey is not ready")

        // apiKey is ready
        
        odpConfig.update(apiKey: "valid", apiHost: "host")
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(0, manager.eventQueue.count)
    }
    
    // MARK: - batch

    func testFlush_batch_1() {
        let events = [
            OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        ]
        manager.dispatch(events[0])
        
        odpConfig.update(apiKey: "valid", apiHost: "host")
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.receivedBatchEvents.count)
        XCTAssertEqual(1, apiManager.receivedBatchEvents[0].count)
        validateEvents(events, apiManager.receivedBatchEvents[0])
    }
 
    func testFlush_batch_3() {
        let events = [
            OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:]),
            OdpEvent(type: "t2", action: "a2", identifiers: [:], data: [:]),
            OdpEvent(type: "t3", action: "a3", identifiers: [:], data: [:])
        ]

        for e in events {
            manager.dispatch(e)
        }

        odpConfig.update(apiKey: "valid", apiHost: "host")
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.receivedBatchEvents.count)
        XCTAssertEqual(3, apiManager.receivedBatchEvents[0].count)
        validateEvents(events, apiManager.receivedBatchEvents[0])
    }

    func testFlush_batch_moreThanBatchSize() {
        let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        let events = [OdpEvent](repeating: event, count: 11)
        
        for e in events {
            manager.dispatch(e)
        }
        
        odpConfig.update(apiKey: "valid", apiHost: "host")
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(2, apiManager.receivedBatchEvents.count)
        XCTAssertEqual(10, apiManager.receivedBatchEvents[0].count)
        XCTAssertEqual(1, apiManager.receivedBatchEvents[1].count)
        validateEvents(events, apiManager.receivedBatchEvents[0] + apiManager.receivedBatchEvents[1])
    }

    func testFlush_emptyQueue() {
        odpConfig.update(apiKey: "valid", apiHost: "host")
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(0, apiManager.receivedBatchEvents.count)
    }
    
    // MARK: - multiple skdKeys
    
    func testMultipleSdkKeys_doNotInterfere() {
        let apiManager1 = MockZaiusApiManager()
        let apiManager2 = MockZaiusApiManager()
        let odpConfig1 = OdpConfig()
        let odpConfig2 = OdpConfig()

        let manager1 = OdpEventManager(sdkKey: "sdkKey-1",
                                       odpConfig: odpConfig1,
                                       apiManager: apiManager1)
        let manager2 = OdpEventManager(sdkKey: "sdkKey-2",
                                       odpConfig: odpConfig2,
                                       apiManager: apiManager2)
        
        let event1 = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        let event2 = OdpEvent(type: "t2", action: "a2", identifiers: [:], data: [:])

        manager1.dispatch(event1)
        manager1.dispatch(event1)
        
        manager2.dispatch(event2)
        
        XCTAssertEqual(0, apiManager1.receivedBatchEvents.count)
        XCTAssertEqual(0, apiManager2.receivedBatchEvents.count)

        odpConfig1.update(apiKey: "valid", apiHost: "host")
        manager1.flush()
        sleep(1)

        XCTAssertEqual(1, apiManager1.receivedBatchEvents.count)
        XCTAssertEqual(2, apiManager1.receivedBatchEvents[0].count)
        XCTAssertEqual(0, apiManager2.receivedBatchEvents.count)

        odpConfig2.update(apiKey: "valid", apiHost: "host")
        manager2.flush()
        sleep(1)

        XCTAssertEqual(1, apiManager1.receivedBatchEvents.count)
        XCTAssertEqual(2, apiManager1.receivedBatchEvents[0].count)
        XCTAssertEqual(1, apiManager2.receivedBatchEvents.count)
        XCTAssertEqual(1, apiManager2.receivedBatchEvents[0].count)
    }

    // MARK: - errors

    func testFlushError_retry() {
        let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        let events = [OdpEvent](repeating: event, count: 2)

        for e in events {
            manager.dispatch(e)
        }

        odpConfig.update(apiKey: "valid-key-retry-error", apiHost: "host")
        manager.flush()
        sleep(1)
        
        let maxRetries = 1   // multiple retries disabled
        XCTAssertEqual(maxRetries, apiManager.receivedBatchEvents.count, "should be retried \(maxRetries) times (a batch of 2 events)")
        XCTAssertEqual(2, manager.eventQueue.count, "the events should remain after giving up")
    }
    
    func testFlushError_noRetry() {
        let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        let events = [OdpEvent](repeating: event, count: 15)

        for e in events {
            manager.dispatch(e)
        }
        
        odpConfig.update(apiKey: "invalid-key-no-retry", apiHost: "host")
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(2, apiManager.receivedBatchEvents.count, "should not be retried (only once for each of batch events)")
        XCTAssertEqual(10, apiManager.receivedBatchEvents[0].count)
        XCTAssertEqual(5, apiManager.receivedBatchEvents[1].count)
        XCTAssertEqual(0, manager.eventQueue.count, "all the events should be discarded")
    }

    // MARK: - OdpConfig
    
    func testOdpConfig() {
        odpConfig.update(apiKey: "test-key", apiHost: "test-host")

        manager = OdpEventManager(sdkKey: "any",
                                  odpConfig: odpConfig,
                                  apiManager: apiManager)

        let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        manager.dispatch(event)
        sleep(1)

        XCTAssertEqual("test-host", apiManager.receivedApiHost)
        XCTAssertEqual("test-key", apiManager.receivedApiKey)
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
        
        // overruled ("model") or other custom data
        if customData.isEmpty {
            XCTAssert((data["model"] as! String).count > 3)
            XCTAssertNil(data["key-1"])
            XCTAssertNil(data["key-2"])
        } else {
            XCTAssert((data["model"] as! String) == "overruled")
            XCTAssert((data["key-1"] as! String) == "value-1")
            XCTAssert((data["key-2"] as! Double) == 12.5)
        }
    }
    
    func validateEvents(_ lhs: [OdpEvent], _ rhs: [OdpEvent]) {
        XCTAssertEqual(lhs.count, rhs.count)
        for i in 0..<lhs.count {
            XCTAssert(OTUtils.compareDictionaries(lhs[i].dict, rhs[i].dict))
        }
    }
    
    // MARK: - MockZaiusApiManager

    class MockZaiusApiManager: ZaiusRestApiManager {
        var receivedApiKey: String!
        var receivedApiHost: String!
        var receivedBatchEvents = [[OdpEvent]]()

        override func sendOdpEvents(apiKey: String,
                                    apiHost: String,
                                    events: [OdpEvent],
                                    completionHandler: @escaping (OptimizelyError?) -> Void) {
            receivedApiKey = apiKey
            receivedApiHost = apiHost
            receivedBatchEvents.append(events)

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
