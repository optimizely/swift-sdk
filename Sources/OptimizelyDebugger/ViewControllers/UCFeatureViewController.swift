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

class UCFeatureViewController: UIViewController {
    weak var client: OptimizelyClient?
    
    var userId: String!
    var value: (featureKey: String, enabled: Bool)?
    
    var features = [String]()
    var values = [true, false]
    
    var saveBtn: UIButton!
    var removeBtn: UIButton!
    
    var actionOnDismiss: (() -> Void)?
    
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
       
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createViews()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))

        features = client?.config?.featureFlagKeyMap.map { $0.key } ?? []
        
        // initial values
        
        if let value = value {
            selectedFeatureIndex = features.firstIndex(of: value.featureKey)
            selectedValueIndex = values.firstIndex(of: value.enabled)
        }
    }
    
    func createViews() {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40
        
        let hv = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 210))
        
        featureView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(featureView)
        cy += height + py

        featureView.placeholder = "Select a feature key"
        featureView.borderStyle = .roundedRect

        var pickerView = UIPickerView()
        pickerView.tag = self.tagFeaturePicker
        pickerView.dataSource = self
        pickerView.delegate = self
        featureView.inputView = pickerView

        valueView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(valueView)
        cy += height + py

        valueView.placeholder = "Select a value"
        valueView.borderStyle = .roundedRect
        
        pickerView = UIPickerView()
        pickerView.tag = self.tagValuePicker
        pickerView.dataSource = self
        pickerView.delegate = self
        valueView.inputView = pickerView
        
        cy += 20
        let width = (hv.frame.width - 3*px) / 2.0
        let cancelBtn = UIButton(frame: CGRect(x: px, y: cy, width: width, height: height))
        cancelBtn.backgroundColor = .gray
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        hv.addSubview(cancelBtn)

        saveBtn = UIButton(frame: CGRect(x: width + 2*px, y: cy, width: width, height: height))
        saveBtn.backgroundColor = .green
        saveBtn.setTitleColor(.black, for: .normal)
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)
        saveBtn.isEnabled = false
        saveBtn.alpha = 0.3
        hv.addSubview(saveBtn)
                
        cy += height + 20
        removeBtn = UIButton(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        removeBtn.backgroundColor = .red
        removeBtn.setTitleColor(.white, for: .normal)
        removeBtn.setTitle("Remove", for: .normal)
        removeBtn.addTarget(self, action: #selector(remove), for: .touchUpInside)
        removeBtn.isEnabled = false
        removeBtn.alpha = 0.3
        hv.addSubview(removeBtn)

        view.backgroundColor = .black
        view.addSubview(hv)
        hv.center = view.center
    }
    
    @objc func save() {
        guard let featureKey = featureView.text, featureKey.isEmpty == false,
            let enabled = valueView.text, enabled.isEmpty == false
            else {
                let alert = UIAlertController(title: "Error", message: "Enter valid values and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
        }
        
        client?.getUserContext()?.addForcedFeatureEnabled(featureKey: featureKey, enabled: Bool(enabled))
        
        close()
    }
    
    @objc func remove() {
        if let featureKey = featureView.text {
            client?.getUserContext()?.addForcedFeatureEnabled(featureKey: featureKey, enabled: nil)
        }
        close()
    }
    
    @objc func close() {
        actionOnDismiss?()
        dismiss(animated: true, completion: nil)
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
