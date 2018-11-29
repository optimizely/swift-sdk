//
//  FeatureVariable.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class FeatureVariable : Codable
{
    var defaultValue:String = ""
    var type:String = ""
    var id:String = ""
    var key:String = ""
    
    func Populate(dictionary:NSDictionary) {
        
        defaultValue = dictionary["defaultValue"] as! String
        type = dictionary["type"] as! String
        id = dictionary["id"] as! String
        key = dictionary["key"] as! String
    }
    class func PopulateArray(array:NSArray) -> [FeatureVariable]
    {
        var result:[FeatureVariable] = []
        for item in array
        {
            let newItem = FeatureVariable()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}

