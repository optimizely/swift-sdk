//
//  Variation.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Variation : Codable
{
    var variables:[Variable]? = []
    var id:String = ""
    var key:String = ""
    var featureEnabled:Bool? = false
    
    func Populate(dictionary:NSDictionary) {
        
        variables = Variable.PopulateArray(array: dictionary["variables"] as! NSArray)
        id = dictionary["id"] as! String
        key = dictionary["key"] as! String
        featureEnabled = dictionary["featureEnabled"] as? Bool
    }
    class func PopulateArray(array:NSArray) -> [Variation]
    {
        var result:[Variation] = []
        for item in array
        {
            let newItem = Variation()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
