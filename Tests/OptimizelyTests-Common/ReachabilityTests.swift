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

class ReachabilityTests: XCTestCase {

    // Reachability (NWPathMonitor) can be tested with real devices only (no simulators), but framework logic testing is not supported on devices.
    // We mock reachability to test core functions on simulator
    
    func testShouldBlockNetworkAccess() throws {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            // disconnect monitoring 
            NetworkReachability.shared.stop()
            
            NetworkReachability.shared.isConnected = false
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 0))
            NetworkReachability.shared.isConnected = true
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 0))

            NetworkReachability.shared.isConnected = false
            XCTAssertTrue(Utils.shouldBlockNetworkAccess(numContiguousFails: 1))
            NetworkReachability.shared.isConnected = true
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 1))

            NetworkReachability.shared.isConnected = false
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 8, maxContiguousFails: 10))
            NetworkReachability.shared.isConnected = true
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 8, maxContiguousFails: 10))

            NetworkReachability.shared.isConnected = false
            XCTAssertTrue(Utils.shouldBlockNetworkAccess(numContiguousFails: 12, maxContiguousFails: 10))
            NetworkReachability.shared.isConnected = true
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 12, maxContiguousFails: 10))
            
        } else {
            
            // NWPathMonitor not supported. Do not use reachability.
            
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 0))
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 1))
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 8, maxContiguousFails: 10))
            XCTAssertFalse(Utils.shouldBlockNetworkAccess(numContiguousFails: 12, maxContiguousFails: 10))
            
        }
    }
    
    func testReachabilityMonitoring() throws {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            let exp = expectation(description: "x")
            DispatchQueue.global().async {
                while true {
                    if NetworkReachability.shared.isConnected {
                        exp.fulfill()
                        break
                    }
                    sleep(1)
                }
            }
            
            wait(for: [exp], timeout: 10)
            XCTAssertTrue(NetworkReachability.shared.isConnected)
            
        }
    }
    
    func testReachabilityForFetchDatafile_numContiguousFails() {
        let sdkKey = "localcdnTestSDKKey"
        let handler = MockDatafileHandler(withError: true)
        
        var exp = expectation(description: "r")
        handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(handler.numContiguousFails, 1, "should be incremented on failure")
        
        exp = expectation(description: "r")
        handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(handler.numContiguousFails, 2, "should be incremented on failure")
       
        handler.withError = false  // following requests should success (no error)

        exp = expectation(description: "r")
        handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(handler.numContiguousFails, 0, "should be reset on success")
    }

    func testReachabilityForEventDispatch_numContiguousFails() {
        let handler = MockDefaultEventDispatcher(withError: true)
        let event = EventForDispatch(body: Data())
        
        var exp = expectation(description: "r")
        handler.sendEvent(event: event) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(handler.numContiguousFails, 1, "should be incremented on failure")

        exp = expectation(description: "r")
        handler.sendEvent(event: event) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(handler.numContiguousFails, 2, "should be incremented on failure")
        
        handler.withError = false  // following requests should success (no error)
        
        exp = expectation(description: "r")
        handler.sendEvent(event: event) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(handler.numContiguousFails, 0, "should be reset on success")
    }

    func testReachabilityForFetchDatafile_checkReachability() {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            NetworkReachability.shared.stop()
            NetworkReachability.shared.isConnected = false
            Utils.defaultMaxContiguousFails = 1
            
            let sdkKey = "localcdnTestSDKKey"
            let handler = MockDatafileHandler(withError: true)
            
            var expNumFails = 0
            for _ in 0..<10 {
                if expNumFails < Utils.defaultMaxContiguousFails { expNumFails += 1 }
                
                let exp = expectation(description: "r")
                handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
                wait(for: [exp], timeout: 3)
                
                // reachability check will kick in when maxContiguousFails is reached.
                // numContiguousFails should not increase beyond maxContiguousFails (since connection request will be discarded).

                XCTAssertEqual(handler.numContiguousFails, expNumFails)
            }

        }
    }

    func testReachabilityForEventDispatch_checkReachability() {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            NetworkReachability.shared.stop()
            NetworkReachability.shared.isConnected = false
            Utils.defaultMaxContiguousFails = 3
            
            let handler = MockDefaultEventDispatcher(withError: true)
            let event = EventForDispatch(body: Data())

            var expNumFails = 0
            for _ in 0..<10 {
                if expNumFails < Utils.defaultMaxContiguousFails { expNumFails += 1 }
                
                let exp = expectation(description: "r")
                handler.sendEvent(event: event) { _ in exp.fulfill() }
                wait(for: [exp], timeout: 3)
                
                // reachability check will kick in when maxContiguousFails is reached.
                // numContiguousFails should not increase beyond maxContiguousFails (since connection request will be discarded).
                
                XCTAssertEqual(handler.numContiguousFails, expNumFails)
            }

        }
    }

}
