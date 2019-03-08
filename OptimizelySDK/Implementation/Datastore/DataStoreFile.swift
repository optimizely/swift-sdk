//
//  DataStoreFile.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 1/18/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

/// Implementation of OPTDataStore as a generic for per type storeage in a flat file.
/// This class should be used as a singleton per storeName and type (T)
public class DataStoreFile<T> : OPTDataStore where T:Codable {
    let dataStoreName:String
    let lock:DispatchQueue
    let url:URL
    
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
    }
    
    public func getItem(forKey: String) -> Any? {
        var returnItem:T?
        
        lock.sync {
            do {
                let contents = try Data(contentsOf: self.url)
                let item = try JSONDecoder().decode(T.self, from: contents)
                returnItem = item
            }
            catch let errorr {
                    print(errorr.localizedDescription)
            }
        }
        
        return returnItem
    }
    
    public func saveItem(forKey: String, value: Any) {
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
}
