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

class OdpEventManagerTests: XCTestCase {
    var manager: OdpEventManager!
    var odpConfig: OdpConfig!
    var apiManager = MockOdpEventApiManager()

    var options = [OptimizelySegmentOption]()
    
    var userKey = "vuid"
    var userValue = "test-user"
    let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
    let customData: [String: Any] = ["key-1": "value-1",
                                     "key-2": 12.5,
                                     "model": "overruled"]
    var originalMaxQueueSize = 0

    override func setUp() {
        OTUtils.clearAllEventQueues()
        OTUtils.createDocumentDirectoryIfNotAvailable()

        // no valid apiKey, so flush will return immediately
        odpConfig = OdpConfig()
        
        manager = OdpEventManager(sdkKey: "any",
                                  apiManager: apiManager)
        manager.odpConfig = odpConfig
        originalMaxQueueSize = manager.maxQueueSize
    }
    
    override func tearDown() {
        OTUtils.clearAllEventQueues()
        manager.maxQueueSize = originalMaxQueueSize
    }
    
    // MARK: - save and restore events
    
    func testSaveAndRestoreEvents() {
        manager.sendEvent(type: "t1",
                          action: "a1",
                          identifiers: ["id-key-1": "id-value-1"],
                          data: ["key1": "value1", "key2": 3.5, "key3": true, "key4": nil])
        
        let evt = manager.eventQueue.getFirstItems(count: 1)!.first!
        XCTAssertEqual("t1", evt.type)
        XCTAssertEqual("a1", evt.action)
        XCTAssertEqual(["id-key-1": "id-value-1"], evt.identifiers)
        XCTAssertEqual("value1", evt.data["key1"] as! String)
        XCTAssertEqual(3.5, evt.data["key2"] as! Double)
        XCTAssertEqual(true, evt.data["key3"] as! Bool)
        // <nil> data value is converted to NSNull (<null>) after saving into and retrieving from the event queue.
        XCTAssert(evt.data["key4"] is NSNull)
    }
    
    // MARK: - sendEvent

