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
    static var enabled = true

    let logManager: LogDBManager
    
    private override init() {
        logManager = LogDBManager()
    }
    
    /// Open the OptimizelyDebugger UI
    /// - Parameters:
    ///   - client: an instance of OptimizelyClint to be debugged
    ///   - parent: the parent view controller to present the debugger UI to
    public static func open(client: OptimizelyClient?,
                            inViewController parent: UIViewController) {
        #if os(iOS) && (DEBUG || OPT_DBG)
        if enabled {
            shared.openDebugger(client: client, inViewController: parent)
        }
        #endif
    }
    
    /// Disable OptimizelyDebugger programmatically
    ///
    /// Call this before initializing OptimizelyClient to disable the debugger  (default: enabled)
    /// - Parameter enable: true for enabled
    public static func enable(_ enable: Bool) {
        enabled = enable
    }
    
    /// Change maximum log items count in the session log database
    /// - Parameter maxLogItemsCount: max count (default: 10000)
    public static func setConfig(maxLogItemsCount: Int? = nil) {
        if let maxCount = maxLogItemsCount {
            shared.logManager.changeMaxItemsCount(maxCount)
        }
    }
    
    /// Call this to log messages into the session log database (necessary only if a cusom logger is used)
    ///
    /// - Parameters:
    ///   - level: log level
    ///   - module: module name
    ///   - text: log message
    public static func logForDebugSession(level: OptimizelyLogLevel, module: String, text: String) {
        #if os(iOS) && (DEBUG || OPT_DBG)
        if enabled {
            shared.logManager.insert(level: level, module: module, text: text)
        }
        #endif
    }
}

#if os(iOS) && (DEBUG || OPT_DBG)
extension OptimizelyDebugger {
    
    private func openDebugger(client: OptimizelyClient?, inViewController parent: UIViewController?) {
        guard let client = client else { return }
        guard let parent = parent else { return }
        
        let coreVC = DebugViewController(client: client,
                                         title: "Optimizely Debugger",
                                         logManager: logManager)        
        let debugNVC = UINavigationController()
        debugNVC.setViewControllers([coreVC], animated: true)
        
        parent.present(debugNVC, animated: true, completion: nil)
    }
    
}
#endif
