/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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

protocol ProjectProtocol {
    func evaluateAudience(audienceId: String, attributes: OptimizelyAttributes?) throws -> Bool
}

//[REF]: datafile schema
//       https://github.com/optimizely/optimizely/blob/43454b726a2a8aab7dcd953999cf8e1902b09d4d/src/www/services/datafile_generator/schema.json

struct Project: Codable, Equatable {
    
    // V2
    var version: String
    var projectId: String
    var experiments: [Experiment]
    var audiences: [Audience]
    var groups: [Group]
    var attributes: [Attribute]
    var accountId: String
    var events: [Event]
    var revision: String
    // V3
    var anonymizeIP: Bool
    // V4
    var rollouts: [Rollout]
    var typedAudiences: [Audience]?
    var featureFlags: [FeatureFlag]
    var botFiltering: Bool?
}

extension Project: ProjectProtocol {
    
    func evaluateAudience(audienceId: String, attributes: OptimizelyAttributes?) throws -> Bool {
        guard let audience = getAudience(id: audienceId) else {
            throw OptimizelyError.conditionNoMatchingAudience(audienceId)
        }
        
        return try audience.evaluate(project: self, attributes: attributes)
    }
    
}

// MARK: - Utils

extension Project {
    
    func getAudience(id: String) -> Audience? {
        return typedAudiences?.filter { $0.id == id }.first ??
            audiences.filter { $0.id == id }.first
    }
    
}
