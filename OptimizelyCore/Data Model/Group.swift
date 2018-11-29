//
//  Group.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Group : Codable {
    var id:String = ""
    var policy:String = ""
    var trafficAllocation:[TrafficAllocation] = []
    var experiments:[Experiment] = []
    
    func Populate(dictionary:NSDictionary) {
        
        id = dictionary["id"] as! String
        policy = dictionary["policy"] as! String
        trafficAllocation = TrafficAllocation.PopulateArray(array: dictionary["trafficAllocation"] as! NSArray)
        experiments = Experiment.PopulateArray(array: dictionary["experiments"] as! NSArray)
    }
    
    class func PopulateArray(array:NSArray) -> [Group]
    {
        var result:[Group] = []
        for item in array
        {
            let newItem = Group()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
}
