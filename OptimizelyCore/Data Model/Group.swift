//
//  Group.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 11/27/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class Group : Codable {
    var id:String = ""
    var policy:String = ""
    var trafficAllocation:[TrafficAllocation] = []
    var experiments:[Experiment] = []
}
