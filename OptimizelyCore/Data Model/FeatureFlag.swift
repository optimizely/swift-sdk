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
}
