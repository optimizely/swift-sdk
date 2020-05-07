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

class UserContextItemViewController: UIViewController {
    weak var client: OptimizelyClient?
    
    var userId: String!
    var experiments = [String]()
    var variations = [String]()
    
    var actionOnDismiss: (() -> Void)?
    
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
                variations = Array(experiment.variationsMap.keys)
            }
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
    var cancelBtn: UIButton!
    var saveBtn: UIButton!
       
    struct ExperimentVariationPair {
        let experimentKey: String
        let variationKey: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createViews()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))

        experiments = client?.config?.allExperiments.map { $0.key } ?? []
    }
    
    func createViews() {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40
        
        let hv = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 210))
        
        expView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(expView)
        cy += height + py

        expView.placeholder = "Select an experiment key"
        expView.borderStyle = .roundedRect

        var pickerView = UIPickerView()
        pickerView.tag = self.tagExperimentPicker
        pickerView.dataSource = self
        pickerView.delegate = self
        expView.inputView = pickerView

        varView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(varView)
        cy += height + py

        varView.placeholder = "Select a variation key"
        varView.borderStyle = .roundedRect
        
        pickerView = UIPickerView()
        pickerView.tag = self.tagVariationPicker
        pickerView.dataSource = self
        pickerView.delegate = self
        varView.inputView = pickerView
        
        cy += 20
        let width = (hv.frame.width - 3*px) / 2.0
        cancelBtn = UIButton(frame: CGRect(x: px, y: cy, width: width, height: height))
        cancelBtn.backgroundColor = .red
        cancelBtn.setTitleColor(.white, for: .normal)
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        hv.addSubview(cancelBtn)

        saveBtn = UIButton(frame: CGRect(x: width + 2*px, y: cy, width: width, height: height))
        saveBtn.backgroundColor = .blue
        saveBtn.setTitleColor(.white, for: .normal)
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.addTarget(self, action: #selector(save), for: .touchUpInside)
        hv.addSubview(saveBtn)
                
        view.backgroundColor = .black
        view.addSubview(hv)
        hv.center = view.center
    }
    
    @objc func save() {
        guard let experimentKey = expView.text, experimentKey.isEmpty == false,
            let variationKey = varView.text, variationKey.isEmpty == false
            else {
                let alert = UIAlertController(title: "Error", message: "Enter valid values and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
        }
        
        _ = self.client?.setForcedVariation(experimentKey: experimentKey, userId: userId, variationKey: variationKey)
        close()
    }
    
    @objc func close() {
        actionOnDismiss?()
        dismiss(animated: true, completion: nil)
    }

}

// Experiment PickerView

extension UserContextItemViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
