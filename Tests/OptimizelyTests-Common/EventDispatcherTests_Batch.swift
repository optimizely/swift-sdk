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
    var uniqueFileName: String {
        return EventDispatcherTests_Batch.keyTestEventFileName + String(Int.random(in: 0...1000000))
    }
    
    override func setUp() {
        // NOTE: dataStore uses the same file ("OptEventQueue") by default.
        // Concurrent tests will cause data corruption.
        // Use a unique event file for each test and clean up all at the end
        
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName)
        
        // for debug level setting
        HandlerRegistryService.shared.binders.property?.removeAll()
        _ = OptimizelyClient(sdkKey: "any", eventDispatcher: eventDispatcher, defaultLogLevel: .debug)
        
        // clear static states to test first datafile load
        ProjectConfig.observer.reset()
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

// MAKR: - Configuration

extension EventDispatcherTests_Batch {
    
    func testInitialization() {
        let expBatchSize = 12
        let expTimerInterval = 35.0
        let expMaxQueueSize = 123
        
        let ep = DefaultEventDispatcher(batchSize: expBatchSize, timerInterval: expTimerInterval, maxQueueSize: expMaxQueueSize)
        
        XCTAssertEqual(ep.batchSize, expBatchSize)
        XCTAssertEqual(ep.timerInterval, expTimerInterval)
        XCTAssertEqual(ep.maxQueueSize, expMaxQueueSize)
    }

    func testBatchEnabledByDefault() {
        
        // batch allowed by default
        
        var ep = DefaultEventDispatcher()

        let defaultBatchSize = ep.batchSize
        let defaultTimeInterval = ep.timerInterval
        let defaultMaxQueueSize = ep.maxQueueSize

        XCTAssert(defaultBatchSize > 1)
        XCTAssert(defaultTimeInterval > 1)
        XCTAssert(defaultMaxQueueSize > 100)

        // invalid batchSize falls back to default value
        // (timerInterval = 0 is a valid value, meaning no batch)
        // invalid timeInterval tested in "testEventDispatchedOnTimer_ZeroInterval" below

        ep = DefaultEventDispatcher(batchSize: 0, timerInterval: -1, maxQueueSize: 0)
        XCTAssertEqual(ep.batchSize, defaultBatchSize)
        XCTAssertEqual(ep.timerInterval, defaultTimeInterval)
        XCTAssertEqual(ep.maxQueueSize, defaultMaxQueueSize)
    }
    
}

// MARK: - Batch

extension EventDispatcherTests_Batch {
    
    func testEmptyEventBatch() {
        let events = [EventForDispatch]()
        let (num, batch) = events.batch()
        XCTAssertEqual(num, 0)
        XCTAssertNil(batch)
    }
    
    func testSingleEventBatch() {
        let event = makeEventForDispatch(url: kUrlA, event: batchEventA)
        let events = [event]
        let (numEvents, batchEvent) = events.batch()
        XCTAssertEqual(numEvents, 1)
        XCTAssertEqual(batchEvent, event)
    }

    func testInvalidEventOnly() {
        let invalidEvent = makeInvalidEventForDispatchWithWrongData()
        let events = [invalidEvent]
        let (numEvents, batchEvent) = events.batch()
        
        // single invalid event returns as is (SDK sends out to the server as is, where it'll be discarded anyway)
        
        XCTAssertEqual(numEvents, 1)
        XCTAssertEqual(batchEvent, invalidEvent)
    }
    
    func testInvalidEventAtHead() {
        let invalidEvent = makeInvalidEventForDispatchWithWrongData()
        let validEvent = makeEventForDispatch(url: kUrlA, event: batchEventA)
        let events = [invalidEvent, validEvent, validEvent]
        let (numEvents, batchEvent) = events.batch()
        
        // invalid event at the header returns a nil event (SDK discards this locally)
        
        XCTAssertEqual(numEvents, 1)
        XCTAssertNil(batchEvent)
    }

    func testInvalidEventInSecond() {
        let invalidEvent = makeInvalidEventForDispatchWithWrongData()
        let validEvent = makeEventForDispatch(url: kUrlA, event: batchEventA)
        let events = [validEvent, invalidEvent, validEvent]
        let (numEvents, batchEvent) = events.batch()
        
        XCTAssertEqual(numEvents, 1)
        XCTAssertEqual(batchEvent, validEvent)
    }

