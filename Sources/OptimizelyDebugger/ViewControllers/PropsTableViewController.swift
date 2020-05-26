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
  
#if os(iOS) && (DEBUG || OPT_DBG)

import UIKit

class PropsTableViewController: UITableViewController {
    var props: Any!
    var dict: [String: Any]!
    var fixedOrder = [String]()
    
    convenience init(props: Any, title: String) {
        self.init(nibName: nil, bundle: nil)
        
        self.props = props
        self.title = title
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if props is [String: Any] {
            dict = (props as! [String: Any])
            fixedOrder = dict.keys.sorted()
        } else if let array = props as? [Any] {
            dict = Dictionary(uniqueKeysWithValues: zip([Int](0..<array.count).map { String($0) }, array))
            fixedOrder = dict.keys.sorted()
        } else {
            // presentation order of Object fields are determined by custom mirroring
            (fixedOrder, dict) = convertToDict(props)
        }
                
        tableView.rowHeight = 60
    }
    
    func convertToDict(_ props: Any?) -> ([String], [String: Any]) {
        guard let props = props else { return ([String](), [String: Any]()) }
        
        let mirror = Mirror(reflecting: props)
        let keys = mirror.children.map { $0.label ?? "N/A - \(Int.random(in: 0..<1000000))" }
        let values = mirror.children.map { $0.value }
        
        return (keys,       // keep mirror-defined order
                Dictionary(uniqueKeysWithValues: zip(keys, values)))
    }
}

// MARK: - Table view data source

extension PropsTableViewController {

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fixedOrder.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuse = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if reuse == nil {
            reuse = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        }
        let cell = reuse!
        
        let key = fixedOrder[indexPath.row]
        
        let item = dict[key]
        cell.textLabel?.text = key
        
        if let value = item as? String {
            cell.detailTextLabel?.text = value
            cell.accessoryType = .none
        } else if let value = item as? Bool {
            cell.detailTextLabel?.text = String(value)
            cell.accessoryType = .none
        } else if let value = item as? [String: Any] {
            if value.isEmpty {
                cell.detailTextLabel?.text = "[empty]"
                cell.accessoryType = .none
            } else {
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .disclosureIndicator
            }
        } else if let value = item as? [Any] {
            if value.isEmpty {
                cell.detailTextLabel?.text = "[empty]"
                cell.accessoryType = .none
            } else {
                cell.detailTextLabel?.text = nil
                cell.accessoryType = .disclosureIndicator
            }
        } else {
            cell.detailTextLabel?.text = nil
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = fixedOrder[indexPath.row]
        
        guard let item = dict[key] else { return }
        guard let cell = tableView.cellForRow(at: indexPath),
            case .disclosureIndicator = cell.accessoryType else { return }

        let propsView = PropsTableViewController()
        propsView.title = key
        propsView.props = item
        self.show(propsView, sender: self)
    }
}

#endif
