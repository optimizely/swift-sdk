//
//  Condition.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/28/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

protocol Condition  {
    func evaluate(config:ProjectConfig, attributes:Dictionary<String,String>) -> Bool?
}

extension Condition {
    static func parseConditions(from container: inout UnkeyedDecodingContainer) throws -> Condition {
        let  op:String? = try container.decodeIfPresent(String.self)
        var conditions = [Condition]()
        
        while !container.isAtEnd {
            if let value = try? container.decode(String.self) {
                // arr.append(.string(value)) audience condition
            } else if let value = try? container.decode(UserAttribute.self) {
                conditions.append(value)
            } else if var value = try? container.nestedUnkeyedContainer() {
                let nested = try? Self.parseConditions(from: &value)
                if let nested = nested {
                    conditions.append(nested)
                }
            }
        }
        
        if let op = op {
            switch op {
            case "and":
                return AndCondition(conditions: conditions)
            case "or":
                return OrCondition(conditions: conditions)
            case "not":
                return NotCondition(condition: conditions.first)
            default:
                return OrCondition(conditions: conditions)
            }
        }

        return OrCondition(conditions: conditions)
    }

    static func Populate(from container: NSArray) throws -> Condition {
        let  op:String? = container.firstObject as? String
        
        var conditions = [Condition]()
        
        for (index, obj) in container.enumerated() {
            if (index == 0) {
                continue;
            }
            if obj is String {
                // arr.append(.string(value)) audience condition
            } else if obj is Dictionary<String, Any> {
                let userAttribute = UserAttribute()
                userAttribute.Populate(dictionary: obj as! NSDictionary)
            } else if obj is Array<Any> {
                let nested = try? Self.Populate(from: obj as! NSArray)
                if let nested = nested {
                    conditions.append(nested)
                }
            }
        }
        
        if let op = op {
            switch op {
            case "and":
                return AndCondition(conditions: conditions)
            case "or":
                return OrCondition(conditions: conditions)
            case "not":
                return NotCondition(condition: conditions.first)
            default:
                return OrCondition(conditions: conditions)
            }
        }
        
        return OrCondition(conditions: conditions)
    }

}

class AndCondition : Condition {
    var conditions:[Condition]?
    
    init(conditions:[Condition]?) {
        self.conditions = conditions
    }
    
    func evaluate(config:ProjectConfig, attributes:Dictionary<String,String>) -> Bool? {
        var foundNil = false
        for condition in conditions ?? [] {
            if let result = condition.evaluate(config: config, attributes: attributes) {
                if result == false {
                   return result
                }
            }
            else {
                foundNil = true
            }
        }
        
        if foundNil {
            return nil
        }
        
        return true
    }
}

class OrCondition : Condition {
    var conditions:[Condition]?

    init(conditions:[Condition]?) {
        self.conditions = conditions
    }

    func evaluate(config:ProjectConfig, attributes:Dictionary<String,String>) -> Bool? {
        for condition in conditions ?? [] {
            if condition.evaluate(config: config, attributes: attributes) == true {
                return true
            }
        }
        
        return false
    }
}

class NotCondition : Condition {
    var condition:Condition?
    
    init(condition:Condition?) {
        self.condition = condition
    }

    func evaluate(config:ProjectConfig, attributes:Dictionary<String,String>) -> Bool? {
        let result = condition?.evaluate(config: config, attributes: attributes)
        if let result = result {
          return result
        }
        return nil
    }
}