    func testBatchingEvents() {
        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: batchEventA),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventA)
        ]

        let (numEvents, batch) = events.batch()
        
        XCTAssertEqual(numEvents, events.count)
        
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch!.body)
        XCTAssertNotNil(batchedEvents)
        XCTAssertEqual(batch!.url.absoluteString, kUrlA)
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

        let (numEvents, batch) = events.batch()
        XCTAssertEqual(numEvents, 3)
        
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch!.body)
        
        XCTAssertEqual(batchedEvents.visitors.count, 3, "all events are batched until non-batchable event is found")
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorB)
        XCTAssertEqual(batchedEvents.visitors[2], visitorC)
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

        let (numEvents, batch) = events.batch()
        XCTAssertEqual(numEvents, 3)
        
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch!.body)
        
        XCTAssertEqual(batchedEvents.visitors.count, 3, "all events are batched until non-batchable event is found")
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorB)
        XCTAssertEqual(batchedEvents.visitors[2], visitorC)
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
        
        let (numEvents, batch) = events.batch()
        XCTAssertEqual(numEvents, 3)
        
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch!.body)
        
        XCTAssertEqual(batchedEvents.visitors.count, 3, "all events are batched until non-batchable event is found")
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorB)
        XCTAssertEqual(batchedEvents.visitors[2], visitorC)
    }
    
    func testEventDiscardedWhenQueueIfFull() {
        eventDispatcher.maxQueueSize = 100
        
        // illegal config batchSize cannot be bigger than maxQueueSize. just for testing
        eventDispatcher.timerInterval = 10000.0
        eventDispatcher.batchSize = 1000
        
        var successCount = 0
        var failureCount = 0
        
        let handler = { (result: OptimizelyResult<Data>) -> Void in
            switch result {
            case .success:
                successCount += 1
            case .failure(let error):
                failureCount += 1
                print("DispatchEvent error callback: \(error)")
            }
        }
        
        for _ in 0..<eventDispatcher.maxQueueSize {
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA),
                                          completionHandler: handler)
        }
        
        // now queue must be full. all following events are expected to drop
        
        for _ in 0..<10 {
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB),
                                          completionHandler: handler)
        }
        
        // check out if success/failure callbacks called properly
        
        XCTAssertEqual(successCount, eventDispatcher.maxQueueSize)
        XCTAssertEqual(failureCount, 10)

        // flush
        
        eventDispatcher.close()

        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "all events should be batched together")
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.visitors.count, eventDispatcher.maxQueueSize, "events must be discarded when queue full")
        batchedEvents.visitors.forEach {
            XCTAssertEqual($0, visitorA)
        }

        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
}

// MARK: - FlushEvents

extension EventDispatcherTests_Batch {

    func testFlushEvents() {
        XCTAssert(eventDispatcher.batchSize == 10)
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventB),
                                (kUrlA, batchEventA)])

        eventDispatcher.close()

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
        XCTAssert(eventDispatcher.batchSize == 10)

        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA),
                                (kUrlB, batchEventB)])
            
        eventDispatcher.close()

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
        XCTAssertEqual(batch.url.absoluteString, kUrlB)
        XCTAssertEqual(batchedEvents.visitors[0], visitorB)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    func testFlushEventsWhenBatchFailsWithInvalidEvent() {
        XCTAssert(eventDispatcher.batchSize == 10)
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeInvalidEventForDispatchWithWrongData(), completionHandler: nil)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)

        eventDispatcher.close()

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
        
        // 3rd event discarded silently
        
        // 4th last event sent separately
        
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
        // (1) error injected - all event send fails
        
        eventDispatcher.forceError = true
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA)])

        eventDispatcher.close()

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
        eventDispatcher.close()

        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, maxFailureCount + 1, "only one more since succeeded")
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[3], eventDispatcher.sendRequestedEvents[0])
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
    }

}

// MARK: - FlushEvents on Timer

extension EventDispatcherTests_Batch {

    func testEventDispatchedOnTimer() {
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
    
    func testEventShouldNotBeSentUntilTimer() {
        eventDispatcher.timerInterval = 99999
        
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        DispatchQueue.global().async {
            self.dispatchMultipleEvents([(self.kUrlA, self.batchEventA)])
        }
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "events should not be sent until timer fires")
    }
    
