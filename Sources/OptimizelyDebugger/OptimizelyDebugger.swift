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

import Foundation

public class OptimizelyDebugger {
    static let shared = OptimizelyDebugger()
    let debugVC: UINavigationController
    
    private init() {
        self.debugVC = UINavigationController()
        
        LogDBManager()
    }
    
    public static func startLogging(client: OptimizelyClient?) {
        guard let client = client else { return }

        
    }
    
    public static func open(client: OptimizelyClient?, parent: UIViewController?) {
        guard let client = client else { return }
        guard let parent = parent else { return }
        
        let coreVC = DebugViewController()
        coreVC.client = client
        coreVC.title = "Optimizely Debugger"
        coreVC.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: nil)
        coreVC.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                                                                       target: self,
                                                                       action: #selector(close))
        shared.debugVC.setViewControllers([coreVC], animated: true)

        parent.present(shared.debugVC, animated: true, completion: nil)
    }
    
    @objc public static func close() {
        shared.debugVC.dismiss(animated: true, completion: nil)
    }
    
}
