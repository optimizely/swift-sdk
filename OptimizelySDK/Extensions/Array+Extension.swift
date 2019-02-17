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
            throw OptimizelyError.conditionInvalidFormat(#function)
        }

        for eval in self {
            if try eval() == false {
                return false
            }
        }
        
        return true
    }
    
    // return trye if any item is true (even with other error items)
    func or() throws -> Bool {
        var foundError = false
        
        for eval in self {
            do {
                if try eval() { return true }
            } catch {
                foundError = true
            }
        }
        
        if foundError {
            throw OptimizelyError.conditionInvalidFormat("logical OR with invalid items")
        }
        
        return false
    }
    
    // evalute the 1st item only
    func not() throws -> Bool {
        guard let eval = self.first else {
            throw OptimizelyError.conditionInvalidFormat(#function)
        }

        let result = try eval()
        return !result
    }
}