    func testEventDispatchedOnTimer_ZeroInterval() {
        // zero-interval means that all events are sent out immediately
        eventDispatcher.timerInterval = 0

        dispatchMultipleEvents([(self.kUrlA, self.batchEventA),
                                (self.kUrlB, self.batchEventB),
                                (self.kUrlC, self.batchEventC)])

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
        eventDispatcher.timerInterval = 3

        eventDispatcher.exp = expectation(description: "timer")

        self.dispatchMultipleEvents([(self.kUrlA, self.batchEventA),
                                     (self.kUrlA, self.batchEventB)])

        // wait for the 1st batched event transmitted successfully
        wait(for: [eventDispatcher.exp!], timeout: 10)

        // wait more for multiple timer fires to make sure there is no redandant sent out
        waitAsyncSeconds(5)

        // check if we have only one batched event transmitted
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)

        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
    }

    func testEventBatchedAndErrorRecoveredOnTimer() {
        eventDispatcher.timerInterval = 5
        
        // (1) inject error
        
        eventDispatcher.forceError = true
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp?.assertForOverFulfill = false
        
        self.dispatchMultipleEvents([(self.kUrlA, self.batchEventA),
                                     (self.kUrlA, self.batchEventB)])

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

// MARK: - FlushEvents other than timer

extension EventDispatcherTests_Batch {
    
    func testEventsFlushedOnEventQueueSizeHit() {
        eventDispatcher.batchSize = 3
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire
        
        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) add one more event, so batchSize hits and flushed
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")

        dispatchMultipleEvents([(kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on batchSize hit")
    }
    
    func testEventsFlushedOnRevisionChange() {
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName, removeDatafileObserver: false)

        eventDispatcher.batchSize = 1000        // big, won't flush
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire
        
        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) flush on revision-change notification
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        
        // change revision
        datafile = OTUtils.loadJSONDatafile("empty_datafile_new_revision")!
        optimizely.config = try! ProjectConfig(datafile: datafile)
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on the revision change")
    }
    
    func testEventsFlushedOnProjectIdChange() {
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName, removeDatafileObserver: false)

        eventDispatcher.batchSize = 1000        // big, won't flush
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire
        
        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) flush on revision-change notification
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        
        // change projectId
        datafile = OTUtils.loadJSONDatafile("empty_datafile_new_project_id")!
        optimizely.config = try! ProjectConfig(datafile: datafile)

        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on the projectId change")
    }
    
    func testEventsNotFlushedOnOtherDatafileChanges() {
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName, removeDatafileObserver: false)

        eventDispatcher.batchSize = 1000        // big, won't flush
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire
        
        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)
        
        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) not flush on other datafile contents change
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true

        // change accountId (not projectId or revision)
        datafile = OTUtils.loadJSONDatafile("empty_datafile_new_account_id")!
        optimizely.config = try! ProjectConfig(datafile: datafile)
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush on any other changes")
    }
    
    func testEventsNotFlushedOnFirstDatafileLoad() {
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName, removeDatafileObserver: false)

        eventDispatcher.batchSize = 1000        // big, won't flush
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        // old events queued before SDK starts
        
        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA)])
        
        // first datafile load

        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush on the first datafile load")
    }
}

// MARK: - LogEvent Notification

extension EventDispatcherTests_Batch {

    func testLogEventNotificationCalledBeforeBatchSent() {
        eventDispatcher.timerInterval = 0   // no batch

        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        
        var notifUrl: String?
        var notifEvent: [String: Any]?
        
        _ = optimizely.notificationCenter!.addLogEventNotificationListener { (url, event) in
            print("LogEvent Notification called")
            notifUrl = url
            notifEvent = event
        }
        
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)
        
        dispatchMultipleEvents([(kUrlA, batchEventA)])
        eventDispatcher.dispatcher.sync {}
        
        XCTAssertEqual(notifUrl, kUrlA)
        
        // check event contents
        
