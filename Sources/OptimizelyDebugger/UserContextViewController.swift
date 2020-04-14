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

class UserContextViewController: UITableViewController {
    weak var client: OptimizelyClient?
    
    var userView: UITextView!
    
    var userContext: OptimizelyUserContext?
    var allAttributes = [String]()
    var attributes = [String]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let keys = client?.config?.attributeKeyMap.keys {
            allAttributes = Array(keys)
        }
        
        userContext = client?.getUserContext()
        
        // userId + attributes table
        
        userView = UITextView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 50))
        userView.backgroundColor = .gray
        userView.text = "UserID: \( userContext?.userId ?? "N/A")"
        userView.font = .systemFont(ofSize: 16)
        userView.textAlignment = .center
        tableView.tableHeaderView = userView
                
        refreshTableView()
        
        tableView.rowHeight = 60.0
    }
    
    @objc func saveUserContext() {
        guard let userId = userView.text, userId.isEmpty == false
            else {
                let alert = UIAlertController(title: "Error", message: "Enter valid values and try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
        }
        
        _ = self.client?.setUserContext(OptimizelyUserContext(userId: userId, attributes: nil))
        
        refreshTableView()
    }
    
    func removeUserContext(userId: String, experimentKey: String) {
        _ = self.client?.setUserContext(nil)
        
        refreshTableView()
    }
            
    func refreshTableView() {
        guard let user = userContext, let attrs = user.attributes else { return }
        
        attributes = Array(attrs.keys)
        
        tableView.reloadData()
    }
}

// MARK: - Table view data source

extension UserContextViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allAttributes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuse = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if reuse == nil {
            reuse = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        }
        let cell = reuse!

        let attributeKey = allAttributes[indexPath.row]
        var attributeValue = ""
        if let pairs = userContext!.attributes, let any = pairs[attributeKey], let value = any {
            switch value {
            case let value as String:
                attributeValue = value
            case let value as Int:
                attributeValue = String(value)
            case let value as Bool:
                attributeValue = String(value)
            case let value as Double:
                attributeValue = String(value)
            default:
                attributeValue = "[Unknown]"
            }
        }
        
        cell.textLabel!.text = attributeKey
        cell.detailTextLabel!.text = attributeValue
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
}
