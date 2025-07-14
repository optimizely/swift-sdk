//
// Copyright 2022, Optimizely, Inc. and contributors 
// 
// Licensed under the Apache License, Version 2.0 (the "License");  
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at   
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

struct Holdout: Codable, ExperimentCore {
    enum Status: String, Codable {
        case draft = "Draft"
        case running = "Running"
        case concluded = "Concluded"
        case archived = "Archived"
    }
    
    var id: String
    var key: String
    var status: Status
    var variations: [Variation]
    var trafficAllocation: [TrafficAllocation]
    var audienceIds: [String]
    var audienceConditions: ConditionHolder?
    var includedFlags: [String]
    var excludedFlags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, key, status, variations, trafficAllocation, audienceIds, audienceConditions, includedFlags, excludedFlags
    }
    
    var variationsMap: [String: OptimizelyVariation] = [:]
    // replace with serialized string representation with audience names when ProjectConfig is ready
    var audiences: String = ""
    // Not necessary for HO
    var layerId: String = ""
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        status = try container.decode(Status.self, forKey: .status)
        variations = try container.decode([Variation].self, forKey: .variations)
        trafficAllocation = try container.decode([TrafficAllocation].self, forKey: .trafficAllocation)
        audienceIds = try container.decode([String].self, forKey: .audienceIds)
        audienceConditions = try container.decodeIfPresent(ConditionHolder.self, forKey: .audienceConditions)
        
        includedFlags = try container.decodeIfPresent([String].self, forKey: .includedFlags) ?? []
        excludedFlags = try container.decodeIfPresent([String].self, forKey: .excludedFlags) ?? []
    }
}

extension Holdout: Equatable {
    static func == (lhs: Holdout, rhs: Holdout) -> Bool {
        return lhs.id == rhs.id &&
        lhs.key == rhs.key &&
        lhs.status == rhs.status &&
        lhs.variations == rhs.variations &&
        lhs.layerId == rhs.layerId &&
        lhs.trafficAllocation == rhs.trafficAllocation &&
        lhs.audienceIds == rhs.audienceIds &&
        lhs.audienceConditions == rhs.audienceConditions &&
        lhs.includedFlags == rhs.includedFlags &&
        lhs.excludedFlags == rhs.excludedFlags
    }
}

extension Holdout {
    var isActivated: Bool {
        return status == .running
    }
}
