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
        attributes = client?.config?.attributeKeyMap.map { $0.key }.sorted() ?? []
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
            if case .boolean = type {
                selectedValueBooleanIndex = valuesBoolean.firstIndex(of: Bool(value) ?? false)
            } else {
                valueView.text = "\(value)"
            }
        }
    }
    
    override func createContentsView() -> UIView {
        let gap: CGFloat = 10.0
        var cy: CGFloat = gap
        let cv = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        
        // attribute picker
        
        attributeView = makeTextInput(yPosition: cy,
                                      prompt: "Select an attribute key",
                                      isPickerEnabled: true,
                                      tag: tagAttributePicker,
                                      pickerDelegate: self)
        cv.addSubview(attributeView)
        cy += attributeView.frame.height + gap
        
        // type picker
        
        typeView = makeTextInput(yPosition: cy,
                                 prompt: "Select a value type",
                                 isPickerEnabled: true,
                                 tag: tagTypePicker,
                                 pickerDelegate: self)
        cv.addSubview(typeView)
        cy += typeView.frame.height + gap
        
        // value input
        
        valueView = makeTextInput(yPosition: cy,
                                  prompt: "Enter a value",
                                  isPickerEnabled: false,
                                  textFieldDelegate: self)
        cv.addSubview(valueView)
        
        // value-boolean picker
        
        valueBooleanView = makeTextInput(yPosition: cy,
                                         prompt: "Select a value",
                                         isPickerEnabled: true,
                                         tag: tagValueBooleanPicker,
                                         pickerDelegate: self)
        cv.addSubview(valueBooleanView)
        cy += valueBooleanView.frame.height + gap
        
        cv.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: cy)
        return cv
    }
    
    override func readyToSave() -> Bool {
        if let attributeKey = attributeView.text, attributeKey.isEmpty == false,
            let type = typeView.text, !type.isEmpty {
            if case .boolean = ValueType(rawValue: type) {
                return valueBooleanView.text != nil  && valueBooleanView.text!.isEmpty == false
            } else {
                return valueView.text != nil && valueView.text!.isEmpty == false
            }
        } else {
            return false
        }
    }
    
    override func saveValue() {
        guard let attributeKey = attributeView.text, let type = typeView.text else { return }
    
        var value: Any
        
        switch ValueType(rawValue: type) {
        case .string:
            value = valueView.text as Any
        case .integer:
            value = Int(valueView.text ?? "") as Any
        case .double:
            value = Double(valueView.text ?? "") as Any
        case .boolean:
            value = Bool(valueBooleanView.text ?? "") as Any
        case .none:
            return
        }
        
        UserContextManager.getUserContext()?.addAttributeValue(attributeKey: attributeKey, value: value)
    }
    
    override func removeValue() {
        guard let attributeKey = attributeView.text else { return }
            
        UserContextManager.getUserContext()?.addAttributeValue(attributeKey: attributeKey, value: nil)
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
