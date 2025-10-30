//
// Copyright 2021, 2023 Optimizely, Inc. and contributors
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

class OptimizelyClientTests_ODP: XCTestCase {

    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
    }
    
    override func tearDown() {
        Utils.sdkVersion = OPTIMIZELYSDKVERSION
        Utils.swiftSdkClientName = "swift-sdk"
    }
    
    // MARK: - ODP configuration
    
    func testSdkSettings_default()  {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        let cmabCache = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService).cmabCache
        XCTAssertEqual(100, cmabCache.maxSize)
        XCTAssertEqual(600, cmabCache.timeoutInSecs)
        XCTAssertEqual(100, optimizely.odpManager.segmentManager?.segmentsCache.maxSize)
        XCTAssertEqual(600, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
        XCTAssertEqual(10, optimizely.odpManager.segmentManager?.apiMgr.resourceTimeoutInSecs)
        XCTAssertEqual(10, optimizely.odpManager.eventManager?.apiMgr.resourceTimeoutInSecs)
        XCTAssertEqual(true, optimizely.odpManager.enabled)
    }
    
    func testSdkSettings_custom()  {
        var sdkSettings = OptimizelySdkSettings(segmentsCacheSize: 12,
                                                segmentsCacheTimeoutInSecs: 345,
                                                cmabCacheSize: 50,
                                                cmabCacheTitmeoutInSecs: 120)
        var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        let cmabCache = ((optimizely.decisionService as! DefaultDecisionService).cmabService as! DefaultCmabService).cmabCache
        XCTAssertEqual(50, cmabCache.maxSize)
        XCTAssertEqual(120, cmabCache.timeoutInSecs)
        XCTAssertEqual(12, optimizely.odpManager.segmentManager?.segmentsCache.maxSize)
        XCTAssertEqual(345, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
        
        sdkSettings = OptimizelySdkSettings(timeoutForSegmentFetchInSecs: 34,
                                            timeoutForOdpEventInSecs: 45)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        XCTAssertEqual(34, optimizely.odpManager.segmentManager?.apiMgr.resourceTimeoutInSecs)
        XCTAssertEqual(45, optimizely.odpManager.eventManager?.apiMgr.resourceTimeoutInSecs)

        sdkSettings = OptimizelySdkSettings(disableOdp: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        XCTAssertEqual(false, optimizely.odpManager.enabled)
    }
    
    // MARK: - sendOdpEvent
    
    func testSendOdpEvent_success() {
        let odpManager = MockOdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager
        
        try? optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k21": "v2", "k22": true, "k23": 3.5, "k24": nil])

        XCTAssertEqual("t1", odpManager.eventType)
        XCTAssertEqual("a1", odpManager.eventAction)
        XCTAssertEqual(["k1": "v1"], odpManager.eventIdentifiers)
        XCTAssertEqual("v2", odpManager.eventData!["k21"] as! String)
        XCTAssertEqual(true, odpManager.eventData!["k22"] as! Bool)
        XCTAssertEqual(3.5, odpManager.eventData!["k23"] as! Double)
        // swift handles <nil> in Any type in a weird way. It's a nil but cannot be AssertNil. Use stringify to validate nil.
        XCTAssertNil(odpManager.eventData!["k24"]!)

        // default event props
        
        try? optimizely.sendOdpEvent(action: "a2")
        
        XCTAssertEqual(nil, odpManager.eventType)
        XCTAssertEqual("a2", odpManager.eventAction)
        XCTAssertEqual([:], odpManager.eventIdentifiers)
        XCTAssertEqual([:], odpManager.eventData as! [String: String])
    }
    
    func testSendOdpEvent_customClientNameAndVersion() {
        let odpEventManager = MockOdpEventManager(sdkKey: "any")
        let odpManager = OdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123, eventManager: odpEventManager)
        
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        let tmpOptimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, odpManager: odpManager, settings: OptimizelySdkSettings(sdkName: "flutter-sdk", sdkVersion: "1234"))
        try! tmpOptimizely.start(datafile: datafile)
        
        try? tmpOptimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k21": "v2", "k22": true, "k23": 3.5, "k24": nil])

        XCTAssertEqual(odpEventManager.receivedData["data_source_version"] as! String, "1234")
        XCTAssertEqual(odpEventManager.receivedData["data_source"] as! String, "flutter-sdk")
    }
    
    func testSendOdpEvent_error() {
        var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)

        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
            XCTAssert(true, "event must be queued if datafile is not ready")
        } catch {
            XCTFail()
        }
        
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
            XCTFail()
        } catch OptimizelyError.odpNotIntegrated {
            XCTAssert(true, "OptimizelyError expected if ODP is not integrated.")
        } catch {
            XCTFail()
        }
        
        datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        try! optimizely.start(datafile: datafile)

        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
        let sdkSettings = OptimizelySdkSettings(disableOdp: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        try! optimizely.start(datafile: datafile)

        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
            XCTAssert(true)
        } catch OptimizelyError.odpNotEnabled {
            XCTAssert(true, "OptimizelyError expected if ODP is disabled.")
        } catch {
            XCTFail()
        }
    }
    
    func testSendOdpEvent_invalidDataTypes() {
        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k21": "valid", "k22": ["invalid"]])
            XCTFail()
        } catch OptimizelyError.odpInvalidData {
            XCTAssert(true)
        } catch {
            XCTFail("OptimizelyError expected if data has invalid types.")
        }
        
        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": ["embed": 12]])
            XCTFail()
        } catch OptimizelyError.odpInvalidData {
            XCTAssert(true)
        } catch {
            XCTFail("OptimizelyError expected if data has invalid types.")
        }
        
        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: [:],
                                        data: ["k1": "v1",
                                               "k2": true,
                                               "k3": 3.5,
                                               "k4": 10,
                                               "k5": nil
                                              ])
                                               
            XCTAssert(true)
        } catch {
            XCTFail("Should accept all valid data value types.")
        }
    }
    
    // MARK: - vuid
    
    func testVuidEnabled() {
        let settings = OptimizelySdkSettings(enableVuid: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: settings)
        XCTAssertNotNil(optimizely.vuid)
        XCTAssert(optimizely.vuid!.starts(with: "vuid_"))
    }
    
    func test_register_vuid_autometically_when_enabled() {
        let settings = OptimizelySdkSettings(enableVuid: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: settings)
        let eventManager = optimizely.odpManager.eventManager!
        let evt = eventManager.eventQueue.getFirstItem()!
        
        XCTAssertEqual("fullstack", evt.type)
        XCTAssertEqual("client_initialized", evt.action)
        XCTAssertEqual(["vuid": optimizely.vuid], evt.identifiers)
        XCTAssertNotNil(optimizely.vuid)
    }
    
    func test_vuid_does_not_register_autometically_when_enabled_but_odp_disabled() {
        let settings = OptimizelySdkSettings(disableOdp: true, enableVuid: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: settings)
        XCTAssertNotNil(optimizely.vuid)
        let eventManager = optimizely.odpManager.eventManager
        XCTAssertNil(eventManager)
    }
        
    // MARK: - OdpConfig Update
    
    func testUpdateOpdConfigCalled_wheneverProjectConfigUpdated_initialOrPolling() {
        let odpManager = MockOdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager
        
        XCTAssertNil(odpManager.apiKey)
        XCTAssertNil(odpManager.apiHost)
        XCTAssertEqual([], odpManager.segmentsToCheck)

        // ODP integrated in datafile
        
        var datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        updateProjectConfig(optimizely: optimizely, datafile: datafile)
        
        XCTAssertEqual("W4WzcEs-ABgXorzY7h1LCQ", odpManager.apiKey, "updateOdpConfig should be called when datafile parsed ok")
        XCTAssertEqual("https://api.zaius.com", odpManager.apiHost)
        XCTAssertEqual(["odp-segment-1", "odp-segment-2", "odp-segment-3"], odpManager.segmentsToCheck.sorted())
        
        // ODP not integrated in datafile
        
        datafile = OTUtils.loadJSONDatafile("decide_datafile")!
        updateProjectConfig(optimizely: optimizely, datafile: datafile)

        XCTAssertNil(odpManager.apiKey, "updateOdpConfig should be called when datafile parsed ok, but no odp integrated")
        XCTAssertNil(odpManager.apiHost)
        XCTAssertEqual([], odpManager.segmentsToCheck)
    }
    
    // MARK: - Utils
    
    func updateProjectConfig(optimizely: OptimizelyClient, datafile: Data) {
        optimizely.config = try! ProjectConfig(datafile: datafile)
    }

}

// MARK: - Mocks

extension OptimizelyClientTests_ODP {
    
    class MockOdpManager: OdpManager {
        var eventType: String?
        var eventAction: String?
        var eventIdentifiers: [String: String]?
        var eventData: [String: Any?]?
        
        var apiKey: String?
        var apiHost: String?
        var segmentsToCheck = [String]()

        override func sendEvent(type: String?, action: String, identifiers: [String : String], data: [String : Any?]) {
            self.eventType = type
            self.eventAction = action
            self.eventIdentifiers = identifiers
            self.eventData = data
        }
        
        override func updateOdpConfig(apiKey: String?, apiHost: String?, segmentsToCheck: [String]) {
            self.apiKey = apiKey
            self.apiHost = apiHost
            self.segmentsToCheck = segmentsToCheck
        }
    }
    
    class MockOdpEventManager: OdpEventManager {
        var receivedData: [String: Any?]!

        override func dispatch(_ event: OdpEvent) {
            self.receivedData = event.data
        }
    }
    
}
