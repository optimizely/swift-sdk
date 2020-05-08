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
    var types = [ValueType]()
    var valuesBoolean = [true, false]

    enum ValueType: String, CaseIterable {
        case string
        case integer
        case double
        case boolean
    }
    
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
    
    var selectedTypeIndex: Int? {
        didSet {
            guard let index = self.selectedTypeIndex else {
                typeView.text = nil
                return
            }
            
            let type = self.types[index]
            typeView.text = type.rawValue
            
            if case .boolean = type {
                valueView.isHidden = true
                valueBooleanView.isHidden = false
            } else {
                valueView.isHidden = false
                valueBooleanView.isHidden = true
            }
        }
    }
    
    var selectedValueBooleanIndex: Int? {
        didSet {
            guard let index = self.selectedValueBooleanIndex else {
                valueView.text = nil
                return
            }
            
            valueBooleanView.text = String(self.valuesBoolean[index])
        }
    }

    let tagAttributePicker = 1
    let tagTypePicker = 2
    let tagValueBooleanPicker = 3

    var attributeView: UITextField!
    var typeView: UITextField!
    var valueView: UITextField!
    var valueBooleanView: UITextField!

    override func setupData() {
        attributes = client?.config?.attributeKeyMap.map { $0.key } ?? []
        types = ValueType.allCases
                
        if let pair = pair {
            var value: String
            var type: ValueType
            
            let attrValue = AttributeValue(value: pair.value)
            switch attrValue {
            case .string(let v):
                type = .string
                value = v
            case .int(let v):
                type = .integer
                value = String(v)
            case .double(let v):
                type = .double
                value = String(v)
            case .bool(let v):
                type = .boolean
                value = String(v)
            default:
                type = .string
                value = "[N/A]"
            }
                 
            selectedAttributeIndex = attributes.firstIndex(of: pair.key)
            selectedTypeIndex = types.firstIndex(of: type)
            valueView.text = "\(value)"
        }
    }
    
    override func createContentsView() -> UIView {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40

        let cv = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 150))
              
        // attribute picker
        
        attributeView = UITextField(frame: CGRect(x: px, y: cy, width: cv.frame.width - 2*px, height: height))
        cv.addSubview(attributeView)
        cy += height + py

        attributeView.placeholder = "Select an attribute key"
        attributeView.borderStyle = .roundedRect
        attributeView.inputView = makePickerView(tag: tagAttributePicker, delegate: self)
        attributeView.inputAccessoryView = makePickerToolbar()

        // type picker
        
        typeView = UITextField(frame: CGRect(x: px, y: cy, width: cv.frame.width - 2*px, height: height))
        cv.addSubview(typeView)
        cy += height + py

        typeView.placeholder = "Select a value type"
        typeView.borderStyle = .roundedRect
        typeView.inputView = makePickerView(tag: tagTypePicker, delegate: self)
        typeView.inputAccessoryView = makePickerToolbar()

        // value input
        
        valueView = UITextField(frame: CGRect(x: px, y: cy, width: cv.frame.width - 2*px, height: height))
        cv.addSubview(valueView)

        valueView.placeholder = "Select a value"
        valueView.borderStyle = .roundedRect
        valueView.returnKeyType = .done
        valueView.delegate = self
        valueView.autocapitalizationType = .none
        valueView.autocorrectionType = .no
        
        // value-boolean picker
        
        valueBooleanView = UITextField(frame: CGRect(x: px, y: cy, width: cv.frame.width - 2*px, height: height))
        cv.addSubview(valueBooleanView)
        cy += height + py

        valueBooleanView.placeholder = "Select a value"
        valueBooleanView.borderStyle = .roundedRect
        valueBooleanView.inputView = makePickerView(tag: tagValueBooleanPicker, delegate: self)
        valueBooleanView.inputAccessoryView = makePickerToolbar()

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
        if pickerView.tag == tagAttributePicker {
            return attributes.count + 1
        } else if pickerView.tag == tagTypePicker {
            return types.count + 1
        } else {
            return valuesBoolean.count + 1
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let adjustedRow = row - 1

        if pickerView.tag == tagAttributePicker {
            if row == 0 {
                return "[Select an attribute key]"
            } else {
                return attributes[adjustedRow]
            }
        } else if pickerView.tag == tagTypePicker {
            if row == 0 {
                return "[Select a value type]"
            } else {
                return types[adjustedRow].rawValue
            }
        } else {
            if row == 0 {
                return "[Select a value]"
            } else {
                return String(valuesBoolean[adjustedRow])
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let adjustedRow = row - 1
        
        if pickerView.tag == tagAttributePicker {
            guard row > 0 else {
                selectedAttributeIndex = nil
                return
            }

            selectedAttributeIndex = adjustedRow
        } else if pickerView.tag == tagTypePicker {
            guard row > 0 else {
                selectedTypeIndex = nil
                return
            }

            selectedTypeIndex = adjustedRow
        } else {
            guard row > 0 else {
                selectedValueBooleanIndex = nil
                return
            }

            selectedValueBooleanIndex = adjustedRow
        }
    }
}

// UITextFieldDelegate

extension UCAttributeViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
