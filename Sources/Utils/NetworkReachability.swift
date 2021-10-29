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
    
    var monitor: AnyObject?
    let queue = DispatchQueue(label: "reachability")
    
    // the number of contiguous download failures (reachability)
    var numContiguousFails = 0
    // the maximum number of contiguous network connection failures allowed before reachability checking
    var maxContiguousFails: Int
    let defaultMaxContiguousFails = 1

    #if targetEnvironment(simulator)
    private var connected = false       // initially false for testing support
    #else
    private var connected = true        // initially true for safety in production
    #endif
    
    var isConnected: Bool {
        get {
            var result = false
            queue.sync {
                result = connected
            }
            return result
        }
        // for test support only
        set {
            queue.sync {
                connected = newValue
            }
        }
    }
    
    init(maxContiguousFails: Int? = nil) {
        self.maxContiguousFails = maxContiguousFails ?? defaultMaxContiguousFails
     
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            
            // NOTE: test with real devices only (simulator not updating properly)

            self.monitor = NWPathMonitor()
            
            (monitor as! NWPathMonitor).pathUpdateHandler = { [weak self] (path: NWPath) -> Void in
                // "Reachability path: satisfied (Path is satisfied), interface: en0, ipv4, ipv6, dns, expensive, constrained"
                // "Reachability path: unsatisfied (No network route)"
                //print("Reachability path: \(path)")
                
                // this task runs in sync queue. set private variable (instead of isConnected to avoid deadlock)
                self?.connected = (path.status == .satisfied)
            }
            
            (monitor as! NWPathMonitor).start(queue: queue)
        }
    }
    
    func stop() {
        if #available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *) {
            guard let monitor = monitor as? NWPathMonitor else { return }

            monitor.pathUpdateHandler = nil
            monitor.cancel()
        }
    }
    
    func updateNumContiguousFails(isError: Bool) {
        numContiguousFails = isError ? (numContiguousFails + 1) : 0
    }
            
    /// Skip network access when reachability is down (optimization for iOS12+ only)
    /// - Returns: true when network access should be blocked
    func shouldBlockNetworkAccess() -> Bool {
        if numContiguousFails < maxContiguousFails { return false }

        if #available(iOS 12, tvOS 12, macOS 10.14, watchOS 5, macCatalyst 13, *) {
            return !isConnected
        } else {
            return false
        }
    }
    
}
