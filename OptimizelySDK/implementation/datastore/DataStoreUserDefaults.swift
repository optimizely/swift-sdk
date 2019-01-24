//
//  DataStoreUserDefaults.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

/// Implementation of OPTDataStore using standard UserDefaults.
/// This class should be used as a singleton.
public class DataStoreUserDefaults : OPTDataStore {
    static let dispatchQueue = DispatchQueue(label: "OPTDataStoreQueueUserDefaults")
    
    public func getItem(forKey: String) -> Any? {
        
        return DataStoreUserDefaults.dispatchQueue.sync {
            return UserDefaults.standard.object(forKey:forKey)
        }
    }
    
    public func saveItem(forKey: String, value: Any) {
        DataStoreUserDefaults.dispatchQueue.async {
            UserDefaults.standard.set(value, forKey: forKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    
}
