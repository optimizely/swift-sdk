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
    
    let kRevision = "321"
    let kAccountId = "11111"
    let kProjectId = "33333"
    let kClientVersion = "3.1.2"
    let kClientName = "swift-sdk"
    let kAnonymizeIP = true
    let kEnrichDecision = true
    
    let kUrlA = "https://urla.com"
    let kUrlB = "https://urlb.com"
    let kUrlC = "https://urlb.com"

    let kUserIdA = "123"
    let kUserIdB = "456"
    let kUserIdC = "789"
    
    var eventDispatcher: TestEventDispatcher!
    
    override func setUp() {
        self.eventDispatcher = TestEventDispatcher(resetPendingEvents: true)
    }
    
    override func tearDown() {
        // make sure timer off at the of each test to avoid interference
        
        self.eventDispatcher.timer.performAtomic { $0.invalidate() }
    }

}

// MARK: - Batch

extension EventDispatcherTests_Batch {

    func testBatchingEvents() {
        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: batchEventA),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventB),
            makeEventForDispatch(url: kUrlA, event: batchEventA)
        ]

        let batch = events.batch()!
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectId)
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
            makeEventForDispatch(url: kUrlB, event: batchEventB)
        ]

        let batch = events.batch()
        XCTAssertNil(batch)
    }

    func testBatchingEventsWhenProjectIdsNotEqual() {
        let be1 = makeTestBatchEvent(projectId: nil, visitor: visitorA)
        let be2 = makeTestBatchEvent(projectId: "99999", visitor: visitorA)

        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, event: be1),
            makeEventForDispatch(url: kUrlB, event: be2)
        ]

        let batch = events.batch()
        XCTAssertNil(batch)
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
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectId)
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
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 3, "no batch expected since urls are all different, so each sent separately")
        
        var batch = eventDispatcher.sendRequestedEvents[0]
        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectId)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        // Note that 1st 2 events (kUrlA, kUrlA) can be batched though the next 2 events are not
        // but we do not batch them if we cannot batch all, so it's expected they are all sent out individually
        
        batch = eventDispatcher.sendRequestedEvents[1]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectId)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        batch = eventDispatcher.sendRequestedEvents[2]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectId)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batch.url.absoluteString, kUrlB)
        XCTAssertEqual(batchedEvents.visitors[0], visitorB)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
        
        XCTAssert(eventDispatcher.batchSize == 10)        
    }
    
    func testFlushEventsWhenSendEventFails() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

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
        
        // repeated send the same event (3+1 times) when failed all
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[1], eventDispatcher.sendRequestedEvents[0])
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[2], eventDispatcher.sendRequestedEvents[0])
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[3], eventDispatcher.sendRequestedEvents[0])

        XCTAssertEqual(eventDispatcher.dataStore.count, 2, "all failed to transmit, so should keep all original events")
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
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[1], eventDispatcher.sendRequestedEvents[0])
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[2], eventDispatcher.sendRequestedEvents[0])
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[3], eventDispatcher.sendRequestedEvents[0])
        
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
        eventDispatcher.timerInterval = 3
        
        eventDispatcher.exp = expectation(description: "timer")
        
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        
        wait(for: [eventDispatcher.exp!], timeout: 10)
        
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
    }

    func testEventDispatchedOnTimer_ZeroInterval() {
        // zero-interval means that all events are sent out immediately
        eventDispatcher.timerInterval = 0

        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        eventDispatcher.dispatcher.sync {}
        
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
    }
    
    func testEventBatchedOnTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        eventDispatcher.timerInterval = 3

        eventDispatcher.exp = expectation(description: "timer")

        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        sleep(1)
        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB), completionHandler: nil)

        wait(for: [eventDispatcher.exp!], timeout: 10)
        XCTAssert(eventDispatcher.sendRequestedEvents.count > 0)

        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorB)
        XCTAssertEqual(batchedEvents.visitors.count, 2)
        
        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
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
        sleep(10)

        // check if we have only one batched event transmitted
        XCTAssert(eventDispatcher.sendRequestedEvents.count == 1)

        XCTAssertEqual(eventDispatcher.dataStore.count, 0, "all expected to get transmitted successfully")
    }

    func testEventBatchedAndErrorRecoveredOnTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        eventDispatcher.timerInterval = 5
        
        // (1) inject error
        
        eventDispatcher.forceError = true
        eventDispatcher.exp = expectation(description: "timer")
        
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

