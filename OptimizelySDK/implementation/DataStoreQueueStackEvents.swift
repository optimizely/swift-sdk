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

//
// Implementation of Data Store Queue for event using standard UserDefaults.
//
//
public class DataStoreQueueStackEvents : DataStoreQueueStack  {
    
    static let eventQueue = "OPTEventQueue"
    static let lock = DispatchQueue(label: "DataStoreEventsLock")
    
    public func save(item:EventForDispatch) {
        DataStoreQueueStackEvents.lock.async {
            guard let data = try? JSONEncoder().encode(item) else { return }
            if var queue = UserDefaults.standard.array(forKey: DataStoreQueueStackEvents.eventQueue) {
                queue.append(data)
                UserDefaults.standard.set(queue, forKey: DataStoreQueueStackEvents.eventQueue)
                UserDefaults.standard.synchronize()
            }
            else {
                UserDefaults.standard.set([data], forKey: DataStoreQueueStackEvents.eventQueue)
                UserDefaults.standard.synchronize()
            }
        }
    }

    public func getFirstItem() -> EventForDispatch? {
        var item:EventForDispatch?
        
        DataStoreQueueStackEvents.lock.sync {
            if let queue = UserDefaults.standard.array(forKey: DataStoreQueueStackEvents.eventQueue) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                }
            }
        }
        return item
        
    }
    
    public func getLastItem() -> EventForDispatch? {
        var item:EventForDispatch?
        DataStoreQueueStackEvents.lock.sync {
            if let queue = UserDefaults.standard.array(forKey: DataStoreQueueStackEvents.eventQueue) {
                if let data = queue.last as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                }
            }
        }
        return item
    }
    

    public func removeFirstItem() -> EventForDispatch? {
        var item:EventForDispatch?
        
        DataStoreQueueStackEvents.lock.sync {
            if var queue = UserDefaults.standard.array(forKey: DataStoreQueueStackEvents.eventQueue) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                    if queue.count > 0 {
                            queue.remove(at: 0)
                            UserDefaults.standard.set(queue, forKey: DataStoreQueueStackEvents.eventQueue)
                            UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        return item
    }
    
    public func removeLastItem() -> EventForDispatch? {
        var item:EventForDispatch?
        DataStoreQueueStackEvents.lock.sync {
            if var queue = UserDefaults.standard.array(forKey: DataStoreQueueStackEvents.eventQueue) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                    if queue.count > 0 {
                        queue.removeLast()
                        UserDefaults.standard.set(queue, forKey: DataStoreQueueStackEvents.eventQueue)
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        return item
    }
}
