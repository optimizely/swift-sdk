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

class EventProcessorTests_Batch: XCTestCase {
    
    let kSdkKey = "any key"
    
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
    
    var eventProcessor: TestEventProcessor!
    var eventDispatcher: TestHTTPEventDispatcher!

    static let keyTestEventFileName = "EventProcessorTests-Batch---"
    var uniqueFileName: String {
        return EventProcessorTests_Batch.keyTestEventFileName + String(Int.random(in: 0...1000000))
    }
    
    override func setUp() {
        // NOTE: dataStore uses the same file ("OptEventQueue") by default.
        // Concurrent tests will cause data corruption.
        // Use a unique event file for each test and clean up all at the end
        
        self.eventDispatcher = TestHTTPEventDispatcher()
        self.eventProcessor = TestEventProcessor(eventDispatcher: eventDispatcher, eventFileName: uniqueFileName)

        // for debug level setting
        OptimizelyClient.clearRegistryService()
        _ = OptimizelyClient(sdkKey: kSdkKey,
                             eventProcessor: eventProcessor,
                             defaultLogLevel: .debug)
        
        // clear static states to test first datafile load
        ProjectConfig.observer.reset()
    }
    
    override func tearDown() {
        // make sure timer off at the of each test to avoid interference
        
        self.eventProcessor.timer.performAtomic { $0.invalidate() }
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

extension EventProcessorTests_Batch {
    
    func testInitialization() {
        let expBatchSize = 12
        let expTimerInterval = 35.0
        let expMaxQueueSize = 123
        
        let ep = BatchEventProcessor(batchSize: expBatchSize, timerInterval: expTimerInterval, maxQueueSize: expMaxQueueSize)
        
        XCTAssertEqual(ep.batchSize, expBatchSize)
        XCTAssertEqual(ep.timerInterval, expTimerInterval)
        XCTAssertEqual(ep.maxQueueSize, expMaxQueueSize)
    }

    func testBatchEnabledByDefault() {
        
        // batch allowed by default
        
        var ep = BatchEventProcessor()

        let defaultBatchSize = ep.batchSize
        let defaultTimeInterval = ep.timerInterval
        let defaultMaxQueueSize = ep.maxQueueSize

        XCTAssert(defaultBatchSize > 1)
        XCTAssert(defaultTimeInterval > 1)
        XCTAssert(defaultMaxQueueSize > 100)

        // invalid batchSize falls back to default value
        // (timerInterval = 0 is a valid value, meaning no batch)
        // invalid timeInterval tested in "testEventDispatchedOnTimer_ZeroInterval" below

        ep = BatchEventProcessor(batchSize: 0, timerInterval: -1, maxQueueSize: 0)
        XCTAssertEqual(ep.batchSize, defaultBatchSize)
        XCTAssertEqual(ep.timerInterval, defaultTimeInterval)
        XCTAssertEqual(ep.maxQueueSize, defaultMaxQueueSize)
    }
    
}

// MARK: - Batch

extension EventProcessorTests_Batch {
    
    func testEmptyEventBatch() {
        let events = [EventForDispatch]()
        let (num, batch) = events.batch()
        XCTAssertEqual(num, 0)
        XCTAssertNil(batch)
    }
    
    func testSingleEventBatch() {
        let event = makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA)
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
        let validEvent = makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA)
        let events = [invalidEvent, validEvent, validEvent]
        let (numEvents, batchEvent) = events.batch()
        
        // invalid event at the header returns a nil event (SDK discards this locally)
        
        XCTAssertEqual(numEvents, 1)
        XCTAssertNil(batchEvent)
    }

    func testInvalidEventInSecond() {
        let invalidEvent = makeInvalidEventForDispatchWithWrongData()
        let validEvent = makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA)
        let events = [validEvent, invalidEvent, validEvent]
        let (numEvents, batchEvent) = events.batch()
        
