//
//  DataStore.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/20/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public protocol DataStore {
    func save(item:T)
    func getFirstItem() -> T?
    func getLastItem() -> T?
    func removeFirstItem() -> T?
    func removeLastItem() -> T?
    
    associatedtype T
}
