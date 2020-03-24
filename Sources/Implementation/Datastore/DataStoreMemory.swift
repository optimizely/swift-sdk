/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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

import Foundation

/// Implementation of OPTDataStore as a generic for per type storeage in memory. On background and foreground
/// the file is saved.
/// This class should be used as a singleton per storeName and type (T)
public class DataStoreMemory<T>: BackgroundingCallbacks, OPTDataStore where T: Codable {
    let dataStoreName: String
    let lock: DispatchQueue
    var data: T?
    var backupDataStore:OPTDataStore
    lazy var logger:OPTLogger? = OPTLoggerFactory.getLogger()
    
    init(storeName: String, backupStore: OPTDataStore = DataStoreUserDefaults()) {
        dataStoreName = storeName
        lock = DispatchQueue(label: storeName)
        backupDataStore = backupStore
        load(forKey: dataStoreName)
        subscribe()
    }
    
    deinit {
        unsubscribe()
    }
    
    public func getItem(forKey: String) -> Any? {
        var retVal:T?
        lock.sync {
            retVal = self.data
        }
        return retVal
    }
    
    public func load(forKey: String) {
        lock.sync {
            do {
                if let contents = backupDataStore.getItem(forKey: dataStoreName) as? Data {
                    let item = try JSONDecoder().decode(T.self, from: contents)
                    self.data = item
                }
            } catch let error {
                self.logger?.e(error.localizedDescription)
            }
        }
    }
    
    public func saveItem(forKey: String, value: Any) {
        lock.async {
            if let value = value as? T {
                self.data = value
            }
        }
    }
    
    public func removeItem(sdkKey: String) {
        // this is a no op here. data could be niled out.
    }

    func save(forKey: String, value: Any) {
        lock.async {
            self.backupDataStore.saveItem(forKey: forKey, value: value)
        }
    }
    
    @objc func applicationDidEnterBackground() {
        if let data = data {
            save(forKey: dataStoreName, value: data as Any)
        }
    }

    @objc func applicationDidBecomeActive() {
        load(forKey: dataStoreName)
    }
}
