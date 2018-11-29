//
//  TrafficAllocation.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class TrafficAllocation : Codable
{
    var entityId:String = ""
    var endOfRange:Int = 0
    
    func Populate(dictionary:NSDictionary) {
        
        entityId = dictionary["entityId"] as! String
        endOfRange = dictionary["endOfRange"] as! Int
    }
    class func PopulateArray(array:NSArray) -> [TrafficAllocation]
    {
        var result:[TrafficAllocation] = []
        for item in array
        {
            let newItem = TrafficAllocation()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
