/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import XCTest

class EventDispatcherTests_Batch: XCTestCase {
    
    let kAccountId = "11111"
    let kClientVersion = "3.1.2"
    let kClientName = "swift-sdk"
    let kAnonymizeIP = true
    let kEnrichDecision = true
    
    let kRevisionA = "1001"
    let kRevisionB = "1002"
    let kRevisionC = "1003"
    
    let kProjectIdA = "33331"
    let kProjectIdB = "33332"
    let kProjectIdC = "33333"

    let kUrlA = "https://urla.com"
    let kUrlB = "https://urlb.com"
    let kUrlC = "https://urlc.com"

    let kUserIdA = "123"
    let kUserIdB = "456"
    let kUserIdC = "789"
    
    var eventDispatcher: TestEventDispatcher!
    static let keyTestEventFileName = "OPTEventQueue-Test-"
    
    override func setUp() {
        // NOTE: dataStore uses the same file ("OptEventQueue") by default.
        // Concurrent tests will cause data corruption.
        // Use a unique event file for each test and clean up all at the end
        
        let uniqueFileName = EventDispatcherTests_Batch.keyTestEventFileName + String(Date().timeIntervalSince1970)
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName)
    }
    
    override func tearDown() {
        // make sure timer off at the of each test to avoid interference
        
        self.eventDispatcher.timer.performAtomic { $0.invalidate() }
    }
    
    override class func tearDown() {
        // remove all event files used for testing
        
        let fm = FileManager.default
        let docFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let allFiles = try! fm.contentsOfDirectory(atPath: docFolder)
        
        let predicate = NSPredicate(format: "self CONTAINS '\(keyTestEventFileName)'")
        let filtered = allFiles.filter { predicate.evaluate(with: $0) }
    
        filtered.forEach {
            do {
                try fm.removeItem(atPath: (docFolder as NSString).appendingPathComponent($0))
                print("[EventBatchTest] Removed temporary event file: \($0)")
            } catch {
                print("[EventBatchTest] ERROR: cannot remove temporary event file: \($0)")
            }
        }
    }
}

// MARK: - Batch

extension EventDispatcherTests_Batch {
    
    func testEmptyOrSingleEventBatch() {
        var events = [EventForDispatch]()
        var batch = events.batch()
        XCTAssertNil(batch)
        
        let event = makeEventForDispatch(url: kUrlA, event: batchEventA)
        events.append(event)
        batch = events.batch()
        XCTAssertEqual(event, batch)
    }
    
    func testNilEventDispatchBody() {
        var events = [EventForDispatch]()
        let event = EventForDispatch(url: URL(string: kUrlA), body: Data())
        events.append(contentsOf: [event, event])
        let batch = events.batch()
        XCTAssertNil(batch)
    }

    func testBatchingEvents() {
        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: batchEventA),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventA)
        ]

        let batch = events.batch()!
        XCTAssertNotNil(batch)
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertNotNil(batchedEvents)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectIdA)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batchedEvents.visitors.count, events.count)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorB)
        XCTAssertEqual(batchedEvents.visitors[2], visitorB)
        XCTAssertEqual(batchedEvents.visitors[3], visitorA)
    }

    func testBatchingEventsWhenUrlsNotEqual() {
        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: batchEventA),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventC),
            makeEventForDispatch(url: kUrlB, event: batchEventA)
        ]

        if let batch = events.batch() {
            let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
            XCTAssertEqual(batchedEvents.visitors.count, 3, "all events are batched until non-batchable event is found")
            XCTAssertEqual(batchedEvents.visitors[0], visitorA)
            XCTAssertEqual(batchedEvents.visitors[1], visitorB)
            XCTAssertEqual(batchedEvents.visitors[2], visitorC)
        } else {
            XCTAssert(false, "batch failed")
        }
    }

    func testBatchingEventsWhenProjectIdsNotEqual() {
        // projectId change will flush all pending events, so this scenario should not happen frequently.
        // but still possible when previous flushes failed.
        
        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: batchEventA),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventC),
            makeEventForDispatch(url: kUrlA, event: makeTestBatchEvent(projectId: "99999", visitor: visitorA))
        ]

        if let batch = events.batch() {
            let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
            XCTAssertEqual(batchedEvents.visitors.count, 3, "all events are batched until non-batchable event is found")
            XCTAssertEqual(batchedEvents.visitors[0], visitorA)
            XCTAssertEqual(batchedEvents.visitors[1], visitorB)
            XCTAssertEqual(batchedEvents.visitors[2], visitorC)
        } else {
            XCTAssert(false, "batch failed")
        }
    }

    func testBatchingEventsWhenRevisionNotEqual() {
        // datafile revision change will flush all pending events, so this scenario should not happen frequently.
        // but still possible when previous flushes failed.

        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: batchEventA),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventC),
            makeEventForDispatch(url: kUrlA, event: makeTestBatchEvent(revision: "99999", visitor: visitorA))
        ]
        
        if let batch = events.batch() {
            let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
            XCTAssertEqual(batchedEvents.visitors.count, 3, "all events are batched until non-batchable event is found")
            XCTAssertEqual(batchedEvents.visitors[0], visitorA)
            XCTAssertEqual(batchedEvents.visitors[1], visitorB)
            XCTAssertEqual(batchedEvents.visitors[2], visitorC)
        } else {
            XCTAssert(false, "batch failed")
        }
    }

}

