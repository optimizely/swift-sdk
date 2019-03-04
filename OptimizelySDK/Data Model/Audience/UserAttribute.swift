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
    
    enum CodingKeys: String, CodingKey {
        case name
        case type
        case match
        case value
    }
    
    init(from decoder: Decoder) throws {
        // no need for this custom decoder. only for debugging support for parse error
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.name = try container.decode(String.self, forKey: .name)
            self.type = try container.decode(ConditionType.self, forKey: .type)
            self.match = try container.decodeIfPresent(ConditionMatch.self, forKey: .match)
            self.value = try container.decodeIfPresent(AttributeValue.self, forKey: .value)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Faild to decode User Attribute)"))
        }
    }
    
    init(name: String, type: ConditionType, match: ConditionMatch?, value: AttributeValue?) {
        self.name = name
        self.type = type
        self.match = match
        self.value = value
    }
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

