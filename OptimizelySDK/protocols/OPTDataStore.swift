//
//  OPTDataStore.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

/// Simple DataStore using key value.  This abstracts away the datastore layer. The datastore should take into account synchronization.
public protocol OPTDataStore {
    
    /// getItem - get an item by key.
    /// - Parameter forKey: key to lookup datastore value.
    /// - Returns: the value saved or nil
    func getItem(forKey:String) -> Any?
    /// saveItem - save the item to the datastore.
    /// - Parameter forKey: key to save value
    /// - Parameter value: value to save.
    func saveItem(forKey:String, value:Any)
}