// MARK: - FlushEvents

extension EventDispatcherTests_Batch {

    func testFlushEvents() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        XCTAssert(eventDispatcher.batchSize == 10)
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        
        eventDispatcher.flushEvents()
        eventDispatcher.dispatcher.sync {}
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectIdA)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorB)
        XCTAssertEqual(batchedEvents.visitors[2], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 3)
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
        
        XCTAssert(eventDispatcher.batchSize == 10)

    }
    
    func testFlushEventsWhenBatchFails() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        XCTAssert(eventDispatcher.batchSize == 10)

        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlB, event: batchEventB), completionHandler: nil)
        
        eventDispatcher.flushEvents()
        eventDispatcher.dispatcher.sync {}
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 2, "different urls should not be batched")
        
        // first 2 events batched together
        
        var batch = eventDispatcher.sendRequestedEvents[0]
        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectIdA)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 2)
        
        // the last event sent separately
        
        batch = eventDispatcher.sendRequestedEvents[1]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectIdA)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    func testFlushEventsWhenSendEventFailsAndRecovers() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        // (1) error injected - all event send fails
        
        eventDispatcher.forceError = true
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        
        eventDispatcher.flushEvents()
        eventDispatcher.dispatcher.sync {}
        
        let maxFailureCount = 3 + 1   // DefaultEventDispatcher.maxFailureCount + 1
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, maxFailureCount, "repeated the same request several times before giveup")
        
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 2)
        
        // confirm that repeat-on-failure sends same packets
        for i in 1..<eventDispatcher.sendRequestedEvents.count {
            XCTAssertEqual(eventDispatcher.sendRequestedEvents[i], eventDispatcher.sendRequestedEvents[0])
        }
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 2, "all failed to transmit, so should keep all original events")
        
        // (2) error removed - now events sent out successfully
        
        eventDispatcher.forceError = false
        
        // assume flushEvents called again on next timer fire
        eventDispatcher.flushEvents()
        eventDispatcher.dispatcher.sync {}

        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, maxFailureCount + 1, "only one more since succeeded")
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[3], eventDispatcher.sendRequestedEvents[0])
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
    }

}

// MARK: - Timer-fired FlushEvents

extension EventDispatcherTests_Batch {

    func testEventDispatchedOnTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        eventDispatcher.timerInterval = 2
        
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp!.assertForOverFulfill = false   // allow redundant fulfull for testing

        DispatchQueue.global().async {
            self.eventDispatcher.dispatchEvent(event: self.makeEventForDispatch(url: self.kUrlA, event: self.batchEventA), completionHandler: nil)
            sleep(1)
            self.eventDispatcher.dispatchEvent(event: self.makeEventForDispatch(url: self.kUrlA, event: self.batchEventA), completionHandler: nil)
            sleep(3)
            self.eventDispatcher.dispatchEvent(event: self.makeEventForDispatch(url: self.kUrlA, event: self.batchEventA), completionHandler: nil)
        }

