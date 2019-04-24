//
//  Array+Extension.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/16/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation


// MARK: - logical ops on eval array

typealias ThrowableCondition = () throws -> Bool
typealias ThrowableConditionList = [ThrowableCondition]

extension Array where Element == ThrowableCondition {
    
    // returns true only when all items are true and no-error
    func and() throws -> Bool {
        guard self.count > 0 else {
            throw OptimizelyError.conditionInvalidFormat("AND with empty items")
        }

        for eval in self {
            do {
                if try eval() == false {
                    return false
                }
            } catch let error as OptimizelyError {
                throw OptimizelyError.conditionInvalidFormat("AND with invalid items [\(error.reason)]")
            }
        }
        
        return true
    }
    
    // return try if any item is true (even with other error items)
    func or() throws -> Bool {
        var foundError: OptimizelyError? = nil
        
        for eval in self {
            do {
                if try eval() { return true }
            } catch let error as OptimizelyError {
                foundError = error
            }
        }
        
        if let error = foundError {
            throw OptimizelyError.conditionInvalidFormat("OR with invalid items [\(error.reason)]")
        }
        
        return false
    }
    
    // evalute the 1st item only
    func not() throws -> Bool {
        guard let eval = self.first else {
            throw OptimizelyError.conditionInvalidFormat("NOT with empty items")
        }

        do {
            let result = try eval()
            return !result
        } catch let error as OptimizelyError {
            throw OptimizelyError.conditionInvalidFormat("NOT with invalid items [\(error.reason)]")
        }
    }
}
