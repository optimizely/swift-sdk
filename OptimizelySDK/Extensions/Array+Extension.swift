/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

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
        var foundError: OptimizelyError?
        
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

        var error: OptimizelyError!
        do {
            let result = try eval()
            return !result
        } catch let err as OptimizelyError {
            error = OptimizelyError.conditionInvalidFormat("NOT with invalid items [\(err.reason)]")
        }
        throw error
    }
}
