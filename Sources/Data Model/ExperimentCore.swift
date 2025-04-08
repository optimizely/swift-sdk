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

protocol ExperimentCore: OptimizelyExperiment {
    var audiences: String { get set }
    var layerId: String { get }
    var variations: [Variation] { get }
    var trafficAllocation: [TrafficAllocation] { get }
    var audienceIds: [String] { get }
    var audienceConditions: ConditionHolder? { get }
}

// Shared utilities in an extension
extension ExperimentCore {
    func getVariation(id: String) -> Variation? {
        return variations.filter { $0.id == id }.first
    }
    
    func getVariation(key: String) -> Variation? {
        return variations.filter { $0.key == key }.first
    }
    
    func replaceAudienceIdsWithNames(string: String, audiencesMap: [String: String]) -> String {
        let beginWord = "AUDIENCE("
        let endWord = ")"
        var keyIdx = 0
        var audienceId = ""
        var collect = false
        
        var replaced = ""
        for ch in string {
            if collect {
                if String(ch) == endWord {
                    replaced += "\"\(audiencesMap[audienceId] ?? audienceId)\""
                    collect = false
                    audienceId = ""
                } else {
                    audienceId += String(ch)
                }
                continue
            }
            
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
            
            replaced += String(ch)
        }
        
        return replaced
    }
    
    mutating func serializeAudiences(with audiencesMap: [String: String]) {
        guard let conditions = audienceConditions else { return }
        
        let serialized = conditions.serialized
        audiences = replaceAudienceIdsWithNames(string: serialized, audiencesMap: audiencesMap)
    }
}
