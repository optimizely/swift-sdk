//
// Copyright 2021, Optimizely, Inc. and contributors
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
    
    // MARK: - ODP configuration
    
    func testConfigurableSettings_default()  {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)

        XCTAssertEqual(100, optimizely.odpManager.segmentManager?.segmentsCache.maxSize)
        XCTAssertEqual(600, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
        XCTAssertEqual(true, optimizely.odpManager.enabled)
    }
    
    func testConfigurableSettings_custom()  {
        var sdkSettings = OptimizelySdkSettings(segmentsCacheSize: 12, segmentsCacheTimeoutInSecs: 345)
        var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        XCTAssertEqual(12, optimizely.odpManager.segmentManager?.segmentsCache.maxSize)
        XCTAssertEqual(345, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
        
        sdkSettings = OptimizelySdkSettings(disableOdp: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        XCTAssertEqual(false, optimizely.odpManager.enabled)
    }
    
    // MARK: - sendOdpEvent
    
    func testSendOdpEvent_success() {
        let odpManager = MockOdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager

        try? optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
        
        XCTAssertEqual("t1", odpManager.eventType)
        XCTAssertEqual("a1", odpManager.eventAction)
        XCTAssertEqual(["k1": "v1"], odpManager.eventIdentifiers)
        XCTAssertEqual(["k2": "v2"], odpManager.eventData as! [String: String])
        
        // default event props
        
        try? optimizely.sendOdpEvent(action: "a2")
        
        XCTAssertEqual("fullstack", odpManager.eventType)
        XCTAssertEqual("a2", odpManager.eventAction)
        XCTAssertEqual([:], odpManager.eventIdentifiers)
        XCTAssertEqual([:], odpManager.eventData as! [String: String])
    }
    
    func testSendOdpEvent_error() {
        var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)

        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
            XCTFail()
        } catch OptimizelyError.sdkNotReady {
            XCTAssert(true)
        } catch {
            XCTFail()
        }
        
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        do {
            try optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
            XCTFail()
        } catch OptimizelyError.odpNotIntegrated {
            XCTAssert(true)
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
            XCTAssert(true)
        } catch {
            XCTFail()
        }
    }
    
    // MARK: - vuid
    
    func testVuid() {
        XCTAssert(optimizely.vuid.starts(with: "vuid_"))
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
        var eventData: [String: Any]?
        
        var apiKey: String?
        var apiHost: String?
        var segmentsToCheck = [String]()

        override func sendEvent(type: String, action: String, identifiers: [String : String], data: [String : Any]) {
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
    
}