        XCTAssertEqual(numEvents, 1)
        XCTAssertEqual(batchEvent, validEvent)
    }

    func testBatchingEvents() {
        let events: [EventForDispatch] = [
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventB),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventB),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA)
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
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventB),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventC),
            makeEventForDispatch(url: kUrlB, sdkKey: kSdkKey, event: batchEventA)
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
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventB),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventC),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: makeTestBatchEvent(projectId: "99999", visitor: visitorA))
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
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventA),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventB),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: batchEventC),
            makeEventForDispatch(url: kUrlA, sdkKey: kSdkKey, event: makeTestBatchEvent(revision: "99999", visitor: visitorA))
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
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        eventProcessor.maxQueueSize = 100
        
        // illegal config batchSize cannot be bigger than maxQueueSize. just for testing
        eventProcessor.timerInterval = 10000.0
        eventProcessor.batchSize = 1000
        
        var successCount = 0
        var failureCount = 0
        
        let handler = { (result: OptimizelyResult<Data>) -> Void in
            switch result {
            case .success:
                successCount += 1
            case .failure(let error):
                failureCount += 1
                print("process error callback: \(error)")
            }
        }
        
        for _ in 0..<eventProcessor.maxQueueSize {
            processEvent(userEventA, completionHandler: handler)
        }
        
        // now queue must be full. the following event is expected to drop
        processEvent(userEventB, completionHandler: handler)
        eventProcessor.sync()
        
        // check out if success/failure callbacks called properly
        
        XCTAssertEqual(successCount, eventProcessor.maxQueueSize)
        XCTAssertEqual(failureCount, 1)

        // flush
        
        eventProcessor.clear()

        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "all events should be batched together")
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.visitors.count, eventProcessor.maxQueueSize, "events must be discarded when queue full")
        batchedEvents.visitors.forEach {
            XCTAssertEqual($0.visitorID, kUserIdA)
        }

        XCTAssertEqual(eventProcessor.dataStore.count, 0)
    }
}

// MARK: - FlushEvents

extension EventProcessorTests_Batch {

    func testFlushEvents() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        XCTAssert(eventProcessor.batchSize == 10)
        
        processMultipleEvents([userEventA, userEventB, userEventA])

        eventProcessor.clear()

        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlA)
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
        XCTAssertEqual(eventProcessor.dataStore.count, 0)
        
        XCTAssert(eventProcessor.batchSize == 10)

    }
    
    func testFlushEventsWhenSendEventFailsAndRecovers() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        // (1) error injected - all event send fails
        
        eventDispatcher.forceError = true
        
        processMultipleEvents([userEventA, userEventA])

        eventProcessor.clear()

        let maxFailureCount = 3 + 1   // BatchEventProcessor.maxFailureCount + 1
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, maxFailureCount, "repeated the same request several times before giveup")
        
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors[1], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 2)
        
        // confirm that repeat-on-failure sends same packets
        for i in 1..<eventDispatcher.sendRequestedEvents.count {
            XCTAssertEqual(eventDispatcher.sendRequestedEvents[i], eventDispatcher.sendRequestedEvents[0])
        }
        
        XCTAssertEqual(eventProcessor.dataStore.count, 2, "all failed to transmit, so should keep all original events")
        
        // (2) error removed - now events sent out successfully
        
        eventDispatcher.forceError = false
        
        // assume flushEvents called again on next timer fire
        eventProcessor.clear()

        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, maxFailureCount + 1, "only one more since succeeded")
        XCTAssertEqual(eventDispatcher.sendRequestedEvents[3], eventDispatcher.sendRequestedEvents[0])
        
        XCTAssertEqual(eventProcessor.dataStore.count, 0, "all expected to get transmitted successfully")
    }

}

// MARK: - FlushEvents on Timer

extension EventProcessorTests_Batch {

    func testEventDispatchedOnTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        eventProcessor.timerInterval = 2
        
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp!.assertForOverFulfill = false   // allow redundant fulfull for testing

        DispatchQueue.global().async {
            self.processEvent(self.userEventA)
            sleep(1)
            self.processEvent(self.userEventA)
            sleep(3)
            self.processEvent(self.userEventA)
        }