        wait(for: [eventDispatcher.exp!], timeout: 10)
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)

        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 2, "only first 2 events when timer expires")
    }

    func testEventDispatchedOnTimer_ZeroInterval() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        // zero-interval means that all events are sent out immediately
        eventDispatcher.timerInterval = 0

        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlB, event: batchEventB), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlC, event: batchEventC), completionHandler: nil)
        eventDispatcher.dispatcher.sync {}
        
        continueAfterFailure = false   // stop on XCTAssertEqual failure instead of array out-of-bound exception
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 3)
        
        var batch = eventDispatcher.sendRequestedEvents[0]
        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        batch = eventDispatcher.sendRequestedEvents[1]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlB)
        XCTAssertEqual(batchedEvents.visitors[0], visitorB)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        batch = eventDispatcher.sendRequestedEvents[2]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlC)
        XCTAssertEqual(batchedEvents.visitors[0], visitorC)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    func testEventBatchedOnTimer_CheckNoRedundantSend() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        eventDispatcher.timerInterval = 3

        eventDispatcher.exp = expectation(description: "timer")

        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB), completionHandler: nil)

        // wait for the 1st batched event transmitted successfully
        wait(for: [eventDispatcher.exp!], timeout: 10)

        // wait more for multiple timer fires to make sure there is no redandant sent out
        waitAsyncSeconds(5)

        // check if we have only one batched event transmitted
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)

        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
    }

    func testEventBatchedAndErrorRecoveredOnTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        eventDispatcher.timerInterval = 5
        
        // (1) inject error
        
        eventDispatcher.forceError = true
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp?.assertForOverFulfill = false
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        sleep(1)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB), completionHandler: nil)
        
        // wait for the first timer-fire
        wait(for: [eventDispatcher.exp!], timeout: 10)
        // tranmission is expected to fail
        XCTAssertEqual(eventDispatcher.dataStore.count, 2, "all failed to transmit, so should keep all original events")
        
        // (2) remove error. check if events are transmitted successfully on next timer-fire
        sleep(3)   // wait all failure-retries (3 times) completed
        eventDispatcher.forceError = false
        eventDispatcher.exp = expectation(description: "timer")
        
        // wait for the next timer-fire
        wait(for: [eventDispatcher.exp!], timeout: 10)
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
    }
}

// MARK: - FlushEvents other than time-fired

extension EventDispatcherTests_Batch {
    
    func testEventsFlushedOnEventQueueSizeHit() {
        
    }

    func testEventsFlushedOnRevisionChange() {
        
    }
    
    func testEventsFlushedOnProjectIdChange() {
        
    }

    func testEventsFlushedOnUrlChange() {
        
    }
    
}

// MARK: - iOS9 Devices

extension EventDispatcherTests_Batch {
    
    func testFlushEventsForIOS9Only() {
        // this tests iOS9 (no-timer)
        if #available(iOS 10.0, tvOS 10.0, *) { return }
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatcher.sync {}
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectIdA)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    func testFlushEventsForIOS9Only_ZeroInterval() {
        // this tests iOS9 (no-timer)
        if #available(iOS 10.0, tvOS 10.0, *) { return }
        
        eventDispatcher.timerInterval = 0
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatcher.sync {}
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
}

// MARK: - Random testing

extension EventDispatcherTests_Batch {
    
    func testRandomEvents10() {
        runRandomEventsTest(numEvents: 9, eventDispatcher: eventDispatcher, tc: self)
    }
    
    func testRandomEvents100() {
        runRandomEventsTest(numEvents: 111, eventDispatcher: eventDispatcher, tc: self)
    }
    
    // Utils
    
    func runRandomEventsTest(numEvents: Int, eventDispatcher: TestEventDispatcher, tc: XCTestCase) {
        eventDispatcher.batchSize = Int.random(in: 1..<10)
        eventDispatcher.timerInterval = Double(Int.random(in: 1..<3))
        
        print("[RandomTest] configuration: (batchSize, timeInterval) = (\(eventDispatcher.batchSize), \(eventDispatcher.timerInterval))")

        let exp = XCTestExpectation(description: "random")
        
        // dispatch evetns in a separate thread for stressting enqueu and batch happen simultaneously
        DispatchQueue.global().async {
            self.dispatchRandomEvents(numEvents: numEvents)
            
            print("[RandomTest] dispatched all events")
            
            // extra delay to make sure all events are flushed and check if no more than expected is batched
            let extraDelay = max(Int(eventDispatcher.timerInterval) * 2, 20)
            var delay = 0
            while delay < extraDelay {
                if eventDispatcher.numReceivedVisitors >= numEvents {
                    self.waitAsyncSeconds(3)  // extra delay to check if any redundant events transmitted
                    break
                }
                
                self.waitAsyncSeconds(1)
                delay += 1
            }
            
            print("RandomTest] waited \(delay) seconds after dispatched all events")
            exp.fulfill()
        }
        
        tc.wait(for: [exp], timeout: 10*60)
        XCTAssertEqual(eventDispatcher.numReceivedVisitors, numEvents)
    }
    
