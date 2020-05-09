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

class UCVariationViewController: UCItemViewController {
    var experiments = [String]()
    var variations = [String]()
        
    var selectedExperimentIndex: Int? {
        didSet {
            guard let index = self.selectedExperimentIndex else {
                expView.text = nil
                return
            }
            
            let selectedExperiment = experiments[index]
            expView.text = selectedExperiment
            
            // update variations candidates for a selected experiment
            
            if let opt = try? client?.getOptimizelyConfig(),
                let experiment = opt.experimentsMap[selectedExperiment] {
                variations = Array(experiment.variationsMap.keys).sorted()
            }
            
            saveBtn.isEnabled = true
            saveBtn.alpha = 1.0
            removeBtn.isEnabled = true
            removeBtn.alpha = 1.0
        }
    }
    
    var selectedVariationIndex: Int? {
        didSet {
            guard let index = self.selectedVariationIndex else {
                varView.text = nil
                return
            }
            
            varView.text = self.variations[index]
        }
    }

    let tagExperimentPicker = 1
    let tagVariationPicker = 2
    
    var expView: UITextField!
    var varView: UITextField!
       
    override func setupData() {        
        experiments = client?.config?.allExperiments.map { $0.key }.sorted() ?? []
                
        if let pair = pair, let value = pair.value as? String {
            selectedExperimentIndex = experiments.firstIndex(of: pair.key)
            selectedVariationIndex = variations.firstIndex(of: value)
        }
    }
    
    override func createContentsView() -> UIView {
        let gap: CGFloat = 10.0
        var cy: CGFloat = gap
        let cv = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))

        // experiment-key picker
        
        expView = makeTextInput(yPosition: cy,
                                      prompt: "Select an experiment key",
                                      isPickerEnabled: true,
                                      tag: tagExperimentPicker,
                                      pickerDelegate: self)
        cv.addSubview(expView)
        cy += expView.frame.height + gap

        // variation-key picker
      
        varView = makeTextInput(yPosition: cy,
                                      prompt: "Select a variation key",
                                      isPickerEnabled: true,
                                      tag: tagVariationPicker,
                                      pickerDelegate: self)
        cv.addSubview(varView)
        cy += varView.frame.height + gap
        
        cv.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: cy)
        return cv
    }
    
    override func readyToSave() -> Bool {
        if let experimentKey = expView.text, experimentKey.isEmpty == false,
            let variationKey = varView.text, variationKey.isEmpty == false {
            return true
        } else {
            return false
        }
    }
    
    override func saveValue() {
        guard let experimentKey = expView.text,
            let variationKey = varView.text else { return }

        UserContextManager.getUserContext()?.addForcedVariation(experimentKey: experimentKey,
                                                                variationKey: variationKey)
    }
    
    override func removeValue() {
        guard let experimentKey = expView.text else { return }
            
        UserContextManager.getUserContext()?.addForcedVariation(experimentKey: experimentKey, variationKey: nil)
    }

}

// Experiment PickerView

extension UCVariationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == tagExperimentPicker {
            return experiments.count + 1
        } else {
            return variations.count + 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let adjustedRow = row - 1

        if pickerView.tag == tagExperimentPicker {
            if row == 0 {
                return "[Select an experiment key]"
            } else {
                return experiments[adjustedRow]
            }
        } else {
            if row == 0 {
                return "[Select a variation key]"
            } else {
                return variations[adjustedRow]
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let adjustedRow = row - 1
        
        if pickerView.tag == tagExperimentPicker {
            guard row > 0 else {
                selectedExperimentIndex = nil
                return
            }

            selectedExperimentIndex = adjustedRow
        } else {
            guard row > 0 else {
                selectedVariationIndex = nil
                return
            }

            selectedVariationIndex = adjustedRow
        }
    }
}
