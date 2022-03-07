//
// Copyright 2021-2022, Optimizely, Inc. and contributors 
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
    let stressFactor = 1    // increase this (10) to give more stress with longer running time

    override func setUpWithError() throws {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
        OTUtils.clearAllEventQueues()
    }

    override func tearDownWithError() throws {
        OTUtils.clearAllEventQueues()
    }

    func testConcurrentDispatchEvents() {
        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        dispatcher.batchSize = 999999999       // avoid early-fire by batch-filled

        let exp = dispatchEventsConcurrently(dispatcher: dispatcher,
                                             numThreads: 50,
                                             numEventsPerThread: (10 * stressFactor),
                                             maxRandomIntervalInUsecs: 1000000)
        wait(for: [exp], timeout: Double(30 * stressFactor))
    }
    
    func testConcurrentDispatchEvents_2() {
        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 0           // no batch

        let exp = dispatchEventsConcurrently(dispatcher: dispatcher,
                                             numThreads: 50,
                                             numEventsPerThread: (10 * stressFactor),
                                             maxRandomIntervalInUsecs: 1000000)
        wait(for: [exp], timeout: Double(30 * stressFactor))
    }
    
    func testConcurrentDispatchEvents_3() {
        // same tests as above, but with more events with less gaps between them
        // timer (with short interval) will not work periodically with those frequent events dispatch, but this can be a good stress testing.

        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        dispatcher.batchSize = 999999999       // avoid early-fire by batch-filled

        let exp = dispatchEventsConcurrently(dispatcher: dispatcher,
                                             numThreads: 10,
                                             numEventsPerThread: (100 * stressFactor),
                                             maxRandomIntervalInUsecs: 1000)
        wait(for: [exp], timeout: Double(30 * stressFactor))
    }
    
    func testConcurrentDispatchEvents_withNotifications() {
        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        dispatcher.batchSize = 999999999       // avoid early-fire by batch-filled

        let exp = dispatchEventsConcurrently(dispatcher: dispatcher,
                                             numThreads: 10,
                                             numEventsPerThread: (100 * stressFactor),
                                             maxRandomIntervalInUsecs: 1000,
                                             injectNotifications: true)
        wait(for: [exp], timeout: Double(30 * stressFactor))
    }
        
    func testConcurrentStartTimer() {
        let numThreads = 50

        let dispatcher = DumpEventDispatcher()
        dispatcher.timerInterval = 1
        // one event in the queue
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))
                
        // keep the test running until all events flushed and timer stopped

        let exp = expectation(description: "delay")
        DispatchQueue.global().async {
            while dispatcher.eventQueue.count > 0 || dispatcher.timer.property != nil { sleep(1) }
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
}

// MARK: - utils

extension EventDispatcherTests_MultiClients {

    func dispatchEventsConcurrently(dispatcher: DumpEventDispatcher,
                                    numThreads: Int,
                                    numEventsPerThread: Int,
                                    maxRandomIntervalInUsecs: Int,
                                    injectNotifications: Bool = false) -> XCTestExpectation {
        let numEvents = numThreads * numEventsPerThread
        
        // keep the test running until all events flushed and timer stopped

        let exp = expectation(description: "delay")
        DispatchQueue.global().async {
            while dispatcher.totalEventsSent < numEvents || dispatcher.timer.property != nil { sleep(1) }
            exp.fulfill()
        }
        
        (0..<numThreads).forEach{ idx in
            DispatchQueue(label:"\(idx)").async {
                (0..<numEventsPerThread).forEach{ e in
                    usleep(UInt32.random(in: 0..<UInt32(maxRandomIntervalInUsecs)))
                    dispatcher.dispatchEvent(event: OTUtils.makeEventForDispatch(), completionHandler: nil)
                }
            }
        }
        
        return exp
    }
    
}
