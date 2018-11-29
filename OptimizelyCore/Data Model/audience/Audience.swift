//
//  Audience.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Audience : Codable {
    var id:String = ""
    var name:String = ""
    var conditions:Condition = OrCondition(conditions: nil)
    
    enum codingKeys : String, CodingKey {
        case id
        case name
        case conditions
    }
    
    init() {
        
    }
    
    required init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: codingKeys.self)
        
        if let value = try container?.decode(String.self, forKey: .id) {
            id = value
        }
        if let value = try container?.decode(String.self, forKey: .name) {
            name = value
        }
        if let value = try container?.decode(String.self, forKey: .conditions) {
            let data = value.data(using: .utf8)
            let array = try? JSONSerialization.jsonObject(with: data!, options: [])
            if let array = array as? Array<Any> {
                conditions = try AndCondition.Populate(from: array as NSArray)
            }
        }
        else if var value = try container?.nestedUnkeyedContainer(forKey: .conditions) {
            conditions = try AndCondition.parseConditions(from: &value)
        }
        
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: codingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        //try container.encode(conditions, forKey: .conditions)
    }

    
    func Populate(dictionary:NSDictionary) {
        
        id = dictionary["id"] as! String
        name = dictionary["name"] as! String
        conditions = try! AndCondition.Populate(from: dictionary["conditions"] as! NSArray)
    }
    
    class func PopulateArray(array:NSArray) -> [Audience]
    {
        var result:[Audience] = []
        for item in array
        {
            let newItem = Audience()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
}
