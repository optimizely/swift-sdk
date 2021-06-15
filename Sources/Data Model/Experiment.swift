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

struct Experiment: Codable, Equatable, OptimizelyExperiment {
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
    
    var variationsMap: [String: OptimizelyVariation] {
        var map = [String: Variation]()
        variations.forEach {
            map[$0.key] = $0
        }
        return map
    }

    // replace with serialized string representation with audience names when ProjectConfig is ready
    var audiences: String = ""
    
    mutating func serializeAudiences(with globalAudiences: [Audience]) {
        guard let conditions = audienceConditions else { return }
        let serialized = conditions.serialized
        
    }
    
}

// MARK: - Utils

extension Experiment {
    func getVariation(id: String) -> Variation? {
        return variations.filter { $0.id == id }.first
    }
    
    func getVariation(key: String) -> Variation? {
        return variations.filter { $0.key == key }.first
    }
    
    var isActivated: Bool {
        return status == .running
    }
}
