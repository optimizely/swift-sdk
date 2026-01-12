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

import Foundation

/// Retry strategy with exponential backoff for event dispatching
class RetryStrategy {
    let maxRetries: Int
    let initialInterval: TimeInterval
    let maxInterval: TimeInterval

    /// Initialize RetryStrategy
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts (default: 2, for total 3 attempts)
    ///   - initialInterval: Initial retry interval in seconds (default: 0.2 seconds / 200ms)
    ///   - maxInterval: Maximum retry interval cap in seconds (default: 1.0 second)
    init(maxRetries: Int = 2,
         initialInterval: TimeInterval = 0.2,
         maxInterval: TimeInterval = 1.0) {
        self.maxRetries = maxRetries
        self.initialInterval = initialInterval
        self.maxInterval = maxInterval
    }

    /// Calculate delay for a given retry attempt using exponential backoff
    /// Formula: min(initialInterval * 2^attempt, maxInterval)
    /// - Parameter attempt: The retry attempt number (0-based)
    /// - Returns: Delay in seconds
    /// Example: For initialInterval=0.2, maxInterval=1.0
    ///   - attempt 0: 0.2s (200ms)
    ///   - attempt 1: 0.4s (400ms)
    ///   - attempt 2: 0.8s (800ms)
    ///   - attempt 3+: 1.0s (capped at maxInterval)
    func delayForRetry(attempt: Int) -> TimeInterval {
        guard attempt > 0 else { return 0 }

        let delay = initialInterval * pow(2.0, Double(attempt - 1))
        return min(delay, maxInterval)
    }

    /// Check if should retry based on current attempt count
    /// - Parameter currentAttempt: Current attempt number (0-based)
    /// - Returns: true if should continue retrying, false otherwise
    func shouldRetry(currentAttempt: Int) -> Bool {
        return currentAttempt <= maxRetries
    }
}
