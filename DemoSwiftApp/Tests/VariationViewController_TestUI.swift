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


import UIKit

extension VariationViewController {
    
    func initializeTestingUI() {
        dispatcherLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: view.frame.width, height: 24))
        dispatcherLabel.center = CGPoint.init(x: view.frame.width/2, y: 80)
        dispatcherLabel.textAlignment = .center
        dispatcherLabel.text = "Current # of Optimizely events:"
        dispatcherLabel.textColor = .white
        dispatcherLabel.alpha = 0.001
        self.view.addSubview(dispatcherLabel)
        
        queueSizeLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: view.frame.width, height: 32))
        queueSizeLabel.center = CGPoint.init(x: view.frame.width/2, y: 108)
        queueSizeLabel.textAlignment = .center
        queueSizeLabel.text = "nil"
        dispatcherLabel.textColor = .white
        queueSizeLabel.alpha = 0.001
        self.view.addSubview(queueSizeLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        queueSizeLabel.text = String(appDelegate.countDispatchQueue())
    }
}
