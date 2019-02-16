/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

struct UserAttribute: Codable, Equatable {
    var name: String
    var type: String
    var match: String?
    var value: AttributeValue
    
    func evaluate(attributes: [String: Any]) throws -> Bool {
        let attributeValue = attributes[name]
        
        switch match {
        case "exists":
            return attributeValue != nil
        case "exact":
            return try value.isExactMatch(with: attributeValue)
        case "substring":
            return try value.isSubstring(of: attributeValue)
        case "lt":
            // user attribute "less than" this condition value
            // so evaluate if this condition value "isGreater" than the user attribute value
            return try value.isGreater(than: attributeValue)
        case "gt":
            // user attribute "greater than" this condition value
            // so evaluate if this condition value "isLess" than the user attribute value
            return try value.isLess(than: attributeValue)
        default:
            return try value.isExactMatch(with: attributeValue)
        }
    }
    
}

