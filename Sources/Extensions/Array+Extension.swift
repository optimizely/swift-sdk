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
            if try eval() == false {
                return false
            }
        }
        
        return true
    }
    
    // return try if any item is true (even with other error items)
    func or() throws -> Bool {
        
        for eval in self {
            if try eval() { return true }
        }
        
        return false
    }
    
    // evalute the 1st item only
    func not() throws -> Bool {
        guard let eval = self.first else {
            throw OptimizelyError.conditionInvalidFormat("NOT with empty items")
        }

        let result = try eval()
        return !result
    }
}
