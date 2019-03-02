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
    
    // TODO: [Jae] spec does not require any of these fields. need to confirm
    //       Confirmed with Nikhil: "name" and "type" required for V4+
    
    enum ConditionType: String, Codable {
        case customAttribute = "custom_attribute"
    }
    
    enum ConditionMatch: String, Codable {
        case exact
        case exists
        case substring
        case lt
        case gt
    }
    
    var name: String
    var type: ConditionType
    var match: ConditionMatch?
    var value: AttributeValue?
}

extension UserAttribute {
    
    func evaluate(attributes: [String: Any]?) throws -> Bool {
        guard let attributes = attributes, !attributes.isEmpty else {
            // TODO: [Jae] confirm this
            return false
        }
        
        let attributeValue = attributes[name]
        
        let matchFinal = match ?? .exact       // legacy audience (default = "exact")
        
        if matchFinal != .exists, value == nil {
            throw OptimizelyError.conditionInvalidFormat("missing value (\(name)))")
        }
        
        switch matchFinal {
        case .exists:
            return attributeValue != nil
        case .exact:
            return try value!.isExactMatch(with: attributeValue)
        case .substring:
            return try value!.isSubstring(of: attributeValue)
        case .lt:
            // user attribute "less than" this condition value
            // so evaluate if this condition value "isGreater" than the user attribute value
            return try value!.isGreater(than: attributeValue)
        case .gt:
            // user attribute "greater than" this condition value
            // so evaluate if this condition value "isLess" than the user attribute value
            return try value!.isLess(than: attributeValue)
        }
    }
    
}

