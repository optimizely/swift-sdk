//
//  Variable.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Variable : Codable
{
    var id:String = ""
    var value:String = ""
    
    func Populate(dictionary:NSDictionary) {
        
        id = dictionary["id"] as! String
        value = dictionary["value"] as! String
    }
    class func PopulateArray(array:NSArray) -> [Variable]
    {
        var result:[Variable] = []
        for item in array
        {
            let newItem = Variable()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
