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

class EventDispatcherTests_MultiClients: XCTestCase {
    let stressFactor = 1    // increase this (10?) to give more stress testing with longer running time

    override func setUpWithError() throws {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
        OTUtils.clearAllEventQueues()
    }

    override func tearDownWithError() throws {
        OTUtils.clearAllEventQueues()
    }

    func testConcurrentDispatchEvents() {
        let numThreads = 100
        let numEventsPerThread = 10 * stressFactor
        let numEvents = numThreads * numEventsPerThread

        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        dispatcher.batchSize = 999999999       // avoid early-fire by batch-filled

        // keep the test running until all events flushed and timer stopped

        let exp = expectation(description: "delay")
        DispatchQueue.global().async {
            while dispatcher.totalEventsSent < numEvents || dispatcher.timer.property != nil {
                sleep(1)
            }
            exp.fulfill()
        }
        
        (0..<numThreads).forEach{ idx in
            DispatchQueue(label:"\(idx)").async {
                (0..<numEventsPerThread).forEach{ e in
                    usleep(UInt32.random(in: 0..<1000000))
                    dispatcher.dispatchEvent(event: OTUtils.makeEventForDispatch(), completionHandler: nil)
                }
                NotificationCenter.default.post(name: .didReceiveOptimizelyProjectIdChange, object: nil)
                NotificationCenter.default.post(name: .didReceiveOptimizelyRevisionChange, object: nil)
            }
        }
                
        // test should wait until all startTimers done, events flushed, and then timer stopped eventually
        wait(for: [exp], timeout: Double(30 * stressFactor))
    }
    
    func testConcurrentDispatchEvents_2() {
        // same tests as above, but with more events with less gaps between them
        // timer (with short interval) will not work periodically with those frequent events dispatch, but this can be a good stress testing.
        
        let numThreads = 10
        let numEventsPerThread = 1000 * stressFactor
        let numEvents = numThreads * numEventsPerThread

        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        dispatcher.batchSize = 999999999       // avoid early-fire by batch-filled

        // keep the test running until all events flushed and timer stopped

        let exp = expectation(description: "delay")
        DispatchQueue.global().async {
            while dispatcher.totalEventsSent < numEvents || dispatcher.timer.property != nil { sleep(1) }
            exp.fulfill()
        }
        
        (0..<numThreads).forEach{ idx in
            DispatchQueue(label:"\(idx)").async {
                (0..<numEventsPerThread).forEach{ e in
                    usleep(UInt32.random(in: 0..<1000))
                    dispatcher.dispatchEvent(event: OTUtils.makeEventForDispatch(), completionHandler: nil)
                }
            }
        }
                
        // test should wait until all startTimers done, events flushed, and then timer stopped eventually
        wait(for: [exp], timeout: Double(30 * stressFactor))
    }
    
    func testConcurrentStartTimer() {
        let numThreads = 100

        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        // one event in the queue
        dispatcher.queue.save(item: EventForDispatch(body: Data()))
                
        // keep the test running until all events flushed and timer stopped

        let exp = expectation(description: "delay")
        DispatchQueue.global().async {
            while dispatcher.queue.count > 0 || dispatcher.timer.property != nil { sleep(1) }
            exp.fulfill()
        }
        
        // multiple threads try to start a timer concurrently
        // only one of them will succeed and other requests will be discarded
        // timer will flush events and then stop timer at the following ticks

        _ = OTUtils.runConcurrent(count: numThreads) { idx in
            dispatcher.startTimer()
        }
                
        // test should wait until all startTimers done, events flushed, and then timer stopped eventually
        wait(for: [exp], timeout: 10)
    }

    func testConcurrentNotifications() {
        let numThreads = 100
        let numEvents = 10

        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 999999999   // disable flush by timer
        dispatcher.batchSize = 999999999       // avoid early-fire by batch-filled

        // keep the test running until all events flushed and timer stopped

        let exp = expectation(description: "delay")
        DispatchQueue.global().async {
            while dispatcher.totalEventsSent < numEvents {
                print("[MultiClients] totalEventSent: \(dispatcher.totalEventsSent)")
                sleep(1)
            }
            exp.fulfill()
        }
        
        (0..<numEvents).forEach{ e in
            dispatcher.dispatchEvent(event: OTUtils.makeEventForDispatch(), completionHandler: nil)
        }

        let result = OTUtils.runConcurrent(count: numThreads) { idx in
            NotificationCenter.default.post(name: .didReceiveOptimizelyProjectIdChange, object: nil)
        }
            
        XCTAssertTrue(result, "Concurrent tasks timed out")

        // test should wait until all startTimers done, events flushed, and then timer stopped eventually
        wait(for: [exp], timeout: 10)
    }

}
