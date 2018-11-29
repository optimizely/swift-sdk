//
//  Event.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Event : Codable
{
    var experimentIds:[String] = []
    var id:String = ""
    var key:String = ""
    
    func Populate(dictionary:NSDictionary) {
        
        experimentIds = (dictionary["experimentIds"] as! NSArray) as! [String]
        id = dictionary["id"] as! String
        key = dictionary["key"] as! String
    }
    class func PopulateArray(array:NSArray) -> [Event]
    {
        var result:[Event] = []
        for item in array
        {
            let newItem = Event()
            newItem.Populate(dictionary: item as! NSDictionary)
            result.append(newItem)
        }
        return result
    }
    
}