        wait(for: [eventDispatcher.exp!], timeout: 10)
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "expection hit on one batch with 2 events")

        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 2, "only first 2 events when timer expires")
    }
    
    func testEventShouldNotBeSentUntilTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        eventProcessor.timerInterval = 99999
        
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        DispatchQueue.global().async {
            self.processMultipleEvents([self.userEventA])
        }
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "events should not be sent until timer fires")
    }
    
    func testEventDispatchedOnTimer_ZeroInterval() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        // zero-interval means that all events are sent out immediately
        eventProcessor.timerInterval = 0

        processEvent(userEventA)
        sleep(1)
        processEvent(userEventB)
        sleep(1)
        processEvent(userEventC)

        eventProcessor.sync()
        
        continueAfterFailure = false   // stop on XCTAssertEqual failure instead of array out-of-bound exception
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 3)
        
        var batch = eventDispatcher.sendRequestedEvents[0]
        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        batch = eventDispatcher.sendRequestedEvents[1]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlB)
        XCTAssertEqual(batchedEvents.visitors[0], visitorB)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        batch = eventDispatcher.sendRequestedEvents[2]
        batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlC)
        XCTAssertEqual(batchedEvents.visitors[0], visitorC)
        XCTAssertEqual(batchedEvents.visitors.count, 1)
        
        XCTAssertEqual(eventProcessor.dataStore.count, 0)
    }
    
    func testEventBatchedOnTimer_CheckNoRedundantSend() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        eventProcessor.timerInterval = 3

        eventDispatcher.exp = expectation(description: "timer")

        processMultipleEvents([userEventA, userEventB])

        // wait for the 1st batched event transmitted successfully
        wait(for: [eventDispatcher.exp!], timeout: 10)

        // wait more for multiple timer fires to make sure there is no redandant sent out
        waitAsyncSeconds(5)

        // check if we have only one batched event transmitted
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)

        XCTAssertEqual(eventProcessor.dataStore.count, 0, "all expected to get transmitted successfully")
    }

    func testEventBatchedAndErrorRecoveredOnTimer() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        eventProcessor.timerInterval = 5
        
        // (1) inject error
        
        eventDispatcher.forceError = true
        eventDispatcher.exp = expectation(description: "timer")
        eventDispatcher.exp?.assertForOverFulfill = false
        
        processMultipleEvents([userEventA, userEventB])

        // wait for the first timer-fire
        wait(for: [eventDispatcher.exp!], timeout: 10)
        // tranmission is expected to fail
        XCTAssertEqual(eventProcessor.dataStore.count, 2, "all failed to transmit, so should keep all original events")
        
        // (2) remove error. check if events are transmitted successfully on next timer-fire
        sleep(3)   // wait all failure-retries (3 times) completed
        eventDispatcher.forceError = false
        eventDispatcher.exp = expectation(description: "timer")
        
        // wait for the next timer-fire
        wait(for: [eventDispatcher.exp!], timeout: 10)
        
        XCTAssertEqual(eventProcessor.dataStore.count, 0, "all expected to get transmitted successfully")
    }
}

// MARK: - FlushEvents other than timer

extension EventProcessorTests_Batch {
    
