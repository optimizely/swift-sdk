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

import Foundation
import SystemConfiguration

/// Check if network interface is up and running
class NetworkReachability {
    static let shared = NetworkReachability()
    
    var reachable: Bool = false
    static var isReachable: Bool {
        let status = self.shared.reachable
        
        DispatchQueue.global().async {
            self.shared.updateReachability()
        }
        
        print("[Reachability] \(status)")
        return status
    }
    
    private var reachability: SCNetworkReachability?
    private var isUpdating: Bool = false
    
    private init() {
        self.reachability = SCNetworkReachabilityCreateWithName(nil, "o.p.t")
        updateReachability()
    }
    
    func updateReachability() {
        guard !isUpdating else { return }
        isUpdating = true
        
        guard let reachability = self.reachability else {
            // cannot determine reachability. assume true for safety.
            self.reachable = true
            return
        }
        
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability, &flags)
        
        self.reachable = flags.contains(.reachable)
        isUpdating = false
    }
}
