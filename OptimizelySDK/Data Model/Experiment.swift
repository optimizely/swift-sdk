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

public class Experiment : NSObject, Codable
{
    enum Status: String, Codable {
        case Running
        case Launched
        case Paused
        case Not_started = "Not started"
        case Archived
    }
    private enum CodingKeys: String, CodingKey {
        case id
        case key
        case layerId
        case trafficAllocation
        case audienceIds
        case audienceConditions
        case variations
        case status
    }
    
    @objc public var id:String = ""
    @objc public var key:String = ""
    public var layerId:String = ""
    public var trafficAllocation:[TrafficAllocation] = []
    public var audienceIds:[String] = []
    public var audienceConditions:ConditionHolder?
    public var variations:[Variation] = []
    public var forcedVariations:Dictionary<String,String>? = Dictionary<String,String>()
    var status:Status = Status.Not_started
    var groupId:String = ""
    var groupPolicy:Policy = Policy.random
}