    func testSendEvent_noApiKey() {
        manager.sendEvent(type: "t1",
                          action: "a1",
                          identifiers: ["id-key-1": "id-value-1"],
                          data: customData)

        XCTAssertEqual(1, manager.eventQueue.count)
        sleep(1)
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
        print("[ODP event default data] ", evt.data)
        
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
    
    func testIdentifyUser_noApiKey_nilUserId() {
        manager.identifyUser(vuid: "v1", userId: nil)
        
        XCTAssertEqual(1, manager.eventQueue.count)
        let evt = manager.eventQueue.getFirstItem()!
        XCTAssertEqual("fullstack", evt.type)
        XCTAssertEqual("identified", evt.action)
        XCTAssertEqual(["vuid": "v1"], evt.identifiers)
        validateData(evt.data, customData: [:])
    }
    
    func testSendEvent_apiKey() {
        odpConfig = OdpConfig()
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        
        manager = OdpEventManager(sdkKey: "any",
                                  apiManager: apiManager)
        manager.odpConfig = odpConfig
        
        manager.sendEvent(type: "t1",
                          action: "a1",
                          identifiers: ["id-key-1": "id-value-1"],
                          data: customData)
        
        XCTAssertEqual(1, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count, "flushed since apiKey is ready")
    }
    
    // MARK: - flush

    func testFlush_odpIntegrated() {
        // apiKey is not ready initially
        
        XCTAssertTrue(manager.odpConfig.eventQueueingAllowed, "initially datafile not ready and assumed queueing is allowed")

        manager.registerVUID(vuid: "v1")    // each of these will try to flush
        manager.identifyUser(vuid: "v1", userId: "u1")
        manager.sendEvent(type: "t1", action: "a1", identifiers: [:], data: [:])

        XCTAssertEqual(3, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(3, manager.eventQueue.count, "not flushed since apiKey is not ready")

        // apiKey is available in datafile (so ODP integrated)

        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        XCTAssertTrue(manager.odpConfig.eventQueueingAllowed, "datafile ready and odp integrated. event queueing is allowed.")
        manager.flush()   // need manual flush here since OdpManager is not connected
        
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count)
        XCTAssertEqual(3, apiManager.totalDispatchedEvents)
        apiManager.dispatchedBatchEvents.removeAll()

        // new events should be dispatched immediately
        
        manager.dispatch(event)    // each of these will try to flush
        manager.dispatch(event)    // each of these will try to flush

        XCTAssertEqual(2, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count, "auto flushed since apiKey is ready")
        XCTAssertEqual(2, apiManager.totalDispatchedEvents)
    }
    
    func testFlush_odpNotIntegrated() {
        // apiKey is not ready
        
        XCTAssertTrue(manager.odpConfig.eventQueueingAllowed, "initially datafile not ready and assumed queueing is allowed")

        manager.registerVUID(vuid: "v1")    // each of these will try to flush
        manager.identifyUser(vuid: "v1", userId: "u1")
        manager.sendEvent(type: "t1", action: "a1", identifiers: [:], data: [:])

        XCTAssertEqual(3, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(3, manager.eventQueue.count, "not flushed since apiKey is not ready")
        
        // apiKey is not available in datafile (so ODP not integrated)
        
        _ = odpConfig.update(apiKey: nil, apiHost: nil, segmentsToCheck: [])
        XCTAssertFalse(manager.odpConfig.eventQueueingAllowed, "datafile ready and odp not integrated. event queueing is not allowed.")
        
        manager.flush()   // need manual flush here since OdpManager is not connected
        XCTAssertEqual(0, manager.eventQueue.count, "all old events are discarded since event queueing not allowed")
        XCTAssertEqual(0, apiManager.totalDispatchedEvents, "all events discarded")

        manager.dispatch(event)    // each of these will try to flush
        manager.dispatch(event)    // each of these will try to flush

        XCTAssertEqual(0, manager.eventQueue.count)
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count, "all news events are discarded since event queueing not allowed")
        XCTAssertEqual(0, apiManager.totalDispatchedEvents, "all events discarded")
    }
    
    // MARK: - queue overflow
    
    func testFlush_maxSize() {
        manager.maxQueueSize = 2
        
        manager.registerVUID(vuid: "v1")    // each of these will try to flush
        manager.identifyUser(vuid: "v1", userId: "u1")
        manager.sendEvent(type: "t1", action: "a1", identifiers: [:], data: [:])

        sleep(1)
        XCTAssertEqual(2, manager.eventQueue.count, "an event discarded since queue overflowed")
                
        // apiKey is available in datafile (so ODP integrated)

        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        
        manager.dispatch(event)    // each of these will try to flush
        
        sleep(1)
        XCTAssertEqual(0, manager.eventQueue.count, "flush is called even when an event is discarded because queue is overflowed")
        XCTAssertEqual(2, apiManager.totalDispatchedEvents)
    }
    
    // MARK: - batch

    func testFlush_batch_1() {
        let events = [event]
        manager.dispatch(events[0])
        
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents[0].count)
        validateEvents(events, apiManager.dispatchedBatchEvents[0])
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

        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(3, apiManager.dispatchedBatchEvents[0].count)
        validateEvents(events, apiManager.dispatchedBatchEvents[0])
    }

    func testFlush_batch_moreThanBatchSize() {
        let events = [OdpEvent](repeating: event, count: 11)
        
        for e in events {
            manager.dispatch(e)
        }
        
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(2, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(10, apiManager.dispatchedBatchEvents[0].count)
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents[1].count)
        validateEvents(events, apiManager.dispatchedBatchEvents[0] + apiManager.dispatchedBatchEvents[1])
    }

    func testFlush_emptyQueue() {
        _ = odpConfig.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(0, apiManager.dispatchedBatchEvents.count)
    }
    
    // MARK: - multiple skdKeys
    
    func testMultipleSdkKeys_doNotInterfere() {
        let apiManager1 = MockOdpEventApiManager()
        let apiManager2 = MockOdpEventApiManager()
        let odpConfig1 = OdpConfig()
        let odpConfig2 = OdpConfig()

        let manager1 = OdpEventManager(sdkKey: "sdkKey-1",
                                       apiManager: apiManager1)
        manager1.odpConfig = odpConfig1
        
        let manager2 = OdpEventManager(sdkKey: "sdkKey-2",
                                       apiManager: apiManager2)
        manager2.odpConfig = odpConfig2
        
        let event1 = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        let event2 = OdpEvent(type: "t2", action: "a2", identifiers: [:], data: [:])

        manager1.dispatch(event1)
        manager1.dispatch(event1)
        
        manager2.dispatch(event2)
        
        XCTAssertEqual(0, apiManager1.dispatchedBatchEvents.count)
        XCTAssertEqual(0, apiManager2.dispatchedBatchEvents.count)

        _ = odpConfig1.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        manager1.flush()
        sleep(1)

        XCTAssertEqual(1, apiManager1.dispatchedBatchEvents.count)
        XCTAssertEqual(2, apiManager1.dispatchedBatchEvents[0].count)
        XCTAssertEqual(0, apiManager2.dispatchedBatchEvents.count)

        _ = odpConfig2.update(apiKey: "valid", apiHost: "host", segmentsToCheck: [])
        manager2.flush()
        sleep(1)

        XCTAssertEqual(1, apiManager1.dispatchedBatchEvents.count)
        XCTAssertEqual(2, apiManager1.dispatchedBatchEvents[0].count)
        XCTAssertEqual(1, apiManager2.dispatchedBatchEvents.count)
        XCTAssertEqual(1, apiManager2.dispatchedBatchEvents[0].count)
    }

