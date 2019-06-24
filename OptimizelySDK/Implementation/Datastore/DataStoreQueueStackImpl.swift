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

/// Implementation of DataStoreQueueStack that takes a DataStore as a instance variable allowing for different datastore imlementations.  It is a generic and will work with any data type that supports Codable.  Keep in mind that whichever data store you use, this class stores it as Array<Data>.  Instances of DataStoreQueueStackImpl should be singletons per queueStackName (which usually corrolates to the data type as well depending on producer/consumer).
public class DataStoreQueueStackImpl<T>: DataStoreQueueStack where T: Codable {
    let queueStackName: String
    let lock: DispatchQueue
    let dataStore: OPTDataStore

    /**
     Create instance of DataStoreQueueStack queue or stack.
     - Parameter queueStackName: name used for shared stack or queue.
     - Parameter dataStore: OPTDataStore implementation.
    */
    init(queueStackName: String, dataStore: OPTDataStore) {
        self.queueStackName = queueStackName
        self.lock = DispatchQueue(label: queueStackName)
        self.dataStore = dataStore
    }
    
    /**
     Save item to the datastore QueueStack.  The item is always appended and then depending on how you want to use it you can either pop (i.e. removeLastItem) or queue (i.e. removeFirstItem)
     - Parameter item: Item to save.
    */
    public func save(item: T) {
        lock.async {
            guard let data = try? JSONEncoder().encode(item) else { return }
            if var queue = self.dataStore.getItem(forKey: self.queueStackName) as? [Data] {
                queue.append(data)
                self.dataStore.saveItem(forKey: self.queueStackName, value: queue)
            } else {
                self.dataStore.saveItem(forKey: self.queueStackName, value: [data])
            }
        }
    }
    
    public var count: Int {
        get {
            var returnValue = 0
            
            lock.sync {
                if let queue = dataStore.getItem(forKey: queueStackName) as? [Data] {
                    returnValue = queue.count
                }
            }
            
            return returnValue
        }
    }
    
    public func getFirstItems(count: Int = 1) -> [T]? {
        var items: [T]?
        
        lock.sync {
            if let queue = dataStore.getItem(forKey: queueStackName) as? [Data] {
                let count = count < queue.count ? count : queue.count
                if count != 0 {
                    let data = queue[0...count-1]
                    items = [T]()
                    for item in data {
                        if let returnItem = try? JSONDecoder().decode(T.self, from: item) {
                            items?.append(returnItem)
                        }
                    }
                }
            }
        }
        return items
    }
    
    public func getLastItems(count: Int = 1) -> [T]? {
        var items: [T]?
        lock.sync {
            if let queue = dataStore.getItem(forKey: queueStackName) as? [Data] {
                let count = count < queue.count ? count : queue.count
                if count != 0 {
                    let start = count == queue.count ? 0 : queue.count - count
                    let data = queue[start...queue.count-1]
                    items = [T]()
                    for item in data {
                        if let returnItem = try? JSONDecoder().decode(T.self, from: item) {
                            items?.append(returnItem)
                        }
                    }
                }
            }
        }
        return items
    }
    
    public func removeFirstItems(count: Int = 1) -> [T]? {
        var items: [T]?
        
        lock.sync {
            if var queue = dataStore.getItem(forKey: queueStackName) as? [Data] {
                let count = count < queue.count ? count : queue.count
                if count != 0 {
                    let data = queue[0...count-1]
                    items = [T]()
                    for item in data {
                        if let returnItem = try? JSONDecoder().decode(T.self, from: item) {
                            items?.append(returnItem)
                        }
                    }
                    queue.removeFirst(count)
                    dataStore.saveItem(forKey: queueStackName, value: queue)
                }
            }
        }
        return items
        
    }
    
    public func removeLastItems(count: Int = 1) -> [T]? {
        var items: [T]?
        lock.sync {
            if var queue = dataStore.getItem(forKey: queueStackName) as? [Data] {
                let count = count < queue.count ? count : queue.count
                if count != 0 {
                    let start = count == queue.count ? 0 : queue.count - count
                    let data = queue[start...queue.count-1]
                    items = [T]()
                    for item in data {
                        if let returnItem = try? JSONDecoder().decode(T.self, from: item) {
                            items?.append(returnItem)
                        }
                    }
                    queue.removeLast(count)
                    dataStore.saveItem(forKey: queueStackName, value: queue)
                }
            }
        }
        return items
    }
}
