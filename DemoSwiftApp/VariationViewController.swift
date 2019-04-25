/****************************************************************************
 * Copyright 2016-2017, Optimizely, Inc. and contributors                   *
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
import Optimizely

class VariationViewController: UIViewController {
    
    var eventKey: String!
    var userId: String!
    var variationKey: String?
    var optimizelyManager: OptimizelyManager?
    var showCoupon: Bool = false {
        didSet  {
            DispatchQueue.main.async {
                self.couponView?.isHidden = !self.showCoupon
            }
        }
    }

    @IBOutlet weak var couponView:UIView!
    @IBOutlet weak var variationLetterLabel: UILabel!
    @IBOutlet weak var variationSubheaderLabel: UILabel!
    @IBOutlet weak var variationBackgroundImage: UIImageView!
    
    @IBAction func closeCoupon(_ sender: UIButton) {
        showCoupon = false
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
    }

    @IBAction func unwindToVariationAction(unwindSegue: UIStoryboardSegue) {
    }
    
    @IBAction func attemptTrackAndShowSuccessOrFailure(_ sender: Any) {
        do {
            try self.optimizelyManager?.track(eventKey: self.eventKey, userId: userId)
            self.performSegue(withIdentifier: "ConversionSuccessSegue", sender: self)
        } catch {
            self.performSegue(withIdentifier: "ConversionFailureSegue", sender: self)
        }
    }
}
