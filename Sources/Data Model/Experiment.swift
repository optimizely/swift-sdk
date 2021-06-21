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

struct Experiment: Codable, OptimizelyExperiment {
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
    func getVariation(id: String) -> Variation? {
        return variations.filter { $0.id == id }.first
    }
    
    func getVariation(key: String) -> Variation? {
        return variations.filter { $0.key == key }.first
    }
    
    var isActivated: Bool {
        return status == .running
    }
    
    mutating func serializeAudiences(with audiencesMap: [String: String]) {
        guard let conditions = audienceConditions else { return }
        
        let serialized = conditions.serialized
        audiences = replaceAudienceIdsWithNames(string: serialized, audiencesMap: audiencesMap)
    }
    
    /// Replace audience ids with audience names
    ///
    /// example:
    /// - string: "(AUDIENCE(1) OR AUDIENCE(2)) AND AUDIENCE(3)"
    /// - replaced: "(\"us\" OR \"female\") AND \"adult\""
    ///
    /// - Parameter string: before replacement
    /// - Returns: string after replacement
    func replaceAudienceIdsWithNames(string: String, audiencesMap: [String: String]) -> String {
        let beginWord = "AUDIENCE("
        let endWord = ")"
        var keyIdx = 0
        var audienceId = ""
        var collect = false
        
        var replaced = ""
        for ch in string {
            // extract audience id in parenthesis (example: AUDIENCE("35") => "35")
            if collect {
                if String(ch) == endWord {
                    // output the extracted audienceId
                    replaced += "\"\(audiencesMap[audienceId] ?? audienceId)\""
                    collect = false
                    audienceId = ""
                } else {
                    audienceId += String(ch)
                }
                continue
            }
            
            // walk-through until finding a matching keyword "AUDIENCE("
            if ch == Array(beginWord)[keyIdx] {
                keyIdx += 1
                if keyIdx == beginWord.count {
                    keyIdx = 0
                    collect = true
                }
                continue
            } else {
                if keyIdx > 0 {
                    replaced += Array(beginWord)[..<keyIdx]
                }
                keyIdx = 0
            }
            
            // pass through other characters
            replaced += String(ch)
        }
        
        return replaced
    }
}
