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

class OptimizelyUserContextTests_ODP_2: XCTestCase {
        
    let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!

    func testOdpEvents_earlyEventsDispatched() {
        // use a different sdkKey to avoid events conflict
        let sdkKey = OTUtils.randomSdkKey
        
        // odp disabled to avoid initial noise
        
        let optimizely = OptimizelyClient(sdkKey: sdkKey,
                                          settings: OptimizelySdkSettings(disableOdp: true))
        
        // override with a custom enabled odpManager.
        // - client_inializatied event will be sent automatically
        // - will wait in the queue until project config is ready
        
        let odpEventApiManager = MockOdpEventApiManager()
        optimizely.odpManager = OdpManager(sdkKey: sdkKey,
                                    disable: false,
                                    cacheSize: 10,
                                    cacheTimeoutInSecs: 10,
                                    eventManager: OdpEventManager(sdkKey: sdkKey,
                                                                  apiManager: odpEventApiManager))
        
        // identified event will sent but wait in the queue until project config is ready
        _ = optimizely.createUserContext(userId: "tester")

        sleep(1)
        XCTAssertEqual(odpEventApiManager.dispatchedEvents.count, 0, "wait until project config is ready")

        // project config gets ready
        try! optimizely.start(datafile: datafile)
        
        // identified event will sent
        _ = optimizely.createUserContext(userId: "tester")
        
        sleep(1)
        XCTAssertEqual(odpEventApiManager.dispatchedEvents.count, 3, "client_initialized and 2 x identified events")
        
        for i in 0..<100 {
            _ = optimizely.createUserContext(userId: "tester-\(i % 10)")
        }
        
        sleep(1)
        XCTAssertEqual(odpEventApiManager.dispatchedEvents.count, 103, "100 more identified events")
    }
    
    // MARK: - Utils
    
    class MockOdpEventApiManager: OdpEventApiManager {
        var dispatchedEvents = [OdpEvent]()
        
        override func sendOdpEvents(apiKey: String,
                                    apiHost: String,
                                    events: [OdpEvent],
                                    completionHandler: @escaping (OptimizelyError?) -> Void) {
            self.dispatchedEvents.append(contentsOf: events)
            completionHandler(nil)
        }
    }

}
