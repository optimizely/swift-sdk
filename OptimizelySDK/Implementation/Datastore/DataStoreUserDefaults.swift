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

/// Implementation of OPTDataStore using standard UserDefaults.
/// This class should be used as a singleton.
public class DataStoreUserDefaults: OPTDataStore {
    static let dispatchQueue = DispatchQueue(label: "OPTDataStoreQueueUserDefaults")
    
    public func getItem(forKey: String) -> Any? {
        
        return DataStoreUserDefaults.dispatchQueue.sync {
            return UserDefaults.standard.object(forKey: forKey)
        }
    }
    
    public func saveItem(forKey: String, value: Any) {
        DataStoreUserDefaults.dispatchQueue.async {
            UserDefaults.standard.set(value, forKey: forKey)
            UserDefaults.standard.synchronize()
        }
    }
    
}
