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

class RetryStrategyTests: XCTestCase {

    func testDelayCalculation_InitialAttempt() {
        let strategy = RetryStrategy()

        // Attempt 0 should have no delay
        let delay = strategy.delayForRetry(attempt: 0)

        XCTAssertEqual(delay, 0.0, accuracy: 0.001)
    }

    func testDelayCalculation_FirstRetry() {
        let strategy = RetryStrategy()

        // First retry (attempt 1): 0.2 * 2^0 = 0.2s (200ms)
        let delay = strategy.delayForRetry(attempt: 1)

        XCTAssertEqual(delay, 0.2, accuracy: 0.001)
    }

    func testDelayCalculation_SecondRetry() {
        let strategy = RetryStrategy()

        // Second retry (attempt 2): 0.2 * 2^1 = 0.4s (400ms)
        let delay = strategy.delayForRetry(attempt: 2)

        XCTAssertEqual(delay, 0.4, accuracy: 0.001)
    }

    func testDelayCalculation_ThirdRetry() {
        let strategy = RetryStrategy()

        // Third retry (attempt 3): 0.2 * 2^2 = 0.8s (800ms)
        let delay = strategy.delayForRetry(attempt: 3)

        XCTAssertEqual(delay, 0.8, accuracy: 0.001)
    }

    func testDelayCalculation_MaxCapReached() {
        let strategy = RetryStrategy()

        // Fourth retry (attempt 4): 0.2 * 2^3 = 1.6s but capped at 1.0s
        let delay = strategy.delayForRetry(attempt: 4)

        XCTAssertEqual(delay, 1.0, accuracy: 0.001)
    }

    func testDelayCalculation_BeyondMaxCap() {
        let strategy = RetryStrategy()

        // Fifth retry (attempt 5): 0.2 * 2^4 = 3.2s but capped at 1.0s
        let delay = strategy.delayForRetry(attempt: 5)

        XCTAssertEqual(delay, 1.0, accuracy: 0.001)
    }

    func testShouldRetry_WithinLimit() {
        let strategy = RetryStrategy(maxRetries: 2)

        XCTAssertTrue(strategy.shouldRetry(currentAttempt: 0))
        XCTAssertTrue(strategy.shouldRetry(currentAttempt: 1))
        XCTAssertTrue(strategy.shouldRetry(currentAttempt: 2))
    }

    func testShouldRetry_AtLimit() {
        let strategy = RetryStrategy(maxRetries: 2)

        // At maxRetries, should still allow retry
        XCTAssertTrue(strategy.shouldRetry(currentAttempt: 2))
    }

    func testShouldRetry_BeyondLimit() {
        let strategy = RetryStrategy(maxRetries: 2)

        // Beyond maxRetries, should not retry
        XCTAssertFalse(strategy.shouldRetry(currentAttempt: 3))
        XCTAssertFalse(strategy.shouldRetry(currentAttempt: 4))
    }

    func testCustomConfiguration_LowerInitialInterval() {
        let strategy = RetryStrategy(maxRetries: 2, initialInterval: 0.1, maxInterval: 0.5)

        XCTAssertEqual(strategy.delayForRetry(attempt: 1), 0.1, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 2), 0.2, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 3), 0.4, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 4), 0.5, accuracy: 0.001) // capped
    }

    func testCustomConfiguration_HigherMaxInterval() {
        let strategy = RetryStrategy(maxRetries: 5, initialInterval: 0.5, maxInterval: 5.0)

        XCTAssertEqual(strategy.delayForRetry(attempt: 1), 0.5, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 2), 1.0, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 3), 2.0, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 4), 4.0, accuracy: 0.001)
        XCTAssertEqual(strategy.delayForRetry(attempt: 5), 5.0, accuracy: 0.001) // capped
    }

    func testExponentialGrowthFormula() {
        let strategy = RetryStrategy(maxRetries: 10, initialInterval: 1.0, maxInterval: 100.0)

        // Verify exponential growth: delay = initialInterval * 2^(attempt-1)
        XCTAssertEqual(strategy.delayForRetry(attempt: 1), 1.0, accuracy: 0.001)   // 1 * 2^0
        XCTAssertEqual(strategy.delayForRetry(attempt: 2), 2.0, accuracy: 0.001)   // 1 * 2^1
        XCTAssertEqual(strategy.delayForRetry(attempt: 3), 4.0, accuracy: 0.001)   // 1 * 2^2
        XCTAssertEqual(strategy.delayForRetry(attempt: 4), 8.0, accuracy: 0.001)   // 1 * 2^3
        XCTAssertEqual(strategy.delayForRetry(attempt: 5), 16.0, accuracy: 0.001)  // 1 * 2^4
        XCTAssertEqual(strategy.delayForRetry(attempt: 6), 32.0, accuracy: 0.001)  // 1 * 2^5
        XCTAssertEqual(strategy.delayForRetry(attempt: 7), 64.0, accuracy: 0.001)  // 1 * 2^6
        XCTAssertEqual(strategy.delayForRetry(attempt: 8), 100.0, accuracy: 0.001) // capped
    }

    func testDefaultValues() {
        let strategy = RetryStrategy()

        // Verify default configuration
        XCTAssertEqual(strategy.maxRetries, 2)
        XCTAssertEqual(strategy.initialInterval, 0.2, accuracy: 0.001)
        XCTAssertEqual(strategy.maxInterval, 1.0, accuracy: 0.001)
    }

    func testZeroAttemptHasNoDelay() {
        let strategy = RetryStrategy()

        // Attempt 0 (initial try) should never have a delay
        XCTAssertEqual(strategy.delayForRetry(attempt: 0), 0.0)
    }

    func testNegativeAttemptHandling() {
        let strategy = RetryStrategy()

        // Negative attempts should be handled gracefully
        let delay = strategy.delayForRetry(attempt: -1)

        XCTAssertEqual(delay, 0.0)
    }
}
