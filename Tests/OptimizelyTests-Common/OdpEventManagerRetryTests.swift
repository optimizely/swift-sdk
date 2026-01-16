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

class OdpEventManagerRetryTests: XCTestCase {
    var manager: OdpEventManager!
    var apiManager: MockOdpEventApiManager!
    var odpConfig: OdpConfig!

    override func setUp() {
        OTUtils.clearAllEventQueues()
        OTUtils.createDocumentDirectoryIfNotAvailable()

        odpConfig = OdpConfig()

        apiManager = MockOdpEventApiManager()
        manager = OdpEventManager(sdkKey: "test-sdk-key", apiManager: apiManager)
        manager.odpConfig = odpConfig
    }

    override func tearDown() {
        OTUtils.clearAllEventQueues()
        manager = nil
        apiManager = nil
    }

    /// Wait for all flush operations to complete
    func waitForFlush() {
        // Ensure flush async block has started
        manager.queueLock.sync {}
        // Wait for the flush to complete
        _ = manager.notify.wait(timeout: .now() + 10.0)
    }

    // MARK: - Basic Retry Tests

    func testRetry_RecoverableError_SuccessOnFirstAttempt() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to succeed immediately
        apiManager.shouldFail = false

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for flush to complete
        waitForFlush()

        // Should succeed on first attempt
        XCTAssertEqual(apiManager.sendCount, 1)
        XCTAssertEqual(manager.eventQueue.count, 0)
        XCTAssertEqual(apiManager.dispatchedBatchEvents.count, 1)
    }

    func testRetry_RecoverableError_SuccessAfterRetry() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to fail once then succeed
        apiManager.failCount = 1
        apiManager.shouldFail = true
        apiManager.recoverable = true

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for retry to complete (200ms delay + processing)
        waitForFlush()

        // Should have 2 attempts (1 initial + 1 retry)
        XCTAssertEqual(apiManager.sendCount, 2)
        XCTAssertEqual(manager.eventQueue.count, 0)
        XCTAssertEqual(apiManager.dispatchedBatchEvents.count, 2)

        // Verify delay timing
        if apiManager.sendTimes.count >= 2 {
            let delay = apiManager.sendTimes[1].timeIntervalSince(apiManager.sendTimes[0])
            XCTAssertGreaterThan(delay, 0.18, "Delay should be at least 180ms")
            XCTAssertLessThan(delay, 0.25, "Delay should be less than 250ms")
        }
    }

    func testRetry_RecoverableError_SuccessAfterTwoRetries() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to fail twice then succeed
        apiManager.failCount = 2
        apiManager.shouldFail = true
        apiManager.recoverable = true

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for retries to complete (200ms + 400ms + processing)
        waitForFlush()

        // Should have 3 attempts (1 initial + 2 retries)
        XCTAssertEqual(apiManager.sendCount, 3)
        XCTAssertEqual(manager.eventQueue.count, 0)

        // Verify exponential backoff delays
        if apiManager.sendTimes.count >= 3 {
            let delay1 = apiManager.sendTimes[1].timeIntervalSince(apiManager.sendTimes[0])
            let delay2 = apiManager.sendTimes[2].timeIntervalSince(apiManager.sendTimes[1])

            // First retry: ~200ms
            XCTAssertGreaterThan(delay1, 0.18)
            XCTAssertLessThan(delay1, 0.25)

            // Second retry: ~400ms
            XCTAssertGreaterThan(delay2, 0.38)
            XCTAssertLessThan(delay2, 0.45)
        }
    }

    func testRetry_RecoverableError_AllAttemptsExhausted() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to always fail with recoverable error
        apiManager.failCount = 10  // More than max retries
        apiManager.shouldFail = true
        apiManager.recoverable = true

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for all retries to exhaust
        waitForFlush()

        // With async implementation, we try 3 times (1 initial + 2 retries)
        // The circuit breaker stops after 3 consecutive failures.
        XCTAssertEqual(apiManager.sendCount, 3)

        // Event should remain in queue after global failure count exhausted
        XCTAssertEqual(manager.eventQueue.count, 1)
    }

    func testRetry_NonRecoverableError_NoRetry() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to fail with non-recoverable error (4xx)
        apiManager.shouldFail = true
        apiManager.recoverable = false

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for processing
        waitForFlush()

        // Should only have 1 attempt, no retries
        XCTAssertEqual(apiManager.sendCount, 1)

        // Event should be removed (non-recoverable error)
        XCTAssertEqual(manager.eventQueue.count, 0)
    }

    // MARK: - Edge Cases

    func testRetry_MultipleBatches() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Set maxBatchEvents to 1 to make each event a separate batch
        manager.maxBatchEvents = 1

        // First batch fails once then succeeds
        apiManager.failCount = 1
        apiManager.shouldFail = true
        apiManager.recoverable = true
        apiManager.failOnlyFirstBatch = true

        // Add 3 events (each will be a separate batch since maxBatchEvents=1)
        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])
        manager.sendEvent(type: "t2", action: "a2", identifiers: ["id": "2"], data: [:])
        manager.sendEvent(type: "t3", action: "a3", identifiers: ["id": "3"], data: [:])

        // Wait for all batches to process
        waitForFlush()

        // Should process all events: first batch (2 attempts), other batches (1 attempt each) = 4 total
        XCTAssertGreaterThanOrEqual(apiManager.sendCount, 4)
        XCTAssertEqual(manager.eventQueue.count, 0)
    }

    func testRetry_NetworkDown_NoRetry() {
        // Simulate network down
        for _ in 0..<3 {
            manager.reachability.updateNumContiguousFails(isError: true)
        }

        // Also need to set isConnected to false for shouldBlockNetworkAccess to return true
        manager.reachability.isConnected = false

        XCTAssertTrue(manager.reachability.shouldBlockNetworkAccess())

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for processing
        waitForFlush()

        // When network is down, flush should return early
        XCTAssertEqual(apiManager.sendCount, 0)
        XCTAssertEqual(manager.eventQueue.count, 1)
    }

    func testRetry_ConfigNotReady_NoRetry() {
        // Clear ODP config (no API key) and set state to notIntegrated
        // This will set eventQueueingAllowed = false, which triggers queue clearing
        _ = odpConfig.update(apiKey: nil, apiHost: nil, segmentsToCheck: [])

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for processing
        waitForFlush()

        // Should not send when config not ready
        XCTAssertEqual(apiManager.sendCount, 0)
        XCTAssertEqual(manager.eventQueue.count, 0)  // Queue cleared when queueing not allowed
    }

    func testRetry_MaxQueueSize_NoRetry() {
        // Set very small queue size
        manager.maxQueueSize = 1

        apiManager.shouldFail = true
        apiManager.recoverable = true
        apiManager.failCount = 10

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])
        manager.sendEvent(type: "t2", action: "a2", identifiers: ["id": "2"], data: [:])

        // Wait for processing
        waitForFlush()

        // Should only have 1 event in queue (queue full)
        XCTAssertEqual(manager.eventQueue.count, 1)
    }

    func testRetry_MixedSuccessFailure() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Set maxBatchEvents to 1 to make each event a separate batch
        manager.maxBatchEvents = 1

        // Configure: fail first 2 batches, succeed on rest
        apiManager.failCount = 2
        apiManager.shouldFail = true
        apiManager.recoverable = true
        apiManager.resetCountOnSuccess = true

        // Add multiple events
        for i in 1...5 {
            manager.sendEvent(type: "t\(i)", action: "a\(i)", identifiers: ["id": "\(i)"], data: [:])
        }

        // Wait for all to process
        waitForFlush()

        // All events should eventually succeed
        // Batch 1: fail, fail, success (3 attempts)
        // Batch 2: fail, fail, success (3 attempts, counter resets on success)
        // Batches 3-5: success (1 attempt each)
        // Total: 3 + 3 + 1 + 1 + 1 = 9 attempts
        XCTAssertEqual(manager.eventQueue.count, 0)
        XCTAssertGreaterThanOrEqual(apiManager.sendCount, 9)
    }

    func testRetry_EventsRemovedAfterSuccess() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to fail once then succeed
        apiManager.failCount = 1
        apiManager.shouldFail = true
        apiManager.recoverable = true

        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])
        manager.sendEvent(type: "t2", action: "a2", identifiers: ["id": "2"], data: [:])

        // Wait for processing
        waitForFlush()

        // All events should be removed after successful retries
        XCTAssertEqual(manager.eventQueue.count, 0)
    }

    // MARK: - Timing Tests

    func testRetry_DelaySequence() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to fail twice then succeed
        apiManager.failCount = 2
        apiManager.shouldFail = true
        apiManager.recoverable = true

        let startTime = Date()
        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])

        // Wait for all retries
        waitForFlush()

        // Verify timing sequence
        XCTAssertEqual(apiManager.sendCount, 3)

        if apiManager.sendTimes.count >= 3 {
            let time0 = apiManager.sendTimes[0].timeIntervalSince(startTime)
            let time1 = apiManager.sendTimes[1].timeIntervalSince(startTime)
            let time2 = apiManager.sendTimes[2].timeIntervalSince(startTime)

            // First attempt: immediate
            XCTAssertLessThan(time0, 0.1)

            // Second attempt: ~200ms
            XCTAssertGreaterThan(time1, 0.18)
            XCTAssertLessThan(time1, 0.3)

            // Third attempt: ~600ms (200ms + 400ms)
            XCTAssertGreaterThan(time2, 0.58)
            XCTAssertLessThan(time2, 0.75)
        }
    }

    func testRetry_ResetOnSuccess() {
        // Configure ODP
        _ = odpConfig.update(apiKey: "test-api-key", apiHost: "test-api-host", segmentsToCheck: [])

        // Configure to fail once on each batch
        apiManager.failCount = 1
        apiManager.shouldFail = true
        apiManager.recoverable = true
        apiManager.resetCountOnSuccess = true
        apiManager.failOnlyFirstAttempt = true

        // Add multiple events
        manager.sendEvent(type: "t1", action: "a1", identifiers: ["id": "1"], data: [:])
        manager.sendEvent(type: "t2", action: "a2", identifiers: ["id": "2"], data: [:])

        // Wait for processing
        waitForFlush()

        // Each batch should retry once then succeed
        XCTAssertEqual(manager.eventQueue.count, 0)
    }

    // MARK: - Mock API Manager

    class MockOdpEventApiManager: OdpEventApiManager {
        var sendCount = 0
        var sendTimes: [Date] = []
        var dispatchedBatchEvents = [[OdpEvent]]()

        var shouldFail = false
        var recoverable = false
        var failCount = 0
        var currentFailCount = 0
        var failOnlyFirstBatch = false
        var failOnlyFirstAttempt = false
        var resetCountOnSuccess = false

        override func sendOdpEvents(apiKey: String,
                                    apiHost: String,
                                    events: [OdpEvent],
                                    completionHandler: @escaping (OptimizelyError?) -> Void) {
            sendCount += 1
            sendTimes.append(Date())
            dispatchedBatchEvents.append(events)

            DispatchQueue.global().async {
                if self.shouldFail {
                    // Check if should fail this attempt
                    let shouldFailThisAttempt: Bool

                    if self.failOnlyFirstAttempt {
                        shouldFailThisAttempt = (self.sendCount == 1)
                    } else if self.failOnlyFirstBatch {
                        shouldFailThisAttempt = (self.dispatchedBatchEvents.count == 1) && (self.currentFailCount < self.failCount)
                    } else {
                        shouldFailThisAttempt = self.currentFailCount < self.failCount
                    }

                    if shouldFailThisAttempt {
                        self.currentFailCount += 1
                        let error = OptimizelyError.odpEventFailed(
                            self.recoverable ? "Network error" : "403 Forbidden",
                            self.recoverable
                        )
                        completionHandler(error)
                        return
                    }
                }

                // Success
                if self.resetCountOnSuccess {
                    self.currentFailCount = 0
                }
                completionHandler(nil)
            }
        }
    }
}
