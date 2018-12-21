//
//  DataStoreUserDefault.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/20/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

//
// Implementation of Data Store for event using standard UserDefaults.
//
//
public class DataStoreEvents : DataStore  {
    
    static let eventQueue = "OPTEventQueue"
    static let lock = DispatchQueue(label: "DataStoreEventsLock")
    
    public func save(item:EventForDispatch) {
        DataStoreEvents.lock.async {
            guard let data = try? JSONEncoder().encode(item) else { return }
            if var queue = UserDefaults.standard.array(forKey: DataStoreEvents.eventQueue) {
                queue.append(data)
                UserDefaults.standard.set(queue, forKey: DataStoreEvents.eventQueue)
                UserDefaults.standard.synchronize()
            }
            else {
                UserDefaults.standard.set([data], forKey: DataStoreEvents.eventQueue)
                UserDefaults.standard.synchronize()
            }
        }
    }

    public func getFirstItem() -> EventForDispatch? {
        var item:EventForDispatch?
        
        DataStoreEvents.lock.sync {
            if let queue = UserDefaults.standard.array(forKey: DataStoreEvents.eventQueue) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                }
            }
        }
        return item
        
    }
    
    public func getLastItem() -> EventForDispatch? {
        var item:EventForDispatch?
        DataStoreEvents.lock.sync {
            if let queue = UserDefaults.standard.array(forKey: DataStoreEvents.eventQueue) {
                if let data = queue.last as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                }
            }
        }
        return item
    }
    

    public func removeFirstItem() -> EventForDispatch? {
        var item:EventForDispatch?
        
        DataStoreEvents.lock.sync {
            if var queue = UserDefaults.standard.array(forKey: DataStoreEvents.eventQueue) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                    if queue.count > 0 {
                            queue.remove(at: 0)
                            UserDefaults.standard.set(queue, forKey: DataStoreEvents.eventQueue)
                            UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        return item
    }
    
    public func removeLastItem() -> EventForDispatch? {
        var item:EventForDispatch?
        DataStoreEvents.lock.sync {
            if var queue = UserDefaults.standard.array(forKey: DataStoreEvents.eventQueue) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(EventForDispatch.self, from: data)
                    if queue.count > 0 {
                        queue.removeLast()
                        UserDefaults.standard.set(queue, forKey: DataStoreEvents.eventQueue)
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        return item
    }
}
