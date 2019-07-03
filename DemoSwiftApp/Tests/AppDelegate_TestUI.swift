//
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
import UIKit

extension AppDelegate {
    
    func initializeTestingUI() -> Void {
        // To refresh queueSizeLabel text.
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateQueueSizeLabel), userInfo: nil, repeats: true)
        
        // To perform UI tests faster.
        if (ProcessInfo.processInfo.environment["UITEST_DISABLE_ANIMATIONS"] == "YES") {
            UIView.setAnimationsEnabled(false)
        }
    }
    
    func countDispatchQueue() -> Int {
        return self.eventHandler.getDataStoreCount()
    }
    
    @objc func updateQueueSizeLabel() {
        guard let vvc = self.window?.rootViewController as? VariationViewController else {
            return
        }
        vvc.queueSizeLabel.text = String(self.countDispatchQueue())
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateQueueSizeLabel), userInfo: nil, repeats: true)
        guard let vvc = self.window?.rootViewController as? VariationViewController else {
            return
        }
        vvc.queueSizeLabel.text = String(self.countDispatchQueue())
    }
}
