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
    
    // MARK: - public APIs
    
    func testConfigurableSettings_default()  {
        let optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)

        XCTAssertEqual(100, optimizely.odpManager.segmentManager?.segmentsCache.size)
        XCTAssertEqual(600, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
        XCTAssertEqual(true, optimizely.odpManager.enabled)
    }
    
    func testConfigurableSettings_custom()  {
        var sdkSettings = OptimizelySdkSettings(segmentsCacheSize: 12, segmentsCacheTimeoutInSecs: 345)
        var optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        XCTAssertEqual(12, optimizely.odpManager.segmentManager?.segmentsCache.size)
        XCTAssertEqual(345, optimizely.odpManager.segmentManager?.segmentsCache.timeoutInSecs)
        
        sdkSettings = OptimizelySdkSettings(disableOdp: true)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, settings: sdkSettings)
        XCTAssertEqual(false, optimizely.odpManager.enabled)
    }
    
    func testSendOdpEvent() {
        let odpManager = MockOdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager

        optimizely.sendOdpEvent(type: "t1", action: "a1", identifiers: ["k1": "v1"], data: ["k2": "v2"])
        
        XCTAssertEqual("t1", odpManager.eventType)
        XCTAssertEqual("a1", odpManager.eventAction)
        XCTAssertEqual(["k1": "v1"], odpManager.eventIdentifiers)
        XCTAssertEqual(["k2": "v2"], odpManager.eventData as! [String: String])
        
        // default event props
        
        optimizely.sendOdpEvent(action: "a2")
        
        XCTAssertEqual("fullstack", odpManager.eventType)
        XCTAssertEqual("a2", odpManager.eventAction)
        XCTAssertEqual([:], odpManager.eventIdentifiers)
        XCTAssertEqual([:], odpManager.eventData as! [String: String])
    }
    
    func testVuid() {
        XCTAssert(optimizely.vuid.starts(with: "vuid_"))
    }
    
    // MARK: - OdpConfig Update
    
    func testUpdateOpdConfigCalled_synchronous_success() {
        let odpManager = MockOdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager
        
        XCTAssertNil(odpManager.apiKey)
        XCTAssertNil(odpManager.apiHost)
        
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        try? optimizely.start(datafile: datafile)
        
        XCTAssertEqual("W4WzcEs-ABgXorzY7h1LCQ", odpManager.apiKey, "updateOdpConfig should be called when datafile parsed ok")
        XCTAssertEqual("https://api.zaius.com", odpManager.apiHost)
    }
    
    func testUpdateOpdConfigCalled_synchronous_failure() {
        let odpManager = MockOdpManager(sdkKey: "any", disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager
        
        XCTAssertNil(odpManager.apiKey)
        XCTAssertNil(odpManager.apiHost)
        
        let datafile = OTUtils.loadJSONDatafile("unsupported_datafile")!
        try? optimizely.start(datafile: datafile)
        
        XCTAssertNil(odpManager.apiKey, "updateOdpConfig should not be called when datafile parse failed")
        XCTAssertNil(odpManager.apiHost)
    }
    
    func testUpdateOpdConfigCalled_asynchronous_success() {
        let sdkKey = "valid"
        let optimizely = OptimizelyClient(sdkKey: sdkKey, datafileHandler: MockDatafileHandler())
        let odpManager = MockOdpManager(sdkKey: sdkKey, disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager
        
        XCTAssertNil(odpManager.apiKey)
        XCTAssertNil(odpManager.apiHost)
        
        let sem = DispatchSemaphore(value: 0)
        optimizely.start { result in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))

        XCTAssertEqual("W4WzcEs-ABgXorzY7h1LCQ", odpManager.apiKey, "updateOdpConfig should be called when datafile fetched")
        XCTAssertEqual("https://api.zaius.com", odpManager.apiHost)
    }
    
    func testUpdateOpdConfigCalled_asynchronous_failure() {
        let sdkKey = "invalid"
        let optimizely = OptimizelyClient(sdkKey: sdkKey, datafileHandler: MockDatafileHandler())
        let odpManager = MockOdpManager(sdkKey: sdkKey, disable: false, cacheSize: 12, cacheTimeoutInSecs: 123)
        optimizely.odpManager = odpManager
        
        XCTAssertNil(odpManager.apiKey)
        XCTAssertNil(odpManager.apiHost)
        
        let sem = DispatchSemaphore(value: 0)
        optimizely.start { result in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))

        XCTAssertNil(odpManager.apiKey, "updateOdpConfig should not be called on datafile fetch failed")
        XCTAssertNil(odpManager.apiHost)
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

        override func sendEvent(type: String, action: String, identifiers: [String : String], data: [String : Any]) {
            self.eventType = type
            self.eventAction = action
            self.eventIdentifiers = identifiers
            self.eventData = data
        }
        
        override func updateOdpConfig(apiKey: String?, apiHost: String?) {
            self.apiKey = apiKey
            self.apiHost = apiHost
        }
    }
    
    class MockDatafileHandler: DefaultDatafileHandler {
        
        override func downloadDatafile(sdkKey: String,
                                       returnCacheIfNoChange: Bool,
                                       resourceTimeoutInterval: Double?,
                                       completionHandler: @escaping DatafileDownloadCompletionHandler) {
            if sdkKey == "valid" {
                let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
                completionHandler(.success(datafile))
            } else {
                completionHandler(.failure(.generic))
            }
        }
        
    }
    
}
