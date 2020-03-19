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

class LogViewController: UITableViewController {    
    weak var client: OptimizelyClient?
    var items = [LogItem]()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let client = client else { return }

        tableView.rowHeight = 60.0
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
        cell.textLabel!.text = "[\(item.level)][\(item.module)]"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let item = items[indexPath.row]
//        item.action?()
    }

}
