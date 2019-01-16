//
//  OPTDataStore.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 1/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

public protocol OPTDataStore {
    
    func getItem(forKey:String) -> Any?
    func saveItem(forKey:String, value:Any)
}