// MARK: - queueSize larger than batchSize
extension EventDispatcherTests_Batch {
    
    func testFlushQueueLargerThanBatchSize_File() {
        // .file backingStore
        eventDispatcher.timerInterval = 5
        eventDispatcher.batchSize = 10
        eventDispatcher.exp = expectation(description: "timer")
        
        // flush any events that may currently be in the queue
        eventDispatcher.flushEvents()
        
        // add 12 events to queue
        for _ in 1...12 {
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        }
        XCTAssertEqual(eventDispatcher.dataStore.count, 12)
        
        eventDispatcher.flushEvents()
        
        eventDispatcher.exp = expectation(description: "timer")
        wait(for: [eventDispatcher.exp!], timeout: 10)
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    func testFlushQueueLargerThanBatchSizeTwice_File() {
        // .file backingStore
        eventDispatcher.batchSize = 10
        
        // flush any events that may currently be in the queue
        eventDispatcher.flushEvents()
        
        // add 16 events to queue
        for _ in 1...16 {
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        }
        eventDispatcher.dispatcher.sync {}
        XCTAssertEqual(eventDispatcher.dataStore.count, 16)
        
        eventDispatcher.flushEvents()
        eventDispatcher.dispatcher.sync {}
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
        
        // add 17 more events to queue
        for _ in 1...17 {
            eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        }
        eventDispatcher.dispatcher.sync {}
        XCTAssertEqual(eventDispatcher.dataStore.count, 17)
        
        eventDispatcher.flushEvents()
        eventDispatcher.dispatcher.sync {}
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    func testFlushQueueLargerThanBatchSize_Memory() {
        // .memory backingStore
        let memoryEventDispatcher = DefaultEventDispatcher.init(batchSize: 10, backingStore: .memory, dataStoreName: "OPTEventQueue", timerInterval: 60*1)
        let exp: XCTestExpectation = expectation(description: "timer")
        
        // flush any events that may currently be in the queue
        memoryEventDispatcher.flushEvents()
        
        // add 12 events to queue
        for _ in 1...12 {
            memoryEventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        }
        XCTAssertEqual(memoryEventDispatcher.dataStore.count, 12)
        
        memoryEventDispatcher.flushEvents()
        wait(for: [exp], timeout: 50)
        XCTAssertEqual(memoryEventDispatcher.dataStore.count, 0)
    }
    
    func testFlushQueueLargerThanBatchSizeTwice_Memory() {
        // .memory backingStore
        let memoryEventDispatcher = DefaultEventDispatcher.init(batchSize: 10, backingStore: .memory, dataStoreName: "OPTEventQueue", timerInterval: 60*1)
        
        // flush any events that may currently be in the queue
        memoryEventDispatcher.flushEvents()
        
        // add 16 events to queue
        for _ in 1...16 {
            memoryEventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        }
        XCTAssertEqual(memoryEventDispatcher.dataStore.count, 16)
        
        memoryEventDispatcher.flushEvents()
        XCTAssertEqual(memoryEventDispatcher.dataStore.count, 0)
        
        // add 17 more events to queue
        for _ in 1...17 {
            memoryEventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
        }
        XCTAssertEqual(memoryEventDispatcher.dataStore.count, 17)
        
        memoryEventDispatcher.flushEvents()
        XCTAssertEqual(memoryEventDispatcher.dataStore.count, 0)
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
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectId)
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
        XCTAssertEqual(batchedEvents.revision, kRevision)
        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
    }
    
    // TODO: [Tom] these 2 tests fails - please take a look
    
//    func testFlushEventsForIOS9Only_MultipleEvents_NotBatchable() {
//        // this tests iOS9 (no-timer)
//        if #available(iOS 10.0, tvOS 10.0, *) { return }
//
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlB, event: batchEventB), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlC, event: batchEventC), completionHandler: nil)
//        eventDispatcher.dispatcher.sync {}
//
//        continueAfterFailure = false   // stop on XCTAssertEqual failure instead of array out-of-bound exception
//        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 3)
//
//        var batch = eventDispatcher.sendRequestedEvents[0]
//        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
//        XCTAssertEqual(batch.url.absoluteString, kUrlA)
//        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
//        XCTAssertEqual(batchedEvents.visitors.count, 1)
//
//        batch = eventDispatcher.sendRequestedEvents[1]
//        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
//        XCTAssertEqual(batch.url.absoluteString, kUrlB)
//        XCTAssertEqual(batchedEvents.visitors[0], visitorB)
//        XCTAssertEqual(batchedEvents.visitors.count, 1)
//
//        batch = eventDispatcher.sendRequestedEvents[2]
//        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
//        XCTAssertEqual(batch.url.absoluteString, kUrlC)
//        XCTAssertEqual(batchedEvents.visitors[0], visitorC)
//        XCTAssertEqual(batchedEvents.visitors.count, 1)
//
//        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
//    }
//
//    func testFlushEventsForIOS9Only_MultipleEvents_Batchable() {
//        // this tests iOS9 (no-timer)
//        if #available(iOS 10.0, tvOS 10.0, *) { return }
//
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventC), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventC), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventB), completionHandler: nil)
//        eventDispatcher.dispatchEvent(event: makeEventForDispatch(url: kUrlA, event: batchEventA), completionHandler: nil)
//        eventDispatcher.dispatcher.sync {}
//
//        // batch is not deterministic since it is sensitive to event arrival time.
//        // we check if all visitors are included in all (non-)bateched events successfully
//
//        var receivedVisistors = [Visitor]()
//        eventDispatcher.sendRequestedEvents.forEach { batch in
//            let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
//            receivedVisistors.append(contentsOf: batchedEvents.visitors)
//        }
//
//        XCTAssertEqual(receivedVisistors, [visitorA, visitorB, visitorC, visitorC, visitorB, visitorA])
//        XCTAssertEqual(eventDispatcher.dataStore.count, 0)
//    }

}

