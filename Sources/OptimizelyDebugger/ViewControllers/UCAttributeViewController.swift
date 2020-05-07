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

class UCAttributeViewController: UCItemViewController {
    var attributes = [String]()
            
    var selectedAttributeIndex: Int? {
        didSet {
            guard let index = self.selectedAttributeIndex else {
                attributeView.text = nil
                return
            }
            
            let selectedAttribute = attributes[index]
            attributeView.text = selectedAttribute
                        
            saveBtn.isEnabled = true
            saveBtn.alpha = 1.0
            removeBtn.isEnabled = true
            removeBtn.alpha = 1.0
        }
    }
        
    var attributeView: UITextField!
    var valueView: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        attributes = client?.config?.attributeKeyMap.map { $0.key } ?? []
                
        if let pair = pair {
            selectedAttributeIndex = attributes.firstIndex(of: pair.key)
        }
    }
    
    override func createContentsView() -> UIView {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40

        let cv = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 120))
                
        attributeView = UITextField(frame: CGRect(x: px, y: cy, width: cv.frame.width - 2*px, height: height))
        cv.addSubview(attributeView)
        cy += height + py

        attributeView.placeholder = "Select an attribute key"
        attributeView.borderStyle = .roundedRect

        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        attributeView.inputView = pickerView
        attributeView.autocapitalizationType = .none
        attributeView.autocorrectionType = .no

        valueView = UITextField(frame: CGRect(x: px, y: cy, width: cv.frame.width - 2*px, height: height))
        cv.addSubview(valueView)
        cy += height + py

        valueView.placeholder = "Select a value"
        valueView.borderStyle = .roundedRect
        valueView.returnKeyType = .done
        valueView.delegate = self
        valueView.autocapitalizationType = .none
        valueView.autocorrectionType = .no
        
        return cv
    }
    
    override func readyToSave() -> Bool {
        if let attributeKey = attributeView.text, attributeKey.isEmpty == false,
            let value = valueView.text,
            value.isEmpty == false {
            return true
        } else {
            return false
        }
    }
    
    override func saveValue() {
        guard let attributeKey = attributeView.text,
            let value = valueView.text else { return }
        
        client?.getUserContext()?.addAttributeValue(attributeKey: attributeKey, value: value)
    }
    
    override func removeValue() {
        guard let attributeKey = attributeView.text else { return }
            
        client?.getUserContext()?.addAttributeValue(attributeKey: attributeKey, value: nil)
    }
    
}

// PickerView

extension UCAttributeViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return attributes.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let adjustedRow = row - 1

        if row == 0 {
            return "[Select an attribute key]"
        } else {
            return attributes[adjustedRow]
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let adjustedRow = row - 1
        
        guard row > 0 else {
            selectedAttributeIndex = nil
            return
        }

        selectedAttributeIndex = adjustedRow
    }
}

// UITextFieldDelegate

extension UCAttributeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
