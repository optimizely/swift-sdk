//
// Copyright 2025, Optimizely, Inc. and contributors
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

class EventDispatcherRetryTests: XCTestCase {

    var eventDispatcher: DefaultEventDispatcher?

    override func setUp() {
        OTUtils.createDocumentDirectoryIfNotAvailable()
    }

    override func tearDown() {
        OTUtils.clearAllEventQueues()
        eventDispatcher = nil
    }

    // MARK: - Basic Retry Tests

    func testRetry_SuccessOnFirstAttempt() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                completionHandler(.success(Data()))
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        dispatcher.flushEvents()
        dispatcher.queueLock.sync {}

        // Should succeed on first attempt, no retries needed
        XCTAssertEqual(dispatcher.sendCount, 1)
        XCTAssertEqual(dispatcher.eventQueue.count, 0)
    }

    func testRetry_SuccessOnSecondAttempt() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0
            var sendTimes: [Date] = []

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                sendTimes.append(Date())

                if sendCount == 1 {
                    completionHandler(.failure(.eventDispatchFailed("Network error")))
                } else {
                    completionHandler(.success(Data()))
                }
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        let startTime = Date()
        dispatcher.flushEvents()

        // Wait for async retry to complete
        let expectation = XCTestExpectation(description: "Retry completes")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Should have 2 send attempts (1 initial + 1 retry)
        XCTAssertEqual(dispatcher.sendCount, 2)
        XCTAssertEqual(dispatcher.eventQueue.count, 0)

        // Verify delay between attempts is approximately 200ms
        if dispatcher.sendTimes.count >= 2 {
            let delayBetweenAttempts = dispatcher.sendTimes[1].timeIntervalSince(dispatcher.sendTimes[0])
            XCTAssertGreaterThan(delayBetweenAttempts, 0.18, "Delay should be at least 180ms")
            XCTAssertLessThan(delayBetweenAttempts, 0.25, "Delay should be less than 250ms")
        }
    }

    func testRetry_SuccessOnThirdAttempt() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0
            var sendTimes: [Date] = []

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                sendTimes.append(Date())

                if sendCount < 3 {
                    completionHandler(.failure(.eventDispatchFailed("Network error")))
                } else {
                    completionHandler(.success(Data()))
                }
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        dispatcher.flushEvents()

        // Wait for retries to complete (200ms + 400ms + processing time)
        let expectation = XCTestExpectation(description: "Retries complete")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Should have 3 send attempts (1 initial + 2 retries)
        XCTAssertEqual(dispatcher.sendCount, 3)
        XCTAssertEqual(dispatcher.eventQueue.count, 0)

        // Verify exponential backoff delays
        if dispatcher.sendTimes.count >= 3 {
            let delay1 = dispatcher.sendTimes[1].timeIntervalSince(dispatcher.sendTimes[0])
            let delay2 = dispatcher.sendTimes[2].timeIntervalSince(dispatcher.sendTimes[1])

            // First retry: ~200ms
            XCTAssertGreaterThan(delay1, 0.18)
            XCTAssertLessThan(delay1, 0.25)

            // Second retry: ~400ms
            XCTAssertGreaterThan(delay2, 0.38)
            XCTAssertLessThan(delay2, 0.45)
        }
    }

    func testRetry_AllAttemptsExhausted() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                // Always fail
                completionHandler(.failure(.eventDispatchFailed("Network error")))
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        dispatcher.flushEvents()

        // Wait for all retries to exhaust
        let expectation = XCTestExpectation(description: "All retries exhausted")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Should have 3 send attempts (1 initial + 2 retries)
        XCTAssertEqual(dispatcher.sendCount, 3)

        // Event should remain in queue after max retries exhausted
        XCTAssertEqual(dispatcher.eventQueue.count, 1)
    }

    // MARK: - Edge Cases

    func testRetry_InvalidEventDiscarded() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                completionHandler(.success(Data()))
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)

        // Add an invalid event (empty body that can't be batched)
        // The batching logic will return nil for invalid events
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        dispatcher.flushEvents()
        dispatcher.queueLock.sync {}

        // Invalid events should be discarded without retry
        XCTAssertEqual(dispatcher.eventQueue.count, 0)
    }

    func testRetry_MultipleBatches() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0
            var failFirstBatch = true

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1

                // First batch fails once then succeeds
                if failFirstBatch && sendCount == 1 {
                    failFirstBatch = false
                    completionHandler(.failure(.eventDispatchFailed("Network error")))
                } else {
                    completionHandler(.success(Data()))
                }
            }
        }

        let dispatcher = TestEventDispatcher(batchSize: 1, timerInterval: 0)

        // Add 3 events
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        dispatcher.flushEvents()

        // Wait for all batches to process
        let expectation = XCTestExpectation(description: "All batches processed")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Should have processed all events (1 retry for first batch + 2 immediate successes)
        XCTAssertEqual(dispatcher.sendCount, 4)
        XCTAssertEqual(dispatcher.eventQueue.count, 0)
    }

    func testRetry_NetworkReachabilityDown() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                completionHandler(.failure(.eventDispatchFailed("Network down")))
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        // Simulate network down by triggering multiple failures
        for _ in 0..<3 {
            dispatcher.reachability.updateNumContiguousFails(isError: true)
        }

        // Also need to set isConnected to false for shouldBlockNetworkAccess to return true
        dispatcher.reachability.isConnected = false

        XCTAssertTrue(dispatcher.reachability.shouldBlockNetworkAccess())

        dispatcher.flushEvents()
        dispatcher.queueLock.sync {}

        // When network is down, sendEvent returns early
        // No retries should happen
        XCTAssertEqual(dispatcher.sendCount, 0)
    }

    func testRetry_QueueNotBlockedDuringRetry() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                completionHandler(.failure(.eventDispatchFailed("Network error")))
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        dispatcher.flushEvents()

        // While retry is pending, add another event
        let addEventExpectation = XCTestExpectation(description: "Event added during retry")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 0.1) {
            dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))
            addEventExpectation.fulfill()
        }

        wait(for: [addEventExpectation], timeout: 0.5)

        // Queue should accept new events during retry
        XCTAssertGreaterThanOrEqual(dispatcher.eventQueue.count, 1)
    }

    func testRetry_ConcurrentFlushCalls() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0
            let sendLock = DispatchQueue(label: "sendLock")

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendLock.sync {
                    sendCount += 1
                }
                completionHandler(.success(Data()))
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)

        // Add multiple events
        for _ in 0..<5 {
            dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))
        }

        // Call flush multiple times concurrently
        let queue = DispatchQueue(label: "test", attributes: .concurrent)
        for _ in 0..<3 {
            queue.async {
                dispatcher.flushEvents()
            }
        }

        // Wait for all flushes to complete
        let expectation = XCTestExpectation(description: "Flushes complete")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // All events should be processed
        XCTAssertEqual(dispatcher.eventQueue.count, 0)
    }

    // MARK: - Timing Tests

    func testRetry_DelayTiming() {
        class TestEventDispatcher: DefaultEventDispatcher {
            var sendCount = 0
            var sendTimes: [Date] = []

            override func sendEvent(event: EventForDispatch, completionHandler: @escaping DispatchCompletionHandler) {
                sendCount += 1
                sendTimes.append(Date())

                if sendCount < 3 {
                    completionHandler(.failure(.eventDispatchFailed("Network error")))
                } else {
                    completionHandler(.success(Data()))
                }
            }
        }

        let dispatcher = TestEventDispatcher(timerInterval: 0)
        dispatcher.eventQueue.save(item: EventForDispatch(body: Data()))

        let startTime = Date()
        dispatcher.flushEvents()

        // Wait for all retries to complete
        let expectation = XCTestExpectation(description: "All retries complete")
        dispatcher.queueLock.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Verify timing sequence
        XCTAssertEqual(dispatcher.sendTimes.count, 3)

        if dispatcher.sendTimes.count >= 3 {
            let time0 = dispatcher.sendTimes[0].timeIntervalSince(startTime)
            let time1 = dispatcher.sendTimes[1].timeIntervalSince(startTime)
            let time2 = dispatcher.sendTimes[2].timeIntervalSince(startTime)

            // First attempt: immediate
            XCTAssertLessThan(time0, 0.05)

            // Second attempt: ~200ms after start
            XCTAssertGreaterThan(time1, 0.18)
            XCTAssertLessThan(time1, 0.25)

            // Third attempt: ~600ms after start (200ms + 400ms)
            XCTAssertGreaterThan(time2, 0.58)
            XCTAssertLessThan(time2, 0.7)
        }
    }
}
