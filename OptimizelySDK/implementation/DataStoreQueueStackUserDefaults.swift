//
//  DataStoreQueueStackUserDefaults.swift
//  OptimizelySwiftSDK-iOS
//
//  Created by Thomas Zurkan on 1/18/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

public class DataStoreQueuStackUserDefaults<T> : DataStoreQueueStack where T:Codable {
    let queueStackName:String
    let lock:DispatchQueue

    /**
     Get instance of user defaults queue or stack.  Keep in mind that the queueStackName and lock name should be the same for each instance that wants to share the queue or stack.
     - Parameter queueStackName: name used for shared stack or queue.
    */
    init(queueStackName:String) {
        self.queueStackName = queueStackName
        self.lock = DispatchQueue(label: queueStackName)
    }
    
    public func save(item:T) {
        lock.async {
            guard let data = try? JSONEncoder().encode(item) else { return }
            if var queue = UserDefaults.standard.array(forKey: self.queueStackName) {
                queue.append(data)
                UserDefaults.standard.set(queue, forKey: self.queueStackName)
                UserDefaults.standard.synchronize()
            }
            else {
                UserDefaults.standard.set([data], forKey: self.queueStackName)
                UserDefaults.standard.synchronize()
            }
        }
    }
    
    public func getFirstItem() -> T? {
        var item:T?
        
        lock.sync {
            if let queue = UserDefaults.standard.array(forKey: queueStackName) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(T.self, from: data)
                }
            }
        }
        return item
        
    }
    
    public func getLastItem() -> T? {
        var item:T?
        lock.sync {
            if let queue = UserDefaults.standard.array(forKey: queueStackName) {
                if let data = queue.last as? Data {
                    item = try? JSONDecoder().decode(T.self, from: data)
                }
            }
        }
        return item
    }
    
    
    public func removeFirstItem() -> T? {
        var item:T?
        
        lock.sync {
            if var queue = UserDefaults.standard.array(forKey: queueStackName) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(T.self, from: data)
                    if queue.count > 0 {
                        queue.remove(at: 0)
                        UserDefaults.standard.set(queue, forKey: queueStackName)
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        return item
    }
    
    public func removeLastItem() -> T? {
        var item:T?
        lock.sync {
            if var queue = UserDefaults.standard.array(forKey: queueStackName) {
                if let data = queue.first as? Data {
                    item = try? JSONDecoder().decode(T.self, from: data)
                    if queue.count > 0 {
                        queue.removeLast()
                        UserDefaults.standard.set(queue, forKey: queueStackName)
                        UserDefaults.standard.synchronize()
                    }
                }
            }
        }
        return item
    }
}
