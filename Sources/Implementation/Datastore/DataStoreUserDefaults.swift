//
// Copyright 2019-2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

/// Implementation of OPTDataStore using standard UserDefaults.
/// This class should be used as a singleton.
public class DataStoreUserDefaults: OPTDataStore {
    // A hardcoded max for user defaults.  Since there is a max on iostv
    #if os(tvOS)
    static let MAX_DS_SIZE = 128000
    #else
    static let MAX_DS_SIZE = 1000000
    #endif
    static let dispatchQueue = DispatchQueue(label: "OPTDataStoreQueueUserDefaults")
    
    public func getItem(forKey: String) -> Any? {
        return DataStoreUserDefaults.dispatchQueue.sync {
            return UserDefaults.standard.object(forKey: forKey)
        }
    }
    
    public func saveItem(forKey: String, value: Any) {

        DataStoreUserDefaults.dispatchQueue.async {
            if let value = value as? Data {
                if value.count > DataStoreUserDefaults.MAX_DS_SIZE {
                    self.logError("Save to User Defaults error: \(forKey) is too big to save size(\(value.count))")
                    return
                }
            } else if let value = value as? String {
                if value.count > DataStoreUserDefaults.MAX_DS_SIZE {
                    self.logError("Save to User Defaults error: \(forKey) is too big to save size(\(value.count))")
                    return
                }
            } else if let value = value as? [Data] {
                var l: Int = 0
                l = value.reduce(into: l, { (res, data) in
                    res += data.count
                })
                if l > DataStoreUserDefaults.MAX_DS_SIZE {
                    self.logError("Save to User Defaults error: \(forKey) is too big to save size(\(value.count))")
                    return
                }
            } else if let value = value as? [String] {
                var l: Int = 0
                l = value.reduce(into: l, { (res, data) in
                    res += data.count
                })
                if l > DataStoreUserDefaults.MAX_DS_SIZE {
                    self.logError("Save to User Defaults error: \(forKey) is too big to save size(\(value.count))")
                    return
                }
            }
            UserDefaults.standard.set(value, forKey: forKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public func removeItem(forKey: String) {
        UserDefaults.standard.removeObject(forKey: forKey)
    }
    
    func logError(_ message: String) {
        OPTLoggerFactory.getLogger().e(message)
    }
    
}
