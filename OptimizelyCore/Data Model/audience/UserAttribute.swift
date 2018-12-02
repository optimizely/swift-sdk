//
//  UserAttribute.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/28/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class UserAttribute : Codable {
    var name:String = ""
    var type:String = ""
    var match:String? = ""
    var value:Any? = String()
    
    enum codedKeys : String, CodingKey {
        case name
        case type
        case match
        case value
    }
    
    init() {
        
    }
    
    required init(from decoder:Decoder) throws {
        guard let container = try? decoder.container(keyedBy: codedKeys.self) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: ""))
        }
        
        if let name = try? container.decode(String.self, forKey: .name) {
            self.name = name
        }
        if let type = try? container.decode(String.self, forKey: .type) {
            self.type = type
        }
        if let match = try? container.decode(String.self, forKey: .match) {
            self.match = match
        }
        if let value = try? container.decode(String.self, forKey: .value) {
            self.value = value
        }
        else if let value = try? container.decode(Double.self, forKey: .value) {
            self.value = value
        }
        else if let value = try? container.decode(Bool.self, forKey: .value) {
            self.value = value
        }
        else if let value = try? container.decode(Int.self, forKey: .value) {
            self.value = value
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: codedKeys.self)
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