        if let event = notifEvent, let client = event["client_name"] as? String {
            XCTAssertEqual(client, "swift-sdk")
        } else {
            XCTAssert(false)
        }
    }
    
    // MARK: - Event Validation
    
    // this test can be used for dumping batched events through logEvent notification which can be used for event-validation offline
    func testLogEventNotification_EventValidator() {
        
        // change this number to create event sets with different batch size, but the same number of events to be compared
        eventDispatcher.batchSize = 3          // {1, 2, 3, 10}
        
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire

        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        
        var notifUrl: String?
        var collections = [[String: Any]]()
        
        _ = optimizely.notificationCenter!.addLogEventNotificationListener { (url, event) in
            notifUrl = url
            collections.append(event)
        }
        
        let datafile = OTUtils.loadJSONDatafile("api_datafile")!
        try! optimizely.start(datafile: datafile)
        
        let experimentKey = "exp_with_audience"
        let userA = "11111"
        let userB = "22222"
        let userC = "33333"
        let eventKey = "event1"
        let attributes: [String: Any?] = [
            "testvar": 32
        ]
        let eventTags: [String: Any] = ["browser": "chrome",
                                        "revenue": 123,
                                        "value": 32.5]

        // 10 events total
        
        _ = try! optimizely.activate(experimentKey: experimentKey, userId: userA)
        _ = try! optimizely.activate(experimentKey: experimentKey, userId: userB, attributes: attributes)
        _ = try! optimizely.activate(experimentKey: experimentKey, userId: userC)
        try! optimizely.track(eventKey: eventKey, userId: userC, eventTags: eventTags)
        try! optimizely.track(eventKey: eventKey, userId: userA)
        try! optimizely.track(eventKey: eventKey, userId: userA, eventTags: eventTags)
        try! optimizely.track(eventKey: eventKey, userId: userB)
        try! optimizely.track(eventKey: eventKey, userId: userB, eventTags: eventTags)
        try! optimizely.track(eventKey: eventKey, userId: userA, eventTags: eventTags)
        try! optimizely.track(eventKey: eventKey, userId: userC, eventTags: eventTags)

        optimizely.close()
        
        // merge collected log events in a single batched format to run with Event Validator
        
        var merged = [String: Any]()
        var visitors = [[String: Any]]()
        
        collections.enumerated().forEach { (idx, event) in
            if idx == 0 {
                event.forEach { merged[$0.key] = $0.value }
            }

            visitors += event["visitors"] as! [[String: Any]]
        }
        merged["visistors"] = visitors
        
        print("[Batched Events] collections ---------------------------------------------")
        if let json = try? JSONSerialization.data(withJSONObject: merged) {
            let jsonStr = String(bytes: json, encoding: .utf8)!
            print("\(jsonStr)")
        }
        print("--------------------------------------------------------------")
        
        XCTAssertEqual(notifUrl, EventForDispatch.eventEndpoint)
        XCTAssertEqual(visitors.count, 10)
    }
    
}

// MARK: - OptimizleyClient: Close()

extension EventDispatcherTests_Batch {
    
    func testCloseForOptimizleyClient() {
        self.eventDispatcher = TestEventDispatcher(eventFileName: uniqueFileName, removeDatafileObserver: false)
        
        eventDispatcher.batchSize = 1000        // big, won't flush
        eventDispatcher.timerInterval = 99999   // timer is big, won't fire
        
        HandlerRegistryService.shared.binders.property?.removeAll()  // clear eventDispatcher registered at top
        let optimizely = OptimizelyClient(sdkKey: "SDKKey",
                                          eventDispatcher: eventDispatcher,
                                          defaultLogLevel: .debug)
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        
        // (1) should have no flush
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        try! optimizely.start(datafile: datafile)

        dispatchMultipleEvents([(kUrlA, batchEventA),
                                (kUrlA, batchEventA),
                                (kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) should flush/batch all on close()
        
        optimizely.close()
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on the revision change")
        var batch = eventDispatcher.sendRequestedEvents[0]
        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.visitors.count, 3)
        eventDispatcher.sendRequestedEvents.removeAll()

        // (3) should have no flush
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        try! optimizely.start(datafile: datafile)
        
        dispatchMultipleEvents([(kUrlA, batchEventB),
                                (kUrlA, batchEventA)])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (4) should flush/batch all on close()
        
        optimizely.close()
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on the revision change")
        batch = eventDispatcher.sendRequestedEvents[0]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.visitors.count, 2)

    }
    
}

// MARK: - Random testing

extension EventDispatcherTests_Batch {
    
    func testRandomEvents() {
        runRandomEventsTest(numEvents: 9, eventDispatcher: eventDispatcher, tc: self)
    }
    
