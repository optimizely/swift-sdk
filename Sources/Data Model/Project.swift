//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

protocol ProjectProtocol {
    func evaluateAudience(audienceId: String, user: OptimizelyUserContext) throws -> Bool
}

// [REF]: datafile schema
//        https://github.com/optimizely/optimizely/blob/43454b726a2a8aab7dcd953999cf8e1902b09d4d/src/www/services/datafile_generator/schema.json

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
    var integrations: [Integration]?
    var typedAudiences: [Audience]?
    var featureFlags: [FeatureFlag]
    var botFiltering: Bool?
    var sendFlagDecisions: Bool?
    var sdkKey: String?
    var environmentKey: String?
    
    let logger = OPTLoggerFactory.getLogger()
    
    // Required since logger is not decodable
    enum CodingKeys: String, CodingKey {
        // V2
        case version, projectId, experiments, audiences, groups, attributes, accountId, events, revision
        // V3
        case anonymizeIP
        // V4
        case rollouts, integrations, typedAudiences, featureFlags, botFiltering, sendFlagDecisions, sdkKey, environmentKey
    }
    
    // Required since logger is not equatable
    static func == (lhs: Project, rhs: Project) -> Bool {
        return lhs.version == rhs.version && lhs.projectId == rhs.projectId && lhs.experiments == rhs.experiments &&
            lhs.audiences == rhs.audiences && lhs.groups == rhs.groups && lhs.attributes == rhs.attributes &&
            lhs.accountId == rhs.accountId && lhs.events == rhs.events && lhs.revision == rhs.revision &&
            lhs.anonymizeIP == rhs.anonymizeIP && lhs.rollouts == rhs.rollouts &&
            lhs.integrations == rhs.integrations && lhs.typedAudiences == rhs.typedAudiences &&
            lhs.featureFlags == rhs.featureFlags && lhs.botFiltering == rhs.botFiltering && lhs.sendFlagDecisions == rhs.sendFlagDecisions && lhs.sdkKey == rhs.sdkKey && lhs.environmentKey == rhs.environmentKey
    }
}

extension Project: ProjectProtocol {
    
    func evaluateAudience(audienceId: String, user: OptimizelyUserContext) throws -> Bool {
        guard let audience = getAudience(id: audienceId) else {
            throw OptimizelyError.conditionNoMatchingAudience(audienceId)
        }
        logger.d { () -> String in
            return LogMessage.audienceEvaluationStarted(audienceId, Utils.getConditionString(conditions: audience.conditionHolder)).description
        }
        
        let result = try audience.evaluate(project: self, user: user)
        logger.d(.audienceEvaluationResult(audienceId, result.description))
        return result
    }
    
}

// MARK: - Utils

extension Project {
    
    func getAudience(id: String) -> Audience? {
        return typedAudiences?.filter { $0.id == id }.first ??
            audiences.filter { $0.id == id }.first
    }
    
}
