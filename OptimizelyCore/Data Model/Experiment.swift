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
    var audienceConditions:ConditionHolder?
    var variations:[Variation] = []
    var forcedVariations:Dictionary<String,String>? = Dictionary<String,String>()
}
