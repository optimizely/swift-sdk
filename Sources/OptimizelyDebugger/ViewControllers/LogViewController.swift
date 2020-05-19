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

class LogViewController: UITableViewController {
    weak var client: OptimizelyClient?
    var items = [OptimizelyLogItem]()
    var sessionId: Int = 0
    var keyword: String?
    var level: OptimizelyLogLevel = .info
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addHeaderViews()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearLogs))
        
        refreshTableView()
        
        tableView.rowHeight = 60.0
    }
    
    func addHeaderViews() {
        let hv = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 100))
        
        // LogLevel selector
        
        let logLevels: [OptimizelyLogLevel] = [.error, .warning, .info, .debug]
        let sv = UISegmentedControl(items: logLevels.map { $0.name })
        sv.selectedSegmentIndex = 2
        sv.layer.cornerRadius = 5.0
        sv.backgroundColor = .gray
        sv.tintColor = .white
        sv.frame = CGRect(x: 10, y: 10, width: hv.frame.width - 20, height: 30)
        sv.addTarget(self, action: #selector(changeLogLevel), for: .valueChanged)
        hv.addSubview(sv)
        
        // Keyword Search Bar
        
        let tv = UISearchBar(frame: CGRect(x: 5, y: 40, width: hv.frame.width - 10, height: 50))
        tv.placeholder = "Enter search keywords"
        tv.autocapitalizationType = .none
        tv.delegate = self
        hv.addSubview(tv)
        
        tableView.tableHeaderView = hv
    }
    
    @objc func changeLogLevel(sender: UISegmentedControl) {
        level = OptimizelyLogLevel(rawValue: sender.selectedSegmentIndex + 1)!
        refreshTableView()
    }
    
    @objc func clearLogs(sender: UIBarButtonItem) {
        LogDBManager.shared.clear()
        refreshTableView()
    }
    
    func refreshTableView() {
        (sessionId, items) = LogDBManager.shared.read(level: level, keyword: keyword)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuse = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        if reuse == nil {
            reuse = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        let cell = reuse!

        let item = items[indexPath.row]
        
        cell.textLabel!.text = "[\(OptimizelyLogLevel(rawValue: Int(item.level))!.name)] \(item.date!)"
        cell.detailTextLabel!.text = item.text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }

}

// MARK: - SearchBar delegate

extension LogViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        keyword = searchBar.text
        if keyword != nil, keyword!.isEmpty { keyword = nil }
        refreshTableView()
    }
    
    // clear table when "x" pressed
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            keyword = nil
            refreshTableView()
        }
    }
    
}

#endif
