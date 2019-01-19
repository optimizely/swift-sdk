//
//  DataStoreFile.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 1/18/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

class DataStoreFile<T> : OPTDataStore where T:Codable {
    let datafileName:String
    let lock:DispatchQueue
    let url:URL
    
    init(storeName:String) {
        datafileName = storeName
        lock = DispatchQueue(label: storeName)
        if let url = FileManager.default.urls(for: .applicationDirectory, in: .userDomainMask).first {
            self.url = url.appendingPathComponent(storeName)
        }
        else {
            self.url = URL(fileURLWithPath:storeName)
        }
    }
    
    func getItem(forKey: String) -> Any? {
        var returnItem:T?
        
        lock.sync {
            if let contents = try? Data(contentsOf: self.url) {
                if let item = try? JSONDecoder().decode(T.self, from: contents) {
                    returnItem = item
                }
            }
        }
        
        return returnItem
    }
    
    func saveItem(forKey: String, value: Any) {
        lock.async {
            if let value = value as? T {
                if let data = try? JSONEncoder().encode(value) {
                    try? data.write(to: self.url, options: .atomic)
                }
            }
        }
    }
    
    
}
