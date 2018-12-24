/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
 *                                                                          *
 * Licensed under the Apache License, Version 2.0 (the "License");          *
 * you may not use this file except in compliance with the License.         *
 * You may obtain a copy of the License at                                  *
 *                                                                          *
 *    http://www.apache.org/licenses/LICENSE-2.0                            *
 *                                                                          *
 * Unless required by applicable law or agreed to in writing, software      *
 * distributed under the License is distributed on an "AS IS" BASIS,        *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
 * See the License for the specific language governing permissions and      *
 * limitations under the License.                                           *
 ***************************************************************************/


import Foundation

public class Experiment : Codable
{
    
    enum Status: String, Codable {
        case Running
        case Launched
        case Paused
        case Not_started = "Not started"
        case Archived
    }
    
    public var id:String = ""
    public var key:String = ""
    var status:Status = Status.Not_started
    public var layerId:String = ""
    public var trafficAllocation:[TrafficAllocation] = []
    public var audienceIds:[String] = []
    public var audienceConditions:ConditionHolder?
    public var variations:[Variation] = []
    public var forcedVariations:Dictionary<String,String>? = Dictionary<String,String>()
    private var _variationIdToVariationMap:[String:Variation]?
    var variationIdToVariationMap:[String:Variation] {
        if (_variationIdToVariationMap == nil) {
            _variationIdToVariationMap = [String:Variation]()
            _variationIdToVariationMap = self.generateVariationIdMapFromVariationsArray(variations: variations)
        }
        return _variationIdToVariationMap!
    }
    private var _variationKeyToVariationMap:[String:Variation]?
    var variationKeyToVariationMap:[String:Variation] {
        if (_variationKeyToVariationMap == nil) {
            _variationKeyToVariationMap = [String:Variation]()
            _variationKeyToVariationMap = self.generateVariationKeyMapFromVariationsArray(variations: variations)
        }
        return _variationKeyToVariationMap!
    }
}

extension Experiment {
    func getVariationForVariationId(variationId: String) -> Variation? {
        return self.variationIdToVariationMap[variationId]
    }
    func getVariationForVariationKey(variationKey: String) -> Variation? {
        return self.variationKeyToVariationMap[variationKey]
    }
}

//MARK:- Map generation methods
extension Experiment {
    func generateVariationIdMapFromVariationsArray(variations: [Variation]) -> [String:Variation] {
        var dict:[String:Variation] = [String:Variation]()
        for variation in variations {
            dict[variation.id] = variation
        }
        return dict
    }
    func generateVariationKeyMapFromVariationsArray(variations: [Variation]) -> [String:Variation] {
        var dict:[String:Variation] = [String:Variation]()
        for variation in variations {
            dict[variation.key] = variation
        }
        return dict
    }
}