    func testEventsFlushedOnEventQueueSizeHit() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        eventProcessor.batchSize = 3
        eventProcessor.timerInterval = 99999   // timer is big, won't fire
        
        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        processMultipleEvents([userEventA, userEventA])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) add one more event, so batchSize hits and flushed
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")

        processMultipleEvents([userEventA])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on batchSize hit")
    }
    
    func testEventsFlushedOnRevisionChange() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        self.eventProcessor = TestEventProcessor(eventDispatcher: eventDispatcher,
                                                 eventFileName: uniqueFileName,
                                                 removeDatafileObserver: false)

        eventProcessor.batchSize = 1000        // big, won't flush
        eventProcessor.timerInterval = 99999   // timer is big, won't fire
        
        let optimizely = OptimizelyClient(sdkKey: kSdkKey,
                                          eventProcessor: eventProcessor,
                                          defaultLogLevel: .debug)
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        processMultipleEvents([userEventA, userEventA])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) flush on revision-change notification
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        
        // change revision
        datafile = OTUtils.loadJSONDatafile("empty_datafile_new_revision")!
        optimizely.config = try! ProjectConfig(datafile: datafile, sdkKey: kSdkKey)
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on the revision change")
    }
    
    func testEventsFlushedOnProjectIdChange() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        self.eventProcessor = TestEventProcessor(eventDispatcher: eventDispatcher,
                                                 eventFileName: uniqueFileName,
                                                 removeDatafileObserver: false)

        eventProcessor.batchSize = 1000        // big, won't flush
        eventProcessor.timerInterval = 99999   // timer is big, won't fire
        
        let optimizely = OptimizelyClient(sdkKey: kSdkKey,
                                          eventProcessor: eventProcessor,
                                          defaultLogLevel: .debug)
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        processMultipleEvents([userEventA, userEventA])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) flush on revision-change notification
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        
        // change projectId
        datafile = OTUtils.loadJSONDatafile("empty_datafile_new_project_id")!
        optimizely.config = try! ProjectConfig(datafile: datafile, sdkKey: kSdkKey)

        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on the projectId change")
    }
    
    func testEventsNotFlushedOnOtherDatafileChanges() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        self.eventProcessor = TestEventProcessor(eventDispatcher: eventDispatcher,
                                                 eventFileName: uniqueFileName,
                                                 removeDatafileObserver: false)

        eventProcessor.batchSize = 1000        // big, won't flush
        eventProcessor.timerInterval = 99999   // timer is big, won't fire
        
        let optimizely = OptimizelyClient(sdkKey: kSdkKey,
                                          eventProcessor: eventProcessor,
                                          defaultLogLevel: .debug)
        var datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)
        
        // (1) not enough events to be flushed yet
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        processMultipleEvents([userEventA, userEventA])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) not flush on other datafile contents change
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true

        // change accountId (not projectId or revision)
        datafile = OTUtils.loadJSONDatafile("empty_datafile_new_account_id")!
        optimizely.config = try! ProjectConfig(datafile: datafile, sdkKey: kSdkKey)
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush on any other changes")
    }
    
    func testEventsNotFlushedOnFirstDatafileLoad() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }

        self.eventProcessor = TestEventProcessor(eventDispatcher: eventDispatcher,
                                                 eventFileName: uniqueFileName,
                                                 removeDatafileObserver: false)

        eventProcessor.batchSize = 1000        // big, won't flush
        eventProcessor.timerInterval = 99999   // timer is big, won't fire
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        // old events queued before SDK starts
        
        processMultipleEvents([userEventA, userEventA])
        
        // first datafile load

        let optimizely = OptimizelyClient(sdkKey: kSdkKey,
                                          eventProcessor: eventProcessor,
                                          defaultLogLevel: .debug)
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush on the first datafile load")
    }
}

// MARK: - LogEvent Notification

extension EventProcessorTests_Batch {

    func testLogEventNotificationCalledBeforeBatchSent() {
        eventProcessor.timerInterval = 0   // no batch

        let optimizely = OptimizelyClient(sdkKey: kSdkKey,
                                          eventProcessor: eventProcessor,
                                          defaultLogLevel: .debug)
        
        var notifEvent: [String: Any]?
        
        _ = optimizely.notificationCenter!.addLogEventNotificationListener { (url, event) in
            print("LogEvent Notification called")
            notifEvent = event
        }
        
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)
        
        processMultipleEvents([userEventA])
        eventProcessor.sync()
                
        // check event contents
        
        if let event = notifEvent, let client = event["client_name"] as? String {
            XCTAssertEqual(client, "swift-sdk")
        } else {
            XCTAssert(false)
        }
    }
    
}

// MARK: - iOS9 Devices

extension EventProcessorTests_Batch {
    
