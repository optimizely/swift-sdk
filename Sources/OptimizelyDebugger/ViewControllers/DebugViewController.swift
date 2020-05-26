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

class DebugViewController: UITableViewController {
    
    struct DebuggerItem {
        let title: String
        let text: String?
        let icon: UIImage?
        let action: (() -> Void)?
        
        init(title: String, text: String? = nil, icon: UIImage? = nil, action: (() -> Void)?) {
            self.title = title
            self.text = text
            self.icon = icon
            self.action = action
        }
    }

    weak var client: OptimizelyClient!
    weak var logManager: LogDBManager!
    
    var items = [DebuggerItem]()
    
    convenience init(client: OptimizelyClient, title: String, logManager: LogDBManager) {
        self.init(nibName: nil, bundle: nil)
        
        self.client = client
        self.title = title
        self.logManager = logManager
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let config = try? client.getOptimizelyConfig() else { return }
        
        //navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                                                                       target: self,
                                                                       action: #selector(close))
        
        items.append(DebuggerItem(title: "SDK Version", text: client.version, action: nil))
        items.append(DebuggerItem(title: "SDK Key", text: client.sdkKey, action: nil))
        items.append(DebuggerItem(title: "ProjectConfig") {
            self.openPropsView(title: "ProjectConfig", props: config)
        })
        items.append(DebuggerItem(title: "Logs") {
            self.openLogView()
        })
        items.append(DebuggerItem(title: "User Contexts") {
            self.openUserContexts()
        })

        tableView.rowHeight = 60.0
        
        // disable closeing modal-view by pull-down
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
    }
    
    @objc public func close() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - segues
    
    func openPropsView(title: String, props: Any) {
        let vc = PropsTableViewController(props: props, title: title)
        self.show(vc, sender: self)
    }
    
    func openLogView() {
        let vc = LogViewController(client: client, title: "Logs", logManager: logManager)
        self.show(vc, sender: self)
    }
        
    func openUserContexts() {
        let vc = UserContextViewController(client: client, title: "User Contexts")
        self.show(vc, sender: self)
    }
    
}

// MARK: - TableView

extension DebugViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuse = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if reuse == nil {
            reuse = UITableViewCell(style: .value1, reuseIdentifier: "reuseIdentifier")
        }
        let cell = reuse!
        
        let item = items[indexPath.row]
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.text
        cell.accessoryType = (item.action != nil) ? .disclosureIndicator : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.action?()
    }

}

#endif
