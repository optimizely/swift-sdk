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
    // We mock reachability to test core functions on simulators.
    
    func testShouldBlockNetworkAccess() throws {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            var reachability = NetworkReachability()
            reachability.stop()  // disconnect monitoring
            
            // never blocked if previous connections did not fail
            
            reachability.numContiguousFails = 0
            XCTAssertEqual(reachability.maxContiguousFails, 1)

            reachability.isConnected = false
            XCTAssertFalse(reachability.shouldBlockNetworkAccess())
            reachability.isConnected = true
            XCTAssertFalse(reachability.shouldBlockNetworkAccess())

            // block depending on reachability if previous connections failed
            
            reachability.numContiguousFails = 1

            reachability.isConnected = false
            XCTAssertTrue(reachability.shouldBlockNetworkAccess())
            reachability.isConnected = true
            XCTAssertFalse(reachability.shouldBlockNetworkAccess())

            // never blocked if previous contiguous connection failures less than max threshold

            reachability = NetworkReachability(maxContiguousFails: 10)
            reachability.stop()  // disconnect monitoring

            reachability.numContiguousFails = 8
            XCTAssertEqual(reachability.maxContiguousFails, 10)

            reachability.isConnected = false
            XCTAssertFalse(reachability.shouldBlockNetworkAccess())
            reachability.isConnected = true
            XCTAssertFalse(reachability.shouldBlockNetworkAccess())

            // block depending on reachability if previous contiguous connection failures more than max threshold

            reachability.numContiguousFails = 12
            XCTAssertEqual(reachability.maxContiguousFails, 10)

            reachability.isConnected = false
            XCTAssertTrue(reachability.shouldBlockNetworkAccess())
            reachability.isConnected = true
            XCTAssertFalse(reachability.shouldBlockNetworkAccess())
            
        } else {
            
            // NWPathMonitor not supported. Should not block regardless of failure counts.
            
            let reachability = NetworkReachability(maxContiguousFails: 3)

            for _ in 0..<10 {
                XCTAssertFalse(reachability.shouldBlockNetworkAccess())
                reachability.updateNumContiguousFails(isError: true)
            }
            
        }
    }
    
    func testReachabilityMonitoring() throws {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            let reachability = NetworkReachability()
            
            // isConnected is initially false (simulators only), and will be updated to true on updateHandler.
            
            let exp = expectation(description: "x")
            DispatchQueue.global().async {
                while true {
                    if reachability.isConnected {
                        exp.fulfill()
                        break
                    }
                    sleep(1)
                }
            }
            
            wait(for: [exp], timeout: 3)
            XCTAssertTrue(reachability.isConnected)
            
        }
    }
    
    func testFetchDatafile_numContiguousFails() {
        let handler = MockDatafileHandler(withError: true)
        let reachability = handler.reachability
        let sdkKey = "localcdnTestSDKKey"

        var exp = expectation(description: "r")
        handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(reachability.numContiguousFails, 1, "should be incremented on failure")
        
        exp = expectation(description: "r")
        handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(reachability.numContiguousFails, 2, "should be incremented on failure")
       
        handler.withError = false  // following requests should succeed (no error)

        exp = expectation(description: "r")
        handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(reachability.numContiguousFails, 0, "should be reset on success")
    }

    func testEventDispatch_numContiguousFails() {
        let handler = MockDefaultEventDispatcher(withError: true)
        let reachability = handler.reachability
        let event = EventForDispatch(body: Data())
        
        var exp = expectation(description: "r")
        handler.sendEvent(event: event) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(reachability.numContiguousFails, 1, "should be incremented on failure")

        exp = expectation(description: "r")
        handler.sendEvent(event: event) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(reachability.numContiguousFails, 2, "should be incremented on failure")
        
        handler.withError = false  // following requests should succeed (no error)
        
        exp = expectation(description: "r")
        handler.sendEvent(event: event) { _ in exp.fulfill() }
        wait(for: [exp], timeout: 3)
        XCTAssertEqual(reachability.numContiguousFails, 0, "should be reset on success")
    }

    func testFetchDatafile_checkReachability() {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            let handler = MockDatafileHandler(withError: true)
            let reachability = handler.reachability
            let sdkKey = "localcdnTestSDKKey"

            reachability.stop()
            reachability.isConnected = false
            reachability.maxContiguousFails = 3
            
            var expNumFails = 0
            for _ in 0..<10 {
                if expNumFails < reachability.maxContiguousFails { expNumFails += 1 }
                
                let exp = expectation(description: "r")
                handler.downloadDatafile(sdkKey: sdkKey) { _ in exp.fulfill() }
                wait(for: [exp], timeout: 3)
                
                // reachability check will kick in when maxContiguousFails is reached.
                // numContiguousFails should not increase beyond maxContiguousFails (since connection request will be discarded).

                //print("numContiguousFails: \(handler.numContiguousFails)")
                XCTAssertEqual(reachability.numContiguousFails, expNumFails)
            }

        }
    }

    func testEventDispatch_checkReachability() {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            let handler = MockDefaultEventDispatcher(withError: true)
            let reachability = handler.reachability
            let event = EventForDispatch(body: Data())

            reachability.stop()
            reachability.isConnected = false
            reachability.maxContiguousFails = 3

            var expNumFails = 0
            for _ in 0..<10 {
                if expNumFails < reachability.maxContiguousFails { expNumFails += 1 }

                let exp = expectation(description: "r")
                handler.sendEvent(event: event) { _ in exp.fulfill() }
                wait(for: [exp], timeout: 3)
                
                // reachability check will kick in when maxContiguousFails is reached.
                // numContiguousFails should not increase beyond maxContiguousFails (since connection request will be discarded).
                
                //print("numContiguousFails: \(handler.numContiguousFails)")
                XCTAssertEqual(reachability.numContiguousFails, expNumFails)
            }

        }
    }

}
