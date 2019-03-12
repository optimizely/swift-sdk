//
//  DataStoreMemory.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 3/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import UIKit

/// Implementation of OPTDataStore as a generic for per type storeage in memory. On background and foreground
/// the file is saved.
/// This class should be used as a singleton per storeName and type (T)
public class DataStoreMemory<T> : BackgroundingCallbacks, OPTDataStore where T:Codable {
    let dataStoreName:String
    let lock:DispatchQueue
    let url:URL
    var data:T?
    
    init(storeName:String) {
        dataStoreName = storeName
        lock = DispatchQueue(label: storeName)
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            self.url = url.appendingPathComponent(storeName, isDirectory: false)
            if !FileManager.default.fileExists(atPath: self.url.path) {
                do {
                    let data = try JSONEncoder().encode([Data]())
                    try data.write(to: self.url, options: .atomicWrite)
                }
                catch let error {
                    print(error.localizedDescription)
                }
            }
        }
        else {
            self.url = URL(fileURLWithPath:storeName)
        }
        
        subscribe()
    }
    
    deinit {
        unsubscribe()
    }
    
    public func getItem(forKey: String) -> Any? {
        var returnData:T?
        
        lock.sync {
            returnData = data
        }
        return returnData
    }
    
    public func load(forKey: String) {
        lock.sync {
            do {
                let contents = try Data(contentsOf: self.url)
                let item = try JSONDecoder().decode(T.self, from: contents)
                self.data = item
            }
            catch let errorr {
                print(errorr.localizedDescription)
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

    private func save(forKey: String, value: Any) {
        lock.async {
            do {
                if let value = value as? T {
                    let data = try JSONEncoder().encode(value)
                    try data.write(to: self.url, options: .atomic)
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
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
