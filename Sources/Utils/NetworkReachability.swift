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

import Foundation
import Network

class NetworkReachability {

    private let queue = DispatchQueue(label: "reachability")

    // All mutable state — only accessed within queue
    private var monitor: AnyObject?
    private var monitorStarted = false
    private var _numContiguousFails = 0
    private var _maxContiguousFails: Int

    #if targetEnvironment(simulator)
    private var _connected = false       // initially false for testing support
    #else
    private var _connected = true        // initially true for safety in production
    #endif

    static let defaultMaxContiguousFails = 1

    // MARK: - Thread-safe accessors

    var isConnected: Bool {
        get { queue.sync { _connected } }
        set { queue.sync { _connected = newValue } }
    }

    var numContiguousFails: Int {
        get { queue.sync { _numContiguousFails } }
        set { queue.sync { _numContiguousFails = newValue } }
    }

    var maxContiguousFails: Int {
        get { queue.sync { _maxContiguousFails } }
        set { queue.sync { _maxContiguousFails = newValue } }
    }

    var isMonitorActive: Bool {
        queue.sync { monitor != nil }
    }

    // MARK: - Init

    init(maxContiguousFails: Int? = nil) {
        self._maxContiguousFails = maxContiguousFails ?? Self.defaultMaxContiguousFails
    }

    // MARK: - Monitor lifecycle

    // NOTE: NWPathMonitor can only be tested with real devices (simulator not updating properly)
    func startMonitorIfNeeded() {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            var monitorToStart: NWPathMonitor?
            queue.sync {
                guard !monitorStarted else { return }
                monitorStarted = true

                let pathMonitor = NWPathMonitor()
                self.monitor = pathMonitor
                pathMonitor.pathUpdateHandler = { [weak self] path in
                    self?._connected = (path.status == .satisfied)
                }
                monitorToStart = pathMonitor
            }
            monitorToStart?.start(queue: queue)
        }
    }

    func stop() {
        queue.sync {
            monitorStarted = true
            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                (monitor as? NWPathMonitor)?.pathUpdateHandler = nil
                (monitor as? NWPathMonitor)?.cancel()
            }
            monitor = nil
        }
    }

    // MARK: - Network state

    func updateNumContiguousFails(isError: Bool) {
        queue.sync {
            _numContiguousFails = isError ? (_numContiguousFails + 1) : 0
        }
    }

    func shouldBlockNetworkAccess() -> Bool {
        startMonitorIfNeeded()

        return queue.sync {
            guard _numContiguousFails >= _maxContiguousFails else { return false }

            if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
                return !_connected
            } else {
                return false
            }
        }
    }

}
