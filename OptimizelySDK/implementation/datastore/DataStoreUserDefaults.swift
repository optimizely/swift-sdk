//
//  DataStoreUserDefaults.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

class DataStoreUserDefaults : OPTDataStore {
    static let dispatchQueue = DispatchQueue(label: "OPTDataStoreQueueUserDefaults")
    
    func getItem(forKey: String) -> Any? {
        
        return DataStoreUserDefaults.dispatchQueue.sync {
            return UserDefaults.standard.object(forKey:forKey)
        }
    }
    
    func saveItem(forKey: String, value: Any) {
        DataStoreUserDefaults.dispatchQueue.async {
            UserDefaults.standard.set(value, forKey: forKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    
}
