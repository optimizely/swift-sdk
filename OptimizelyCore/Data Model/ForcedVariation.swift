//
//  ForcedVariation.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class ForcedVariation
{
    var map:NSDictionary = NSDictionary()
    
    subscript(key: String) -> Any? {
        get {
            return map[key]
        }        
    }
    
    func Populate(dictionary:NSDictionary) {
            map = dictionary
    }
    class func PopulateArray(array:NSArray) -> [ForcedVariation]
    {
        var result:[ForcedVariation] = []
        for item in array
        {
            let newItem = ForcedVariation()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