    func testRandomEventsWithInvalid() {
        let numEvents = 21
        runRandomEventsTest(numEvents: numEvents, eventDispatcher: eventDispatcher, tc: self, numInvalidEvents: Int(Float(numEvents) * 0.1))
    }

    // Utils
    
    func runRandomEventsTest(numEvents: Int, eventDispatcher: TestEventDispatcher, tc: XCTestCase, numInvalidEvents: Int=0) {
        eventDispatcher.batchSize = Int.random(in: 1..<10)
        eventDispatcher.timerInterval = Double(Int.random(in: 1..<3))
        
        print("[RandomTest] configuration: (batchSize, timeInterval) = (\(eventDispatcher.batchSize), \(eventDispatcher.timerInterval))")

        let exp = XCTestExpectation(description: "random")
        let expectedVisistors = numEvents - numInvalidEvents  // all invalid events will be discarded

        // dispatch evetns in a separate thread for stressting enqueue and batch happen simultaneously
        DispatchQueue.global().async {
            self.dispatchRandomEvents(numEvents: numEvents, numInvalidEvents: numInvalidEvents)
            
            print("[RandomTest] dispatched all events")
            
            // extra delay to make sure all events are flushed and check if no more than expected is batched
            let extraDelay = max(Int(eventDispatcher.timerInterval) * 2, 60)
            var delay = 0
            while delay < extraDelay {
                if eventDispatcher.numReceivedVisitors >= expectedVisistors {
                    self.waitAsyncSeconds(3)  // extra delay to make sure that no redundant events transmitted
                    break
                }
                
                self.waitAsyncSeconds(1)
                delay += 1
            }
            
            print("[RandomTest] waited \(delay) seconds after dispatched all events")
            exp.fulfill()
        }
        
        tc.wait(for: [exp], timeout: 10*60)
        
        XCTAssertEqual(eventDispatcher.numReceivedVisitors, expectedVisistors)
    }
    
    func dispatchRandomEvents(numEvents: Int, numInvalidEvents: Int) {
        let urlPool = [kUrlA]
        
        let projectIdPool = [kProjectIdA]
        let revisionPool = [kRevisionA, kRevisionA, kRevisionA, kRevisionA, kRevisionB]
        let visitorPool = [visitorA, visitorB, visitorC]
        
        var posForInvalid = Set<Int>()
        while posForInvalid.count < numInvalidEvents {
            posForInvalid.insert(Int.random(in: 0..<numEvents))
        }
        
        for i in 0..<numEvents {
            // insert invalid event randomly
            if posForInvalid.contains(i) {
                eventDispatcher.dispatchEvent(event: makeInvalidEventForDispatchWithWrongData(), completionHandler: nil)
                print("[RandomTest][\(i)] dispatch an invalid event")
                continue
            }
            
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
    
    func makeInvalidEventForDispatchWithNilUrl() -> EventForDispatch {
        let data = try! JSONEncoder().encode(batchEventA)
        return EventForDispatch(url: nil, body: data)
    }
    
    func makeInvalidEventForDispatchWithWrongData() -> EventForDispatch {
        return EventForDispatch(url: URL(string: kUrlA), body: Data())
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
    
    func dispatchMultipleEvents(_ events: [(url: String, event: BatchEvent)]) {
        events.forEach {
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: $0.url, event: $0.event),
                                          completionHandler: nil)
        }
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
    let eventFileName: String
    
    // set this if need to wait sendEvent completed
    var exp: XCTestExpectation?
    
    init(eventFileName: String, removeDatafileObserver: Bool = true) {
        self.eventFileName = eventFileName
        super.init(dataStoreName: eventFileName)
        
        // block interference from other tests notifications when testing batch timing
        if removeDatafileObserver {
            removeProjectChangeNotificationObservers()
        }
    }
    
    override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        sendRequestedEvents.append(event)
        
        do {
            let decodedEvent = try JSONDecoder().decode(BatchEvent.self, from: event.body)
            numReceivedVisitors += decodedEvent.visitors.count
            print("[TestEventDispatcher][SendEvent][\(eventFileName)] Received a batched event with visistors: \(decodedEvent.visitors.count) \(numReceivedVisitors)")
        } catch {
            // invalid event format detected
            // - invalid events are supposed to be filtered out when batching (converting to nil, so silently dropped)
            // - an exeption is that an invalid event is alone in the queue, when validation is skipped for performance on common path
            
            // pass through invalid events, so server can filter them out
        }

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
