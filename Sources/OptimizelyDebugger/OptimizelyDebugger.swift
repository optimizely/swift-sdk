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
    
    public static func open(client: OptimizelyClient?, parent: UIViewController?) {
        #if DEBUG || OPT_DBG
        openDebugger(client: client, parent: parent)
        #endif
    }
    
    public static func logForDebugSession(level: OptimizelyLogLevel, module: String, text: String) {
        #if DEBUG || OPT_DBG
        LogDBManager.shared.insert(level: level, module: module, text: text)
        #endif
    }
}

#if DEBUG || OPT_DBG
extension OptimizelyDebugger {
    
    private static func openDebugger(client: OptimizelyClient?, parent: UIViewController?) {
        guard let client = client else { return }
        guard let parent = parent else { return }
        
        let coreVC = DebugViewController()
        coreVC.client = client
        coreVC.title = "Optimizely Debugger"
        
        let debugNVC = UINavigationController()
        debugNVC.setViewControllers([coreVC], animated: true)
        
        parent.present(debugNVC, animated: true, completion: nil)
    }
    
}
#endif
