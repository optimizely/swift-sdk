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
        case running = "Running"
        case archived = "Archived"
        case draft = "Draft"
        case concluded = "Concluded"
    }
    
    var id: String
    var key: String
    var status: Status
    var layerId: String
    var variations: [Variation]
    var trafficAllocation: [TrafficAllocation]
    var audienceIds: [String]
    var audienceConditions: ConditionHolder?
    var excludedFlags: [String]
    var includedFlags: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, key, status, layerId, variations, trafficAllocation, audienceIds, audienceConditions, includedFlags, excludedFlags
    }
    
    // replace with serialized string representation with audience names when ProjectConfig is ready
    var audiences: String = ""
}


extension Holdout {
    var isActivated: Bool {
        return status == .running
    }
}