    func testFlushEventsForIOS9Only() {
        // this tests iOS9 (no-timer)
        if #available(iOS 10.0, tvOS 10.0, *) { return }
        
        processMultipleEvents([userEventA])

        eventProcessor.sync()
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(batchedEvents.accountID, kAccountId)
        XCTAssertEqual(batchedEvents.projectID, kProjectIdA)
        XCTAssertEqual(batchedEvents.clientVersion, kClientVersion)
        XCTAssertEqual(batchedEvents.clientName, kClientName)
        XCTAssertEqual(batchedEvents.anonymizeIP, kAnonymizeIP)
        XCTAssertEqual(batchedEvents.enrichDecisions, kEnrichDecision)
        XCTAssertEqual(batchedEvents.visitors[0], visitorA)
        XCTAssertEqual(eventProcessor.dataStore.count, 0)
    }
    
    func testFlushEventsForIOS9Only_ZeroInterval() {
        // this tests iOS9 (no-timer)
        if #available(iOS 10.0, tvOS 10.0, *) { return }
        
        eventProcessor.timerInterval = 0
        
        processMultipleEvents([userEventA])
        eventProcessor.sync()
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1)
        let batch = eventDispatcher.sendRequestedEvents[0]
        let batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        //XCTAssertEqual(batch.url.absoluteString, kUrlA)
        XCTAssertEqual(batchedEvents.revision, kRevisionA)
        XCTAssertEqual(eventProcessor.dataStore.count, 0)
    }
    
}

// MARK: - OptimizleyClient: Close()

extension EventProcessorTests_Batch {
    
    func testCloseForOptimizleyClient() {
        // this tests timer-based dispatch, available for iOS 10+
        guard #available(iOS 10.0, tvOS 10.0, *) else { return }
        
        self.eventProcessor = TestEventProcessor(eventDispatcher: eventDispatcher,
                                                 eventFileName: uniqueFileName,
                                                 removeDatafileObserver: false)
        
        eventProcessor.batchSize = 1000        // big, won't flush
        eventProcessor.timerInterval = 99999   // timer is big, won't fire
        
        // clean
        OptimizelyClient.clearRegistryService()
        let optimizely = OptimizelyClient(sdkKey: kSdkKey,
                                          eventProcessor: eventProcessor,
                                          defaultLogLevel: .debug)
        
        // (1) should have no flush
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        let datafile = OTUtils.loadJSONDatafile("empty_datafile")!
        try! optimizely.start(datafile: datafile)

        processMultipleEvents([userEventA, userEventA, userEventA])
        
        wait(for: [eventDispatcher.exp!], timeout: 3)
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 0, "should not flush yet")
        
        // (2) should flush/batch all on close()
        
        optimizely.close()
        
        XCTAssertEqual(eventDispatcher.sendRequestedEvents.count, 1, "should flush on close")
        var batch = eventDispatcher.sendRequestedEvents[0]
        var batchedEvents = try! JSONDecoder().decode(BatchEvent.self, from: batch.body)
        XCTAssertEqual(batchedEvents.visitors.count, 3)
        eventDispatcher.sendRequestedEvents.removeAll()

        // (3) should have no flush
        
        eventDispatcher.exp = XCTestExpectation(description: "timer")
        eventDispatcher.exp?.isInverted = true
        
        try! optimizely.start(datafile: datafile)
        
        processMultipleEvents([userEventB, userEventA])
        
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

extension EventProcessorTests_Batch {
    
    func testRandomEvents_10() {
        runRandomEventsTest(numEvents: 9, eventProcessor: eventProcessor, tc: self)
    }
    
    func testRandomEvents_100() {
        runRandomEventsTest(numEvents: 111, eventProcessor: eventProcessor, tc: self, numInvalidEvents: 0)
    }
    
    func testRandomEventsWithInvalid_100() {
        runRandomEventsTest(numEvents: 111, eventProcessor: eventProcessor, tc: self, numInvalidEvents: 10)
    }

    // Utils
    
