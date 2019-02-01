//
//  DataStore.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/20/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

/// A protocol that can be used as a queue or a stack with a backing datastore.  All items stored in a datastore queue stack must be of the same type.
public protocol DataStoreQueueStack {
    /// save item of type T
    /// - Parameter item: item to save. It is both append and push.
    func save(item:T)
    /// getFirstItem - queue peek
    /// - Returns: value of the first item added or nil.
    func getFirstItem() -> T?
    /// getLastItem - stack peek.
    /// - Returns: value of the last item added or nil.
    func getLastItem() -> T?
    /// removeFirstItem - queue get. It removes and returns the first item in the queue if it exists.
    /// - Returns: value of the first item in the queue.
    func removeFirstItem() -> T?
    /// removeLastItem - stack pop. It removes and returns the last item item added if it exists.
    /// - Returns: value of the last item pushed onto the stack.
    func removeLastItem() -> T?
    
    associatedtype T
}
