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

class ForcedVariationsViewController: UITableViewController {
    weak var client: OptimizelyClient?
    
    var forcedList = [ForcedVariation]()
    var experiments = [String]()
    var variations = [String]()
    var selectedExperimentIndex: Int? {
        didSet {
            guard let index = self.selectedExperimentIndex else {
                expView.text = nil
                return
            }
            
            expView.text = self.experiments[index]
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
    
    var headerView: UIView!
    var userView: UITextField!
    var expView: UITextField!
    var varView: UITextField!
    var cancelBtn: UIButton!
    var saveBtn: UIButton!
       
    struct ForcedVariation {
        let userId: String
        let experimentKey: String
        let variationKey: String
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createHeaderViews()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showHeaderView))

        experiments = client?.config?.allExperiments.map { $0.key } ?? []
        
        refreshTableView()
        
        tableView.rowHeight = 60.0
    }
    
    func createHeaderViews() {
        let px: CGFloat = 10
        let py: CGFloat = 10
        var cy: CGFloat = py
        let height: CGFloat = 40
        
        let hv = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 200))
        
        userView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(userView)
        cy += height + py
        
        userView.placeholder = "Enter a user id"
        
        expView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(expView)
        cy += height + py

        expView.placeholder = "Select an experiment key"

        var pickerView = UIPickerView()
        pickerView.tag = self.tagExperimentPicker
        pickerView.dataSource = self
        pickerView.delegate = self
        expView.inputView = pickerView

        varView = UITextField(frame: CGRect(x: px, y: cy, width: hv.frame.width - 2*px, height: height))
        hv.addSubview(varView)
        cy += height + py

        varView.placeholder = "Select a variation key"
        
        pickerView = UIPickerView()
        pickerView.tag = self.tagVariationPicker
        pickerView.dataSource = self
        pickerView.delegate = self
        varView.inputView = pickerView
        
        let width = (hv.frame.width - 3*px) / 2.0
        cancelBtn = UIButton(frame: CGRect(x: px, y: cy, width: width, height: height))
        cancelBtn.backgroundColor = .gray
        cancelBtn.setTitle("Cancel", for: .normal)
        cancelBtn.addTarget(self, action: #selector(hideHeaderView), for: .touchUpInside)
        hv.addSubview(cancelBtn)

        saveBtn = UIButton(frame: CGRect(x: width + 2*px, y: cy, width: width, height: height))
        saveBtn.backgroundColor = .blue
        saveBtn.setTitle("Save", for: .normal)
        saveBtn.addTarget(self, action: #selector(saveForcedVariation), for: .touchUpInside)
        hv.addSubview(saveBtn)
        
        headerView = hv
    }
    
    @objc func showHeaderView() {
        tableView.tableHeaderView = headerView
    }
    
    @objc func hideHeaderView() {
        userView.text = nil
        expView.text = nil
        varView.text = nil
        
        tableView.tableHeaderView = nil
    }
    
    @objc func saveForcedVariation() {
        guard let userId = userView.text, userId.isEmpty == false,
            let experimentKey = expView.text, experimentKey.isEmpty == false,
            let variationKey = varView.text, variationKey.isEmpty == false
            else {
                let alert = UIAlertController(title: "Error", message: "Enter valid values and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
        }
        
        _ = self.client?.setForcedVariation(experimentKey: experimentKey, userId: userId, variationKey: variationKey)
        
        refreshTableView()
        hideHeaderView()
    }
            
    func refreshTableView() {
        guard let config = client?.config else { return }
        forcedList = [ForcedVariation]()
        
        config.whitelistUsers.forEach { (userId, pair) in
            pair.forEach { (experimentId, variationId) in
                if let exp = config.getExperiment(id: experimentId), let variation = exp.getVariation(id: variationId) {
                    forcedList.append(ForcedVariation(userId: userId, experimentKey: exp.key, variationKey: variation.key))
                }
            }
        }

        tableView.reloadData()
    }
            
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return forcedList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuse = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if reuse == nil {
            reuse = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        let cell = reuse!

        let item = forcedList[indexPath.row]
        
        cell.textLabel!.text = "UserID: \(item.userId)"
        cell.detailTextLabel!.text = "\(item.experimentKey) -> \(item.variationKey)"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

}

// Experiment PickerView

extension ForcedVariationsViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
            let selectedExperiment = experiments[adjustedRow]
        
            if let opt = try? client?.getOptimizelyConfig(),
                let experiment = opt.experimentsMap[selectedExperiment] {
                variations = Array(experiment.variationsMap.keys)
            }
        } else {
            guard row > 0 else {
                selectedVariationIndex = nil
                return
            }

            selectedVariationIndex = adjustedRow
        }
    }
}
