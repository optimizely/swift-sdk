//
// Copyright 2019-2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

struct UserAttribute: Codable, Equatable {
    
    // MARK: - JSON parse
    
    var name: String?
    var type: String?
    var match: String?
    var value: AttributeValue?
    var stringRepresentation: String = ""

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case match
        case value
    }
    
    // MARK: - Forward compatable evaluation support
    
    enum ConditionType: String, Codable {
        case customAttribute = "custom_attribute"
        case thirdPartyDimension = "third_party_dimension"
    }
    
    enum ConditionMatch: String, Codable {
        case exact
        case exists
        case substring
        case lt
        case le
        case gt
        case ge
        case semver_eq
        case semver_lt
        case semver_le
        case semver_gt
        case semver_ge
        case qualified
    }
    
    var typeSupported: ConditionType? {
        guard let rawType = type else { return nil }
        
        return ConditionType(rawValue: rawType)
    }
    
    var matchSupported: ConditionMatch? {
        // legacy audience (default = "exact")
        guard let rawMatch = match else { return .exact }
        
        return ConditionMatch(rawValue: rawMatch)
    }
    
    // MARK: - init
    
    init(from decoder: Decoder) throws {
        // forward compatibility support: accept all string values for {type, match} not defined in enum
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.type = try container.decodeIfPresent(String.self, forKey: .type)
            self.match = try container.decodeIfPresent(String.self, forKey: .match)
            self.value = try container.decodeIfPresent(AttributeValue.self, forKey: .value)
            self.stringRepresentation = Utils.getConditionString(conditions: self)
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Faild to decode User Attribute)"))
        }
    }
    
    init(name: String, type: String, match: String?, value: AttributeValue?) {
        self.name = name
        self.type = type
        self.match = match
        self.value = value
        self.stringRepresentation = Utils.getConditionString(conditions: self)
    }
}

// MARK: - Evaluate

extension UserAttribute {
    
    func evaluate(user: OptimizelyUserContext) throws -> Bool {
        
        // invalid type - parsed for forward compatibility only (but evaluation fails)
        if typeSupported == nil {
            throw OptimizelyError.userAttributeInvalidType(stringRepresentation)
        }

        // invalid match - parsed for forward compatibility only (but evaluation fails)
        guard let matchFinal = matchSupported else {
            throw OptimizelyError.userAttributeInvalidMatch(stringRepresentation)
        }
        
        guard let nameFinal = name else {
            throw OptimizelyError.userAttributeInvalidName(stringRepresentation)
        }
        
        let attributes = user.attributes
        let rawAttributeValue = attributes[nameFinal] ?? nil // default to nil to avoid warning "coerced from 'Any??' to 'Any?'"
     
        if matchFinal == .exists {
            return !(rawAttributeValue is NSNull || rawAttributeValue == nil)
        }
        
        // all other matches requires valid value
        
        guard let value = value else {
            throw OptimizelyError.userAttributeNilValue(stringRepresentation)
        }
            
        if matchFinal == .qualified {
            // NOTE: name ("odp.audiences") and type("third_party_dimension") not used

            guard case .string(let strValue) = value else {
                throw OptimizelyError.evaluateAttributeInvalidCondition(stringRepresentation)
            }
            return user.isQualifiedFor(segment: strValue)
        }
        
        guard attributes.keys.contains(nameFinal) else {
            throw OptimizelyError.missingAttributeValue(stringRepresentation, nameFinal)
        }

        guard let rawAttributeValue = rawAttributeValue else {
            throw OptimizelyError.nilAttributeValue(stringRepresentation, nameFinal)
        }
                
        switch matchFinal {
        case .exact:
            return try value.isExactMatch(with: rawAttributeValue, condition: stringRepresentation, name: nameFinal)
        case .substring:
            return try value.isSubstring(of: rawAttributeValue, condition: stringRepresentation, name: nameFinal)
        case .lt:
            // user attribute "less than" this condition value
            // so evaluate if this condition value "isGreater" than the user attribute value
            return try value.isGreater(than: rawAttributeValue, condition: stringRepresentation, name: nameFinal)
        case .le:
            // user attribute "less than" or equal this condition value
            // so evaluate if this condition value "isGreater" than or equal the user attribute value
            return try value.isGreaterOrEqual(than: rawAttributeValue, condition: stringRepresentation, name: nameFinal)
        case .gt:
            // user attribute "greater than" this condition value
            // so evaluate if this condition value "isLess" than the user attribute value
            return try value.isLess(than: rawAttributeValue, condition: stringRepresentation, name: nameFinal)
        case .ge:
            // user attribute "greater than or equal" this condition value
            // so evaluate if this condition value "isLess" than or equal the user attribute value
            return try value.isLessOrEqual(than: rawAttributeValue, condition: stringRepresentation, name: nameFinal)
        // semantic versioning seems unique.  the comarison is to compare verion but the passed in version is the target version.
        case .semver_eq:
            let targetValue = try targetAsAttributeValue(value: rawAttributeValue, attribute: value, nameFinal: nameFinal)
            return try targetValue.isSemanticVersionEqual(than: value.stringValue)
        case .semver_lt:
            let targetValue = try targetAsAttributeValue(value: rawAttributeValue, attribute: value, nameFinal: nameFinal)
            return try targetValue.isSemanticVersionLess(than: value.stringValue)
        case .semver_le:
            let targetValue = try targetAsAttributeValue(value: rawAttributeValue, attribute: value, nameFinal: nameFinal)
            return try targetValue.isSemanticVersionLessOrEqual(than: value.stringValue)
        case .semver_gt:
            let targetValue = try targetAsAttributeValue(value: rawAttributeValue, attribute: value, nameFinal: nameFinal)
            return try targetValue.isSemanticVersionGreater(than: value.stringValue)
        case .semver_ge:
            let targetValue = try targetAsAttributeValue(value: rawAttributeValue, attribute: value, nameFinal: nameFinal)
            return try targetValue.isSemanticVersionGreaterOrEqual(than: value.stringValue)
        default:
            throw OptimizelyError.userAttributeInvalidMatch(stringRepresentation)
        }
    }
    
    private func targetAsAttributeValue(value: Any?, attribute: AttributeValue?, nameFinal: String) throws -> AttributeValue {
        guard let targetValue = AttributeValue(value: value), targetValue.isComparable(with: attribute!) else {
            throw OptimizelyError.evaluateAttributeInvalidCondition("attribute value \(nameFinal) invalid type")
         }

        return targetValue
    }
    
}
