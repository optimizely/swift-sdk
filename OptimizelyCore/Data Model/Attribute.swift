//
//  Attribute.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Attribute : Codable {
    var id:String = ""
    var key:String = ""
    var segmentId:String? = ""
    
    func Populate(dictionary:NSDictionary) {
        
        id = dictionary["id"] as! String
        key = dictionary["key"] as! String
        segmentId = dictionary["segmentId"] as? String
        
    }
    class func PopulateArray(array:NSArray) -> [Attribute]
    {
        var result:[Attribute] = []
        for item in array
        {
            let newItem = Attribute()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
}
