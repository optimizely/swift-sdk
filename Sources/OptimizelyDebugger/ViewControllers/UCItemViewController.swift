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

class UCItemViewController: UIViewController {
    weak var client: OptimizelyClient?
    var userId: String!
    var pair: (key: String, value: Any)?
    var actionOnDismiss: (() -> Void)?

    var saveBtn: UIButton!
    var removeBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews(contentsView: createContentsView())
        setupData()
    }
    
    func setupViews(contentsView: UIView) {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40
        
        let hv = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
                
        hv.addSubview(contentsView)
        cy += contentsView.frame.size.height + 20
        
        let width = (view.frame.width - 3*px) / 2.0
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
        removeBtn = UIButton(frame: CGRect(x: px, y: cy, width: view.frame.width - 2*px, height: height))
        removeBtn.backgroundColor = .red
        removeBtn.setTitleColor(.white, for: .normal)
        removeBtn.setTitle("Remove", for: .normal)
        removeBtn.addTarget(self, action: #selector(remove), for: .touchUpInside)
        removeBtn.isEnabled = false
        removeBtn.alpha = 0.3
        hv.addSubview(removeBtn)
        
        cy += height
        
        view.backgroundColor = .black
        view.addSubview(hv)
        
        hv.frame = CGRect(x: 0, y: 100, width: view.frame.size.width, height: cy)
    }
    
    func makeTextInput(yPosition: CGFloat,
                       prompt: String,
                       isPickerEnabled: Bool,
                       tag: Int? = nil,
                       textFieldDelegate: UITextFieldDelegate? = nil,
                       pickerDelegate: (UIPickerViewDelegate & UIPickerViewDataSource)? = nil) -> UITextField {
        let xPosition: CGFloat = 10.0
        let height: CGFloat = 50.0
        let v = UITextField(frame: CGRect(x: xPosition,
                                          y: yPosition,
                                          width: view.frame.width - 2*xPosition,
                                          height: height))
        v.textAlignment = .right
        v.borderStyle = .roundedRect
        v.autocapitalizationType = .none
        v.autocorrectionType = .no
        v.returnKeyType = .done
        // add padding to the right
        v.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        v.rightViewMode = .always
        // keyboard input mode
        if let delegate = textFieldDelegate {
            v.delegate = delegate
        }
        // associated picker mode
        if isPickerEnabled, let tag = tag, let delegate = pickerDelegate {
            v.inputView = makePickerView(tag: tag, delegate: delegate)
            v.inputAccessoryView = makePickerToolbar()
        }

        let mv = UILabel(frame: CGRect(x: 10.0, y: 5.0, width: v.frame.width - 20.0, height: 14))
        mv.textAlignment = .left
        mv.adjustsFontSizeToFitWidth = true
        mv.font = mv.font.withSize(12)
        mv.text = prompt
        mv.textColor = .gray
        v.addSubview(mv)
        
        return v
    }
    
    func makePickerView(tag: Int, delegate: UIPickerViewDelegate & UIPickerViewDataSource) -> UIPickerView {
        let pickerView = UIPickerView()
        pickerView.tag = tag
        pickerView.dataSource = delegate
        pickerView.delegate = delegate
        return pickerView
    }
    
    func makePickerToolbar() -> UIToolbar {
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = .blue
        toolBar.sizeToFit()
        
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(closePicker))
        
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        return toolBar
    }
    
    @objc func closePicker() {
        view.endEditing(true)
    }
    
    @objc func save() {
        guard readyToSave() else {
            let alert = UIAlertController(title: "Error", message: "Enter valid values and try again", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        saveValue()
        close()
    }
    
    @objc func remove() {
        removeValue()
        close()
    }
    
    @objc func close() {
        actionOnDismiss?()
        dismiss(animated: true, completion: nil)
    }
    
    // override
    
    func setupData() {}
    
    func createContentsView() -> UIView { return UIView() }
    
    func readyToSave() -> Bool { return false }
    
    func readyToRemove() -> Bool { return false }
    
    func saveValue() {}
    
    func removeValue() {}
    
}
