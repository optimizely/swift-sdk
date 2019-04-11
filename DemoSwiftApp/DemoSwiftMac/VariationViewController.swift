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
    

import Cocoa
import Optimizely

class VariationViewController: NSViewController {
    
    var eventKey: String!
    var userId: String!
    var variationKey: String?
    var optimizelyManager: OptimizelyManager?
    var showCoupon:Bool? {
        didSet  {
            if let show = showCoupon {
                if show {
                    DispatchQueue.main.async {
                        if self.couponView != nil {
                            self.couponView.isHidden = false
                        }
                        
                    }
                }
                else {
                    DispatchQueue.main.async {
                        if self.couponView != nil {
                            self.couponView.isHidden = true
                        }
                    }
                }
            }
        }
    }
    
    @IBOutlet weak var couponView:NSView!
    @IBOutlet weak var variationLetterLabel: NSTextField!
    @IBOutlet weak var variationSubheaderLabel: NSTextField!
    @IBOutlet weak var variationBackgroundImage: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let variationKey = self.variationKey {
            switch variationKey {
            case "variation_a":
                self.variationLetterLabel.stringValue = "A"
                self.variationLetterLabel.textColor = NSColor.black
                self.variationSubheaderLabel.textColor = NSColor.black
                self.variationBackgroundImage.image = NSImage(named: "background_variA")
            case "variation_b":
                self.variationLetterLabel.stringValue = "B"
                self.variationLetterLabel.textColor = NSColor.white
                self.variationSubheaderLabel.textColor = NSColor.white
                self.variationBackgroundImage.image = NSImage(named: "background_variB-marina")
            default:
                fatalError("Invalid variation key: \(variationKey)")
            }
        } else {
            // not mapped to experiement (not error)
            self.variationLetterLabel.stringValue = "U"
            self.variationLetterLabel.textColor = NSColor.gray
            self.variationSubheaderLabel.textColor = NSColor.white
        }
    }
    
    @IBAction func unwindToVariationAction(unwindSegue: NSStoryboardSegue) {
        
    }
    
    @IBAction func attemptTrackAndShowSuccessOrFailure(_ sender: Any) {
        do {
            try self.optimizelyManager?.track(eventKey: self.eventKey, userId: userId)
            self.performSegue(withIdentifier: "ConversionSuccessSegue", sender: self)
        }
        catch {
            self.performSegue(withIdentifier: "ConversionFailureSegue", sender: self)
            
        }
    }
}


