//
//  UserAttribute.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/28/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class UserAttribute : Condition, Codable {
    var name:String = ""
    var type:String = ""
    var match:String? = ""
    var value: Any = String()
    
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
    
    func Populate(dictionary:NSDictionary) {
        
        name = dictionary["name"] as! String
        type = dictionary["type"] as! String
        match = dictionary["match"] as? String
        value = dictionary["value"] as Any
    }
    
    func evaluate(config: ProjectConfig, attributes: Dictionary<String, String>) -> Bool? {
        return true
    }
    
    
}
