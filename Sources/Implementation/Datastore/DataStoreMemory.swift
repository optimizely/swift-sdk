/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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
    var backupDataStore: OPTDataStore
    public enum BackingStore { case UserDefaults, File }
    lazy var logger: OPTLogger? = OPTLoggerFactory.getLogger()
    
    init(storeName: String, backupStore:BackingStore = .File) {
        dataStoreName = storeName
        lock = DispatchQueue(label: storeName)
        switch backupStore {
        case .File:
            self.backupDataStore = DataStoreFile<T>(storeName: storeName, async: false)
        case .UserDefaults:
            self.backupDataStore = DataStoreUserDefaults()
        }
        load(forKey: dataStoreName)
        subscribe()
    }
    
    deinit {
        unsubscribe()
    }
    
    public func getItem(forKey: String) -> Any? {
        var retVal: T?
        lock.sync {
            retVal = self.data
        }
        return retVal
    }
    
    public func load(forKey: String) {
        lock.sync {
            if let contents = backupDataStore.getItem(forKey: dataStoreName) as? T {
                self.data = contents
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
    
    public func removeItem(forKey: String) {
        lock.async {
            self.data = nil
            self.backupDataStore.removeItem(forKey: forKey)
        }
        // this is a no op here. data could be niled out.
    }

    func save(forKey: String, value: Any) {
        lock.async {
            self.backupDataStore.saveItem(forKey: forKey, value: value)
        }
    }
    
    @objc func applicationDidEnterBackground() {
        if let data = self.data {
            self.save(forKey: dataStoreName, value: data as Any)
        }
    }

    @objc func applicationDidBecomeActive() {
        self.load(forKey: dataStoreName)
    }
}
