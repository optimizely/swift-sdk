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

/// Simple DataStore using key value.  This abstracts away the datastore layer. The datastore should take into account synchronization.
public protocol OPTDataStore {
    
    /// getItem - get an item by key.
    /// - Parameter forKey: key to lookup datastore value.
    /// - Returns: the value saved or nil
    func getItem(forKey: String) -> Any?
    /// saveItem - save the item to the datastore.
    /// - Parameter forKey: key to save value
    /// - Parameter value: value to save.
    func saveItem(forKey: String, value: Any)
}
