//
//  Experiment.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Experiment : Codable
{
    var id:String = ""
    var key:String = ""
    var status:String = ""
    var layerId:String = ""
    var trafficAllocation:[TrafficAllocation] = []
    var audienceIds:[String] = []
    var variations:[Variation] = []
    var forcedVariations:Dictionary<String,String>? = Dictionary<String,String>()
    
    func Populate(dictionary:NSDictionary) {
        
        id = dictionary["id"] as! String

        status = dictionary["status"] as! String
        key = dictionary["key"] as! String
        layerId = dictionary["layerId"] as! String
        trafficAllocation = TrafficAllocation.PopulateArray(array: dictionary["trafficAllocation"] as? NSArray ?? [])
        audienceIds = (dictionary["audienceIds"] as? NSArray ?? []) as! [String]
        variations = Variation.PopulateArray(array: dictionary["variations"] as? NSArray ?? [])
        forcedVariations = dictionary["forcedVariations"] as? Dictionary<String,String>
    }
    class func PopulateArray(array:NSArray) -> [Experiment]
    {
        var result:[Experiment] = []
        for item in array
        {
            let newItem = Experiment()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
