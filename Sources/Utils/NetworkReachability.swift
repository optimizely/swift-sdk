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

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
class NetworkReachability {
    static let shared = NetworkReachability()
    
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "reachability")
    
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
    
    private init() {
        
        // NOTE: test with real devices only (simulator not updating properly)

        start()
    }
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] (path: NWPath) -> Void in
            // "Reachability path: satisfied (Path is satisfied), interface: en0, ipv4, ipv6, dns, expensive, constrained"
            // "Reachability path: unsatisfied (No network route)"
            //print("Reachability path: \(path)")
            
            // this task runs in sync queue. set private variable (instead of isConnected to avoid deadlock)
            self?.connected = (path.status == .satisfied)
        }

        monitor.start(queue: queue)
    }
    
    func stop() {
        monitor.pathUpdateHandler = nil
        monitor.cancel()
    }
    
}

extension Utils {
    
    static var defaultMaxContiguousFails = 1
    
    /// Skip network access when reachability is down (optimization for iOS12+ only)
    ///
    /// For safety, trust reachability only when the last downloads failed contiguously.
    ///
    /// - Parameter numContiguousFails: the number of contiguous network connection failures
    /// - Parameter maxContiguousFails: the maximum number of contiguous network connection failures allowed before reachability checking
    /// - Returns: true when network access should be blocked
    static func shouldBlockNetworkAccess(numContiguousFails: Int, maxContiguousFails: Int = defaultMaxContiguousFails) -> Bool {
        if numContiguousFails < maxContiguousFails { return false }
        
        if #available(iOS 12, tvOS 12, macOS 10.14, watchOS 5, macCatalyst 13, *) {            
            return !NetworkReachability.shared.isConnected
        } else {
            return false
        }
    }
    
}
