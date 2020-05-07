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
    
    let sectionHeaderHeight: CGFloat = 50.0
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let keys = client?.config?.attributeKeyMap.keys {
            allAttributes = Array(keys)
        }
                
        userView = UITextView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 40))
        userView.backgroundColor = .lightGray
        userView.font = .systemFont(ofSize: 18)
        userView.textAlignment = .center
        
        tableView.tableHeaderView = userView
        tableView.rowHeight = 60.0
        
        refreshUserContext()
    }
    
    func refreshUserContext() {
        userContext = self.client?.getUserContext()
        userView.text = "UserID: \( userContext?.userId ?? "N/A")"
        refreshTableView()
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
        return 4
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let userContext = userContext else { return 0 }
        
        switch section {
        case 0: return userContext.attributes?.count ?? 0
        case 1: return userContext.userProfiles?.count ?? 0
        case 2: return userContext.forcedVariations?.count ?? 0
        case 3: return userContext.features?.count ?? 0
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return sectionHeaderHeight
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        var title: String
        switch section {
        case 0: title = "Attributes"
        case 1: title = "User Profiles"
        case 2: title = "Forced Variations"
        case 3: title = "Features"
        default: title = "N/A"
        }
        
        let height = sectionHeaderHeight
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: height))
        
        let label = UILabel(frame: CGRect(x: 10, y: 5, width: 200.0, height: sectionHeaderHeight - 10))
        view.addSubview(label)
        label.text = title
        
        let buttonHeight: CGFloat = 40.0
        let addBtn = UIButton(type: .contactAdd)
        addBtn.frame = CGRect(x: view.frame.size.width - buttonHeight - 10.0,
                                            y: (sectionHeaderHeight - buttonHeight)/2.0,
                                            width: buttonHeight,
                                            height: buttonHeight)
        addBtn.addTarget(self, action: #selector(addItem), for: .touchUpInside)
        addBtn.tag = section
        view.addSubview(addBtn)
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuse = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if reuse == nil {
            reuse = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        }
        let cell = reuse!

        let (key, rawValue) = keyValueForIndexPath(indexPath)
        var value: String?
        if let rv = rawValue {
            switch rv {
            case let rv as String:
                value = rv
            case let rv as Int:
                value = String(rv)
            case let rv as Bool:
                value = String(rv)
            case let rv as Double:
                value = String(rv)
            default:
                value = "[Unknown]"
            }
        }
        
        cell.textLabel!.text = key
        cell.detailTextLabel!.text = value
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
    
    func keyValueForIndexPath(_ indexPath: IndexPath) -> (String?, Any?) {
        guard let userContext = userContext else { return (nil, nil) }

        var data: [String: Any?]?
        
        switch indexPath.section {
        case 0:
            data = userContext.attributes
        case 1:
            data = userContext.userProfiles
        case 2:
            data = userContext.forcedVariations
        case 3:
            data = userContext.features
        default:
            data = nil
        }
        
        guard let dict = data else { return (nil, nil) }
        
        let key = dict.keys.sorted()[indexPath.row]
        let value = dict[key] as Any?
        return (key, value)
    }
    
    @objc func addItem(sender: UIButton) {
        guard let uc = userContext else { return }
        
        let vc = UserContextItemViewController()
        vc.client = client
        vc.userId = uc.userId

        switch sender.tag {
        case 0: print("section 0")
            vc.title = "Attributes"
        case 1: print("section 1")
            vc.title = "User Profile"
        case 2: print("section 2")
            vc.title = "Forced Variations"
        case 3: print("section 3")
            vc.title = "Features"
        default: print("section other")
        }
        
        vc.actionOnDismiss = {
            self.refreshUserContext()
        }
        
        let nvc = UINavigationController(rootViewController: vc)
        self.present(nvc, animated: true, completion: nil)
    }
}
