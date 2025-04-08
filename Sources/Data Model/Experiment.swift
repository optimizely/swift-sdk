//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

struct Experiment: Codable, ExperimentCore, OptimizelyExperiment{
    enum Status: String, Codable {
        case running = "Running"
        case launched = "Launched"
        case paused = "Paused"
        case notStarted = "Not started"
        case archived = "Archived"
    }
    
    var id: String
    var key: String
    var status: Status
    var layerId: String
    var variations: [Variation]
    var trafficAllocation: [TrafficAllocation]
    var audienceIds: [String]
    var audienceConditions: ConditionHolder?
    // datafile spec defines this as [String: Any]. Supposed to be [ExperimentKey: VariationKey]
    var forcedVariations: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case id, key, status, layerId, variations, trafficAllocation, audienceIds, audienceConditions, forcedVariations
    }

    // MARK: - OptimizelyConfig
    
    var variationsMap: [String: OptimizelyVariation] = [:]
    // replace with serialized string representation with audience names when ProjectConfig is ready
    var audiences: String = ""
}

extension Experiment: Equatable {
    static func == (lhs: Experiment, rhs: Experiment) -> Bool {
        return lhs.id == rhs.id &&
            lhs.key == rhs.key &&
            lhs.status == rhs.status &&
            lhs.layerId == rhs.layerId &&
            lhs.variations == rhs.variations &&
            lhs.trafficAllocation == rhs.trafficAllocation &&
            lhs.audienceIds == rhs.audienceIds &&
            lhs.audienceConditions == rhs.audienceConditions &&
            lhs.forcedVariations == rhs.forcedVariations
    }
}

// MARK: - Utils

extension Experiment {
    
    var isActivated: Bool {
        return status == .running
    }
    
}
