//
//  Rollout.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Rollout : Codable
{
    var experiments:[Experiment] = []
    var id:String = ""
    
    func Populate(dictionary:NSDictionary) {
        
        experiments = Experiment.PopulateArray(array: dictionary["experiments"] as! NSArray)
        id = dictionary["id"] as! String
    }
    class func PopulateArray(array:NSArray) -> [Rollout]
    {
        var result:[Rollout] = []
        for item in array
        {
            let newItem = Rollout()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}

