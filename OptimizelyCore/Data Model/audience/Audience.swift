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
    var conditions:ConditionHolder?
    
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
        if let value = try? container?.decode(String.self, forKey: .conditions) {
            let data = value?.data(using: .utf8)
            if let holders = try? JSONDecoder().decode(ConditionHolder.self, from: data!) {
                conditions = holders
            }
            
        }
        else if let value = try? container?.nestedUnkeyedContainer(forKey: .conditions) {
            guard var value = value else { return }
            var conditionList = [ConditionHolder]()
            while !value.isAtEnd {
                if let condition = try? value.decode(ConditionHolder.self) {
                    conditionList.append(condition)
                }
            }
            conditions = ConditionHolder.array(conditionList)
        }
        
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: codingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        //try container.encode(conditions, forKey: .conditions)
    }

}
