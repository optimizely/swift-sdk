//
/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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
    
import Optimizely
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    let logLevel = OptimizelyLogLevel.debug
    let sdkKey = "FCnSegiEkRry9rhVMroit4"
    var optimizely: OptimizelyClient!

    func applicationDidFinishLaunching() {
        optimizely = OptimizelyClient(sdkKey: sdkKey, defaultLogLevel: logLevel)
        optimizely.start { result in
            switch result {
            case .failure(let error):
                print("Optimizely SDK initiliazation failed: \(error)")
            case .success:
                print("Optimizely SDK initialized successfully!")
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
