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

struct NetworkReachability {
    /// Check network reachability
    ///
    /// - Parameters:
    ///   - timeout: re-try until timeout if not-reachable
    ///   - handler: action to take after reachability check
    static func waitForReachable(timeout: Int? = nil, handler: @escaping (Bool) -> Void) {
        DispatchQueue.global().async {
            guard let reachability = SCNetworkReachabilityCreateWithName(nil, "google.com") else {
                handler(false)
                return
            }
            
            var reachable = false
            let checkIntervalInMilliSecs = 10
            let timeoutInMilliSecs = timeout ?? 100
            var waitTime = 0
            
            while waitTime < timeoutInMilliSecs {
                var flags = SCNetworkReachabilityFlags()
                SCNetworkReachabilityGetFlags(reachability, &flags)

                reachable = flags.contains(.reachable)
                if reachable { break }
                
                usleep(useconds_t(checkIntervalInMilliSecs * 1000))
                waitTime += checkIntervalInMilliSecs
            }

            //print("[OPTIMIZELY] network reachable? " + (reachable ? "YES" : "NO"))

            handler(reachable)
        }
    }
}