// MARK: - Utils

extension EventDispatcherTests_Batch {
    
    func makeEventForDispatch(url: String, event: BatchEvent) -> EventForDispatch {
        let data = try! JSONEncoder().encode(event)
        return EventForDispatch(url: URL(string: url), body: data)
    }
    
    func makeTestBatchEvent(projectId: String?=nil, visitor: Visitor?=nil) -> BatchEvent {
        let testProjectId = projectId ?? kProjectId
        let testVisitor = visitor ?? visitorA
        
        return BatchEvent(revision: kRevision,
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

}

// MARK: - Fake EventDispatcher

class TestEventDispatcher: DefaultEventDispatcher {
    var sendRequestedEvents: [EventForDispatch] = []
    var forceError = false
    
    // set this if need to wait sendEvent completed
    var exp: XCTestExpectation?
    
    init(resetPendingEvents: Bool) {
        super.init()
        
        if resetPendingEvents {
            _ = dataStore.removeLastItems(count: 1000)
        }
    }
    
    override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
        sendRequestedEvents.append(event)

        // must call completionHandler to complete synchronization
        super.sendEvent(event: event) { _ in
            if self.forceError {
                completionHandler(.failure(.eventDispatchFailed("forced")))
            } else {
                // return success to clear store after sending events
                completionHandler(.success(Data()))
            }

            self.exp?.fulfill()
            self.exp = nil   // nullify to avoid repeated calls
        }
    }
    
}