    func dispatchRandomEvents(numEvents: Int) {
        let urlPool = [kUrlA]
        
        let projectIdPool = [kProjectIdA]
        let revisionPool = [kRevisionA, kRevisionA, kRevisionA, kRevisionA, kRevisionB]
        let visitorPool = [visitorA, visitorB, visitorC]
        
        for i in 0..<numEvents {
            let url = urlPool.randomElement()
            
            let projectId = projectIdPool.randomElement()
            let revision = revisionPool.randomElement()
            let visitor = visitorPool.randomElement()
            let event = makeTestBatchEvent(projectId: projectId, revision: revision, visitor: visitor)
            print("[RandomTest][\(i)] dispatch event: revision = \(revision!)")
            
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: url!, event: event), completionHandler: nil)
            waitAsyncMilliseconds(Int.random(in: 0..<100))  // random delays between event dispatches
        }
    }
}

// MARK: - Utils

extension EventDispatcherTests_Batch {
    
    func makeEventForDispatch(url: String, event: BatchEvent) -> EventForDispatch {
        let data = try! JSONEncoder().encode(event)
        return EventForDispatch(url: URL(string: url), body: data)
    }
    
    func makeTestBatchEvent(projectId: String?=nil, revision: String?=nil, visitor: Visitor?=nil) -> BatchEvent {
        let testProjectId = projectId ?? kProjectIdA
        let testVisitor = visitor ?? visitorA
        let testRevision = revision ?? kRevisionA
        
        return BatchEvent(revision: testRevision,
                          accountID: kAccountId,
                          clientVersion: kClientVersion,
                          visitors: [testVisitor],
                          projectID: testProjectId,
                          clientName: kClientName,
                          anonymizeIP: kAnonymizeIP,
                          enrichDecisions: kEnrichDecision)
    }
    
    var batchEventA: BatchEvent {
        return makeTestBatchEvent(visitor: visitorA)
    }
    
    var batchEventB: BatchEvent {
        return makeTestBatchEvent(visitor: visitorB)
    }

    var batchEventC: BatchEvent {
        return makeTestBatchEvent(visitor: visitorC)
    }

    var visitorA: Visitor {
        return Visitor(attributes: [],
                       snapshots: [],
                       visitorID: kUserIdA)
    }
    
    var visitorB: Visitor {
        return Visitor(attributes: [],
                       snapshots: [],
                       visitorID: kUserIdB)
    }

    var visitorC: Visitor {
        return Visitor(attributes: [],
                       snapshots: [],
                       visitorID: kUserIdC)
    }
    
    // use this instead of sleep
    // - force delay while not freezing batchInterval timer
    func waitAsyncMilliseconds(_ delay: Int) {
        let exp = XCTestExpectation(description: "delay")
        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(delay)) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: TimeInterval(delay/1000 + 10))
    }
    
    func waitAsyncSeconds(_ delay: Int) {
        waitAsyncMilliseconds(delay * 1000)
    }
}

// MARK: - Fake EventDispatcher

class TestEventDispatcher: DefaultEventDispatcher {
    var sendRequestedEvents: [EventForDispatch] = []
    var forceError = false
    var numReceivedVisitors = 0
    
    // set this if need to wait sendEvent completed
    var exp: XCTestExpectation?
    
    init(eventFileName: String) {
        super.init(dataStoreName: eventFileName)
     }
    
    override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        sendRequestedEvents.append(event)
        
        let decodedEvent = try! JSONDecoder().decode(BatchEvent.self, from: event.body)
        numReceivedVisitors += decodedEvent.visitors.count
        print("[SendEvent] Received a batched event with visistors: \(decodedEvent.visitors.count) \(numReceivedVisitors)")

        // must call completionHandler to complete synchronization
        super.sendEvent(event: event) { _ in
            if self.forceError {
                completionHandler(.failure(.eventDispatchFailed("forced")))
            } else {
                // return success to clear store after sending events
                completionHandler(.success(Data()))
            }

            self.exp?.fulfill()
        }
    }
    
}
