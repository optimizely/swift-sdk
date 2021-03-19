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

import Optimizely
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let logLevel = OptimizelyLogLevel.debug
    var optimizely: OptimizelyClient!

    let sdkKey = "FCnSegiEkRry9rhVMroit4"
    let featureKey = "decide_demo"
    let eventKey = "sample_conversion"
    let userId = String(Int.random(in: 0..<100000))
    let attributes: [String: Any] = ["location": "NY",
                                     "bool_attr": false,
                                     "semanticVersioning": "1.2"]

    func applicationDidFinishLaunching() {
        optimizely = OptimizelyClient(sdkKey: sdkKey, defaultLogLevel: logLevel)
        
        optimizely.start { result in
            switch result {
            case .failure(let error):
                print("Optimizely SDK initiliazation failed: \(error)")
            case .success:
                print("Optimizely SDK initialized successfully!")
                
                let user = self.optimizely.createUserContext(userId: self.userId, attributes: self.attributes)
                let decision = user.decide(key: self.featureKey, options: [.includeReasons])
                print("[DECISION] \(decision)")
                try? user.trackEvent(eventKey: self.eventKey)
            @unknown default:
                print("Optimizely SDK initiliazation failed with unknown result")
            }
        }
    }

    func applicationDidBecomeActive() {
        WatchBackgroundNotifier.applicationDidBecomeActive()
    }

    func applicationDidEnterBackground() {
        WatchBackgroundNotifier.applicationDidEnterBackground()
    }
}
