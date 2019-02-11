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

struct UserAttribute: Codable {
    var name: String
    var type: String
    var value: Any
    var match: String?
    
    enum CodingKeys : String, CodingKey {
        case name
        case type
        case match
        case value
    }
    
    init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
        
        if let match = try? container.decode(String.self, forKey: .match) {
            self.match = match
        }
        
        if let value = try? container.decode(String.self, forKey: .value) {
            self.value = value
        } else if let value = try? container.decode(Double.self, forKey: .value) {
            self.value = value
        } else if let value = try? container.decode(Bool.self, forKey: .value) {
            self.value = value
        } else if let value = try? container.decode(Int.self, forKey: .value) {
            self.value = value
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode Condition"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(match, forKey: .match)
        if value is String {
            try container.encode(value as! String, forKey: .value)
        }
        else if value is Double {
            try container.encode(value as! Double, forKey: .value)
        }
        else if value is Int {
            try container.encode(value as! Int, forKey: .value)
        }
        else if value is Bool {
            try container.encode(value as! Bool, forKey: .value)
        }
    }
    
    func evaluate(config: ProjectConfig, attributes: Dictionary<String, Any>) -> Bool? {
        let attributeValue = attributes[name]
        
        func convertToDouble(v:Any?) -> Double? {
            if v is Int {
                return Double(v as! Int)
            }
            if v is Double {
                return (v as! Double)
            }
            
            return nil
        }

        func exactMatch<T:Equatable>(value:T) -> Bool? {
            if let value = convertToDouble(v: value), let attributeValue = convertToDouble(v: attributeValue) {
                return attributeValue == value
            }
            
            if let attrValue = attributeValue as? T {
                return value == attrValue
            }
            return nil
         }
        
        func greaterThan() -> Bool? {
            if let value = convertToDouble(v: value), let attributeValue = convertToDouble(v: attributeValue) {
                return attributeValue > value
            }
 
            return nil
        }
        
        func lessThan() -> Bool? {
            if let value = convertToDouble(v: value), let attrValue = convertToDouble(v: attributeValue) {
                return attrValue < value
            }
            return nil
        }
        
        func exists() -> Bool? {
            if let _ = attributeValue {
                return true
            }
            return false
        }
        
        func substring() -> Bool? {
            if let value = value as? String, let attributeValue = attributeValue as? String {
                return attributeValue.contains(value)
            }
            return nil
        }
        
        func matcher<T:Equatable>(value:T) -> Bool? {
            switch match {
            case "substring":
                return substring()
            case "exists":
                return exists()
            case "exact":
                return exactMatch(value: value)
            case "lt":
                return lessThan()
            case "gt":
                return greaterThan()
            default:
                return exactMatch(value: value)
            }

        }

        if value is String {
            return matcher(value: value as! String)
        }
        else if value is Double {
            return matcher(value: value as! Double)
        }
        else if value is Int {
            return matcher(value: value as! Int)
        }
        else if value is Bool {
            return matcher(value: value as! Bool)
        }

        return nil
    }
    
}
