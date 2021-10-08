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

@available(iOSApplicationExtension 12.0, *)
class NetworkReachability {
    static let shared = NetworkReachability()
    
    let monitor = NWPathMonitor()
    var isConnected = false
    
    private init() {
        
        // NOTE: unit test with real devices only (simulator not updating properly)
        
        monitor.pathUpdateHandler = { [weak self] path in
            // "Reachability path: satisfied (Path is satisfied), interface: en0, ipv4, ipv6, dns, expensive, constrained"
            // "Reachability path: unsatisfied (No network route)"
            print("Reachability path: \(path)")
            
            self?.isConnected = (path.status == .satisfied)
        }
    }
    
    func start() {
        monitor.start(queue: DispatchQueue.global())
    }
    
}