    func runRandomEventsTest(numEvents: Int, eventProcessor: TestEventProcessor, tc: XCTestCase, numInvalidEvents: Int=0) {
        eventProcessor.batchSize = Int.random(in: 1..<10)
        eventProcessor.timerInterval = Double(Int.random(in: 1..<3))
        
        print("[RandomTest] configuration: (batchSize, timeInterval) = (\(eventProcessor.batchSize), \(eventProcessor.timerInterval))")

        let exp = XCTestExpectation(description: "random")
        let expectedVisistors = numEvents - numInvalidEvents  // all invalid events will be discarded

        // dispatch evetns in a separate thread for stressting enqueue and batch happen simultaneously
        DispatchQueue.global().async {
            self.dispatchRandomEvents(numEvents: numEvents, numInvalidEvents: numInvalidEvents)
            
            print("[RandomTest] dispatched all events")
            
            // extra delay to make sure all events are flushed and check if no more than expected is batched
            let extraDelay = max(Int(eventProcessor.timerInterval) * 2, 60)
            var delay = 0
            while delay < extraDelay {
                if self.eventDispatcher.numReceivedVisitors >= expectedVisistors {
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
        let projectIdPool = [kProjectIdA]
        let revisionPool = [kRevisionA, kRevisionA, kRevisionA, kRevisionA, kRevisionB]
        let userPool = [kUserIdA, kUserIdB, kUserIdC]
        
        var posForInvalid = Set<Int>()
        while posForInvalid.count < numInvalidEvents {
            posForInvalid.insert(Int.random(in: 0..<numEvents))
        }
        
        for i in 0..<numEvents {
            // insert invalid event randomly
            if posForInvalid.contains(i) {
                // TODO: fix testing for invalid events
                // - cannot inject errors at this level. drop them for now.
                //        processEvent(batchEventInvalid)
                
                print("[RandomTest][\(i)] dispatch an invalid event")
                continue
            }
                        
            let projectId = projectIdPool.randomElement()
            let revision = revisionPool.randomElement()
            let userId = userPool.randomElement()
            let event = makeTestUserEvent(userId: userId!, projectId: projectId, revision: revision)
            print("[RandomTest][\(i)] dispatch event: revision = \(revision!)")
            
            processEvent(event)
            waitAsyncMilliseconds(Int.random(in: 0..<100))  // random delays between event dispatches
        }
    }
}

// MARK: - Utils

extension EventProcessorTests_Batch {
    
    func makeEventForDispatch(url: String, sdkKey: String, event: BatchEvent) -> EventForDispatch {
        let data = try! JSONEncoder().encode(event)
        return EventForDispatch(url: URL(string: url), sdkKey: sdkKey, body: data)
    }
    
    func makeInvalidEventForDispatchWithNilUrl() -> EventForDispatch {
        let data = try! JSONEncoder().encode(batchEventA)
        return EventForDispatch(url: nil, sdkKey: kSdkKey, body: data)
    }
    
    func makeInvalidEventForDispatchWithWrongData() -> EventForDispatch {
        return EventForDispatch(url: URL(string: kUrlA), sdkKey: kSdkKey, body: Data())
    }
    
    // UserEvent
    
    var kConfigA: ProjectConfig {
        return makeEmptyConfig(projectId: kProjectIdA, revision: kRevisionA)
    }
    var kConfigB: ProjectConfig {
        return makeEmptyConfig(projectId: kProjectIdB, revision: kRevisionB)
    }
    var kConfigC: ProjectConfig {
        return makeEmptyConfig(projectId: kProjectIdC, revision: kRevisionC)
    }
    
    func makeEmptyConfig(projectId: String, revision: String) -> ProjectConfig {
        let data = OTUtils.loadJSONDatafile("empty_datafile")!
        let config = try! ProjectConfig(datafile: data, sdkKey: kSdkKey)
        config.project.projectId = kProjectIdA
        config.project.revision = kRevisionA
        return config
    }

    struct DummyEvent: UserEvent {
        var userContext: UserContext
        var accountId: String
        var clientName: String
        var clientVersion: String
        var anonymizeIP: Bool
        
        var batchEvent: BatchEvent {
            let visitor = Visitor(attributes: [], snapshots: [], visitorID: userContext.userId)

            return BatchEvent(revision: userContext.config.project.revision,
                              accountID: accountId,
                              clientVersion: clientVersion,
                              visitors: [visitor],
                              projectID: userContext.config.project.projectId,
                              clientName: clientName,
                              anonymizeIP: anonymizeIP,
                              enrichDecisions: true)
        }
        
        init(userContext: UserContext, accountId: String, clientName: String, clientVersion: String, anonymizeIP: Bool) {
            self.userContext = userContext
            self.accountId = accountId
            self.clientName = clientName
            self.clientVersion = clientVersion
            self.anonymizeIP = anonymizeIP
        }
    }
    
    func makeTestUserEvent(userId: String, projectId: String?=nil, revision: String?=nil) -> UserEvent {
        let testProjectId = projectId ?? kProjectIdA
        let testRevision = revision ?? kRevisionA
        
        let userContext = UserContext(config: makeEmptyConfig(projectId: testProjectId, revision: testRevision),
                                      userId: userId,
                                      attributes: nil)
        return DummyEvent(userContext: userContext, accountId: kAccountId, clientName: kClientName, clientVersion: kClientVersion, anonymizeIP: kAnonymizeIP)
    }
    
    var userEventA: UserEvent {
        return makeTestUserEvent(userId: kUserIdA)
    }
    
    var userEventB: UserEvent {
        return makeTestUserEvent(userId: kUserIdB)
    }

    var userEventC: UserEvent {
        return makeTestUserEvent(userId: kUserIdC)
    }
    
    // BatchEvent
    
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
    
    var batchEventInvalid: BatchEvent {
        return BatchEvent(revision: kRevisionA, accountID: kAccountId, clientVersion: kClientVersion, visitors: [],
                          projectID: kProjectIdA, clientName: kClientName, anonymizeIP: kAnonymizeIP, enrichDecisions: kEnrichDecision)
    }

    var visitorA: Visitor {
        return Visitor(attributes: [],
                       snapshots: [],
                       visitorID: kUserIdA)
    }
    
    func processEvent(_ event: UserEvent, completionHandler: DispatchCompletionHandler? = nil) {
        processMultipleEvents([event], completionHandler: completionHandler)
    }

    func processMultipleEvents(_ events: [UserEvent], completionHandler: DispatchCompletionHandler? = nil) {
        events.forEach {
            eventProcessor.process(event: $0, completionHandler: completionHandler)
        }
        eventProcessor.sync()
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

// MARK: - Fake EventProcessor

class TestHTTPEventDispatcher: HTTPEventDispatcher {
    var sendRequestedEvents: [EventForDispatch] = []
    var forceError = false
    var numReceivedVisitors = 0

    // set this if need to wait sendEvent completed
    var exp: XCTestExpectation?
    
    override func dispatch(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        sendRequestedEvents.append(event)
        
        do {
            let decodedEvent = try JSONDecoder().decode(BatchEvent.self, from: event.body)
            numReceivedVisitors += decodedEvent.visitors.count
            print("[TestEventProcessor][SendEvent] Received a batched event with visistors: \(decodedEvent.visitors.count) \(numReceivedVisitors)")
        } catch {
            // invalid event format detected
            // - invalid events are supposed to be filtered out when batching (converting to nil, so silently dropped)
            // - an exeption is that an invalid event is alone in the queue, when validation is skipped for performance on common path
            
            // pass through invalid events, so server can filter them out
        }

        // must call completionHandler to complete synchronization
        super.dispatch(event: event) { _ in
            if self.forceError {
                completionHandler?(.failure(.eventDispatchFailed("forced")))
            } else {
                // return success to clear store after sending events
                completionHandler?(.success(Data()))
            }

            self.exp?.fulfill()
        }
    }
    
}

class TestEventProcessor: BatchEventProcessor {
    let eventFileName: String
    
    init(eventDispatcher: OPTEventsDispatcher, eventFileName: String, removeDatafileObserver: Bool = true) {
        self.eventFileName = eventFileName
        
        super.init(eventDispatcher: eventDispatcher, dataStoreName: eventFileName)
        
        print("[TestEventProcessor] init with [\(eventFileName)] ")

        // block interference from other tests notifications when testing batch timing
        if removeDatafileObserver {
            removeProjectChangeNotificationObservers()
        }
    }
    
    override func process(event: UserEvent, completionHandler: DispatchCompletionHandler?) {
        super.process(event: event, completionHandler: completionHandler)
    }
    
}
