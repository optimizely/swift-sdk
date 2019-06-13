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
//import Optimizely

class VariationViewController: UIViewController {
    
    var eventKey: String!
    var userId: String!
    var variationKey: String?
    var optimizely: OptimizelyClient?
    var showCoupon: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.couponView?.isHidden = !self.showCoupon
            }
        }
    }
    
    var dispatcherLabel: UILabel!
    var queueSizeLabel: UILabel!
    
    @IBOutlet weak var couponView: UIView!
    @IBOutlet weak var variationLetterLabel: UILabel!
    @IBOutlet weak var variationSubheaderLabel: UILabel!
    @IBOutlet weak var variationBackgroundImage: UIImageView!
    
    @IBAction func closeCoupon(_ sender: UIButton) {
        showCoupon = false
    }
    
    @IBAction func unwindToVariationAction(unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func attemptTrackAndShowSuccessOrFailure(_ sender: Any) {
        do {
            try self.optimizely?.track(eventKey: self.eventKey, userId: userId)
            self.performSegue(withIdentifier: "ConversionSuccessSegue", sender: self)
        } catch {
            self.performSegue(withIdentifier: "ConversionFailureSegue", sender: self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let variationKey = self.variationKey {
            switch variationKey {
            case "variation_a":
                self.variationLetterLabel.text = "A"
                self.variationLetterLabel.textColor = UIColor.black
                self.variationSubheaderLabel.textColor = UIColor.black
                self.variationBackgroundImage.image = UIImage(named: "background_variA")
            case "variation_b":
                self.variationLetterLabel.text = "B"
                self.variationLetterLabel.textColor = UIColor.white
                self.variationSubheaderLabel.textColor = UIColor.white
                self.variationBackgroundImage.image = UIImage(named: "background_variB-marina")
            default:
                fatalError("Invalid variation key: \(variationKey)")
            }
        } else {
            // not mapped to experiement (not error)
            self.variationLetterLabel.text = "U"
            self.variationLetterLabel.textColor = UIColor.gray
            self.variationSubheaderLabel.textColor = UIColor.white
        }
        
        dispatcherLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: view.frame.width, height: 24))
        dispatcherLabel.center = CGPoint.init(x: view.frame.width/2, y: 80)
        dispatcherLabel.textAlignment = .center
        dispatcherLabel.backgroundColor = .white
        dispatcherLabel.text = "Current # of Optimizely events:"
        self.view.addSubview(dispatcherLabel)
        
        queueSizeLabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: view.frame.width, height: 32))
        queueSizeLabel.center = CGPoint.init(x: view.frame.width/2, y: 108)
        queueSizeLabel.textAlignment = .center
        queueSizeLabel.backgroundColor = .white
        queueSizeLabel.text = "nil"
        self.view.addSubview(queueSizeLabel)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        queueSizeLabel.text = String(appDelegate.countDispatchQueue())
    }
}
