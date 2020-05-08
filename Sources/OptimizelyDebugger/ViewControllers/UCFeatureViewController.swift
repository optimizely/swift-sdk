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

class UCFeatureViewController: UCItemViewController {
    var features = [String]()
    var values = [true, false]
    
    var selectedFeatureIndex: Int? {
        didSet {
            guard let index = self.selectedFeatureIndex else {
                featureView.text = nil
                return
            }
            
            let selectedFeature = features[index]
            featureView.text = selectedFeature
                        
            saveBtn.isEnabled = true
            saveBtn.alpha = 1.0
            removeBtn.isEnabled = true
            removeBtn.alpha = 1.0
        }
    }
    
    var selectedValueIndex: Int? {
        didSet {
            guard let index = self.selectedValueIndex else {
                valueView.text = nil
                return
            }
            
            valueView.text = String(self.values[index])
        }
    }

    let tagFeaturePicker = 1
    let tagValuePicker = 2
    
    var featureView: UITextField!
    var valueView: UITextField!
       
    override func setupData() {        
        features = client?.config?.featureFlagKeyMap.map { $0.key }.sorted() ?? []
                
        if let pair = pair, let enabled = pair.value as? Bool {
            selectedFeatureIndex = features.firstIndex(of: pair.key)
            selectedValueIndex = values.firstIndex(of: enabled)
        }
    }
    
    override func createContentsView() -> UIView {
        let gap: CGFloat = 10.0
        var cy: CGFloat = gap
        let cv = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))

        // feature-key picker
        
        featureView = makeTextInput(yPosition: cy,
                                      prompt: "Select a feature key",
                                      isPickerEnabled: true,
                                      tag: tagFeaturePicker,
                                      pickerDelegate: self)
        cv.addSubview(featureView)
        cy += featureView.frame.height + gap

        // value picker
        
        valueView = makeTextInput(yPosition: cy,
                                      prompt: "Select a value",
                                      isPickerEnabled: true,
                                      tag: tagValuePicker,
                                      pickerDelegate: self)
        cv.addSubview(valueView)
        cy += valueView.frame.height + gap

        cv.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: cy)
        return cv
    }
    
    override func readyToSave() -> Bool {
        if let featureKey = featureView.text, !featureKey.isEmpty,
            let enabled = valueView.text, !enabled.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    override func saveValue() {
        guard let featureKey = featureView.text, !featureKey.isEmpty,
            let enabled = valueView.text, !enabled.isEmpty else { return }
        
        client?.getUserContext()?.addForcedFeatureEnabled(featureKey: featureKey, enabled: Bool(enabled))
    }
    
    override func removeValue() {
        guard let featureKey = featureView.text else { return }
        
        client?.getUserContext()?.addForcedFeatureEnabled(featureKey: featureKey, enabled: nil)
    }

}

// Experiment PickerView

extension UCFeatureViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == tagFeaturePicker {
            return features.count + 1
        } else {
            return values.count + 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let adjustedRow = row - 1

        if pickerView.tag == tagFeaturePicker {
            if row == 0 {
                return "[Select a feature key]"
            } else {
                return features[adjustedRow]
            }
        } else {
            if row == 0 {
                return "[Select a value]"
            } else {
                return String(values[adjustedRow])
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let adjustedRow = row - 1
        
        if pickerView.tag == tagFeaturePicker {
            guard row > 0 else {
                selectedFeatureIndex = nil
                return
            }

            selectedFeatureIndex = adjustedRow
        } else {
            guard row > 0 else {
                selectedValueIndex = nil
                return
            }

            selectedValueIndex = adjustedRow
        }
    }
}
