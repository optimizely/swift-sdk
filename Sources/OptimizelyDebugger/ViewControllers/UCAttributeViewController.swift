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

class UCAttributeViewController: UIViewController {
    weak var client: OptimizelyClient?
    
    var userId: String!
    var value: (attributeKey: String, value: Any)?
    
    var attributes = [String]()
    
    var saveBtn: UIButton!
    var removeBtn: UIButton!
    
    var actionOnDismiss: (() -> Void)?
    
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
        
        createViews()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))

        attributes = client?.config?.attributeKeyMap.map { $0.key } ?? []
        
        // initial values
        
        if let value = value {
            selectedAttributeIndex = attributes.firstIndex(of: value.attributeKey)
        }
    }
    
    func createViews() {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40
        
        let hv = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 210))
        
        attributeView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(attributeView)
        cy += height + py

        attributeView.placeholder = "Select an attribute key"
        attributeView.borderStyle = .roundedRect

        let pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        attributeView.inputView = pickerView

        valueView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(valueView)
        cy += height + py

        valueView.placeholder = "Select a value"
        valueView.borderStyle = .roundedRect
        valueView.returnKeyType = .done
        valueView.delegate = self
        valueView.autocapitalizationType = .none
        valueView.autocorrectionType = .no
        
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
        guard let attributeKey = attributeView.text, attributeKey.isEmpty == false,
            let value = valueView.text, value.isEmpty == false
            else {
                let alert = UIAlertController(title: "Error", message: "Enter valid values and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
        }
        
        //client?.getUserContext()?.addForcedFeatureEnabled(featureKey: featureKey, enabled: Bool(enabled))
        
        close()
    }
    
    @objc func remove() {
        if let attributeKey = attributeView.text {
            //client?.getUserContext()?.addForcedFeatureEnabled(featureKey: featureKey, enabled: nil)
        }
        close()
    }
    
    @objc func close() {
        actionOnDismiss?()
        dismiss(animated: true, completion: nil)
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
