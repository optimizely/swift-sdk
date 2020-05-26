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

import UIKit

@objcMembers public class OptimizelyDebugger: NSObject {
    static let shared = OptimizelyDebugger()
    
    let logManager: LogDBManager
    let maxLogItemsCount = 10000
    
    private override init() {
        logManager = LogDBManager(maxItemsCount: maxLogItemsCount)
    }
    
    public static func open(client: OptimizelyClient?, inViewController parent: UIViewController) {
        #if os(iOS) && (DEBUG || OPT_DBG)
        shared.openDebugger(client: client, inViewController: parent)
        #endif
    }
    
    public static func logForDebugSession(level: OptimizelyLogLevel, module: String, text: String) {
        #if os(iOS) && (DEBUG || OPT_DBG)
        shared.logManager.insert(level: level, module: module, text: text)
        #endif
    }
}

#if os(iOS) && (DEBUG || OPT_DBG)
extension OptimizelyDebugger {
    
    private func openDebugger(client: OptimizelyClient?, inViewController parent: UIViewController?) {
        guard let client = client else { return }
        guard let parent = parent else { return }
        
        let coreVC = DebugViewController()
        coreVC.client = client
        coreVC.title = "Optimizely Debugger"
        coreVC.logManager = logManager
        
        let debugNVC = UINavigationController()
        debugNVC.setViewControllers([coreVC], animated: true)
        
        parent.present(debugNVC, animated: true, completion: nil)
    }
    
}
#endif