    // MARK: - errors

    func testFlushError_noRetryOnClientError() {
        manager.dispatch(event)
        
        _ = odpConfig.update(apiKey: "invalid-key-no-retry", apiHost: "host", segmentsToCheck: [])
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents.count, "should not be retried for 4xx error")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be discarded")
    }
    
    func testFlushError_retryWhenFailedOnceOnServerError() {
        _ = odpConfig.update(apiKey: "valid-key-retry-error", apiHost: "host", segmentsToCheck: [])
        
        let failCnt = 1
        apiManager.maxCountWithErrorResponse = failCnt
        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(failCnt + 1, apiManager.dispatchedBatchEvents.count, "should be retried max for 5xx error")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be removed after success")
    }
    
    func testFlushError_retryWhenFailedTwiceOnServerError() {
        _ = odpConfig.update(apiKey: "valid-key-retry-error", apiHost: "host", segmentsToCheck: [])
        
        let failCnt = 2
        apiManager.maxCountWithErrorResponse = failCnt
        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(failCnt + 1, apiManager.dispatchedBatchEvents.count, "should be retried for 5xx error")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be removed after success")
    }

    func testFlushError_retryWhenFailedMoreThan3TimesAndGiveupOnServerError() {
        _ = odpConfig.update(apiKey: "valid-key-retry-error", apiHost: "host", segmentsToCheck: [])
        
        let failCnt = 10
        apiManager.maxCountWithErrorResponse = failCnt
        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(3, apiManager.dispatchedBatchEvents.count, "should be retried max 3 times for 5xx error")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be discarded after 3 retries")
    }

    // MARK: - reachability

    func testFlushError_reachability_connectedAndNoPreviousError() {
        _ = odpConfig.update(apiKey: "valid-key", apiHost: "host", segmentsToCheck: [])
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(0, manager.eventQueue.count)

        // connected. should not block.

        manager.reachability.isConnected = true
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)

        XCTAssertEqual(2, apiManager.dispatchedBatchEvents.count, "should not block event dispatch")
        XCTAssertEqual(0, manager.eventQueue.count)
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())
    }
    
    func testFlushError_reachability_connectedAndPreviousError() {
        _ = odpConfig.update(apiKey: "valid-key-retry-error", apiHost: "host", segmentsToCheck: [])
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(3, apiManager.dispatchedBatchEvents.count, "should be retried max 3 times for 5xx error")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be discarded after max retries")

        // connected. should not block even if there is a previous error.

        manager.reachability.isConnected = true
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)

        XCTAssertEqual(6, apiManager.dispatchedBatchEvents.count, "should dispatch if connected even if previous event discarded")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be discarded after max retries")
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())
    }

    func testFlushError_reachability_disconnectedAndNoPreviousError() {
        _ = odpConfig.update(apiKey: "valid-key", apiHost: "host", segmentsToCheck: [])
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(1, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(0, manager.eventQueue.count)

        // disconnected. should not block because there is no previous error.
        
        manager.reachability.isConnected = false
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)

        XCTAssertEqual(2, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(0, manager.eventQueue.count)
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())
    }
    
    func testFlushError_reachability_disconnectedAndPreviousError() {
        _ = odpConfig.update(apiKey: "valid-key-retry-error", apiHost: "host", segmentsToCheck: [])
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)
        
        XCTAssertEqual(3, apiManager.dispatchedBatchEvents.count, "should be retried max 3 times for 5xx error")
        XCTAssertEqual(0, manager.eventQueue.count, "the events should be discarded after max retries")

        // disconnected. should block because there is a previous error and disconnected.
        
        manager.reachability.isConnected = false
        XCTAssertTrue(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)

        XCTAssertEqual(3, apiManager.dispatchedBatchEvents.count, "should not dispatch any more when not connected and previous event discarded")
        XCTAssertEqual(1, manager.eventQueue.count, "the events should stay in the queue")
        
        // connected again. should not block any more even if there is a previous error.
        
        manager.reachability.isConnected = true
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        _ = odpConfig.update(apiKey: "valid-key", apiHost: "host", segmentsToCheck: [])

        manager.dispatch(event)
        manager.flush()
        sleep(1)

        XCTAssertEqual(4, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(0, manager.eventQueue.count)
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        // disconnected. should not block any more since previous error was cleared.
        
        manager.reachability.isConnected = false
        XCTAssertFalse(manager.reachability.shouldBlockNetworkAccess())

        manager.dispatch(event)
        manager.flush()
        sleep(1)

        XCTAssertEqual(5, apiManager.dispatchedBatchEvents.count)
        XCTAssertEqual(0, manager.eventQueue.count)
    }
    
    // MARK: - reset

    func testReset() {
        let events = [OdpEvent](repeating: event, count: 3)

        manager.reset()
        XCTAssertEqual(0, manager.eventQueue.count)

        for e in events {
            manager.dispatch(e)
        }
        
        XCTAssertEqual(3, manager.eventQueue.count)

        manager.reset()
        XCTAssertEqual(0, manager.eventQueue.count)
    }

    // MARK: - OdpConfig
    
    func testOdpConfig() {
        _ = odpConfig.update(apiKey: "test-key", apiHost: "test-host", segmentsToCheck: [])

        manager = OdpEventManager(sdkKey: "any",
                                  apiManager: apiManager)
        manager.odpConfig = odpConfig

        let event = OdpEvent(type: "t1", action: "a1", identifiers: [:], data: [:])
        manager.dispatch(event)
        sleep(1)

        XCTAssertEqual("test-host", apiManager.receivedApiHost)
        XCTAssertEqual("test-key", apiManager.receivedApiKey)
    }
    
    // MARK: - Utils
    
    func validateData(_ data: [String: Any?], customData: [String: Any?]) {
        XCTAssert((data["idempotence_id"] as! String).count > 3)
        XCTAssert((data["data_source_type"] as! String) == "sdk")
        XCTAssert((data["data_source"] as! String) == "swift-sdk")
        XCTAssert(Utils.isValidVersion(data["data_source_version"] as! String))
        XCTAssert(Utils.isValidVersion(data["os_version"] as! String))
        
        // os-dependent
        
        let dataOS = data["os"] as! String
        let dataDeviceType = data["device_type"] as! String
        
        #if os(iOS)
        XCTAssertEqual(dataOS, "iOS")
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCTAssertEqual(dataDeviceType, "Phone")
        } else {
            XCTAssertEqual(dataDeviceType, "Tablet")
        }
        #elseif os(tvOS)
        XCTAssertEqual(dataOS, "tvOS")
        XCTAssertEqual(dataDeviceType, "Smart TV")
        #elseif os(watchOS)
        XCTAssertEqual(dataOS, "watchOS")
        XCTAssertEqual(dataDeviceType, "Watch")
        #elseif os(macOS)
        XCTAssertEqual(dataOS, "macOS")
        XCTAssertEqual(dataDeviceType, "PC")
        #else
        XCTAssertEqual(dataOS, "Other")
        XCTAssertEqual(dataDeviceType, "Other")
        #endif
        
        // overruled ("model") or other custom data
        
        if customData.isEmpty {
            XCTAssert((data["model"] as! String).count > 3)
            XCTAssertNil(data["key-1"] as? String)
            XCTAssertNil(data["key-2"] as? String)
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
    
    // MARK: - MockOdpEventApiManager

    class MockOdpEventApiManager: OdpEventApiManager {
        var receivedApiKey: String!
        var receivedApiHost: String!
        var dispatchedBatchEvents = [[OdpEvent]]()
        
        var countWithErrorResponse = 0
        var maxCountWithErrorResponse = Int.max
        
        var totalDispatchedEvents: Int {
            return dispatchedBatchEvents.reduce(0) { $0 + $1.count }
        }

        override func sendOdpEvents(apiKey: String,
                                    apiHost: String,
                                    events: [OdpEvent],
                                    completionHandler: @escaping (OptimizelyError?) -> Void) {
            receivedApiKey = apiKey
            receivedApiHost = apiHost
            dispatchedBatchEvents.append(events)

            DispatchQueue.global().async {
                if apiKey == "invalid-key-no-retry" || apiKey == "valid-key-retry-error" {
                    if self.countWithErrorResponse < self.maxCountWithErrorResponse {
                        self.countWithErrorResponse += 1
                        if apiKey == "invalid-key-no-retry" {
                            completionHandler(OptimizelyError.odpEventFailed("403", false))
                        } else {
                            completionHandler(OptimizelyError.odpEventFailed("network error", true))
                        }
                        return
                    }
                }
                
                self.countWithErrorResponse = 0
                completionHandler(nil)
            }
        }
    }
    
}
