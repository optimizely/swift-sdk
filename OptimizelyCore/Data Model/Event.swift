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
}
