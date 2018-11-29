//
//  FeatureFlag.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class FeatureFlag : Codable
{
    var experimentIds:[String] = []
    var rolloutId:String? = ""
    var variables:[FeatureVariable] = []
    var id:String = ""
    var key:String = ""
    
    func Populate(dictionary:NSDictionary) {
        
        experimentIds = dictionary["experimentIds"] as! [String]
        rolloutId = dictionary["rolloutId"] as? String
        variables = FeatureVariable.PopulateArray(array: dictionary["variables"] as? NSArray ?? [])
        id = dictionary["id"] as! String
        key = dictionary["key"] as! String
    }
    class func PopulateArray(array:NSArray) -> [FeatureFlag]
    {
        var result:[FeatureFlag] = []
        for item in array
        {
            let newItem = FeatureFlag()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
