//
// Copyright 2021, Optimizely, Inc. and contributors 
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

public class DecisionTableGenerator {
    
    public static func create(for optimizely: OptimizelyClient) -> DecisionTables {
        let config = optimizely.config!
        let flags = config.getFeatureFlags()
        let allExperiments = config.allExperiments
        
        for flag in flags.sorted { $0.key < $1.key } {
            var schemas = [DecisionSchema]()
                        
            var rules = flag.experimentIds.compactMap { expId in
                return allExperiments.filter { $0.id == expId }.first
            }
            
            let rollout = config.project.rollouts.filter { $0.id == flag.rolloutId }.first
            rules.append(contentsOf: rollout?.experiments ?? [])
            
            rules.forEach { rule in
                schemas.append(BucketDecisionSchema(bucketKey: rule.key, trafficAllocations: rule.trafficAllocation))
            }
            
            // merge [typedAudiences, audiences] in ProjectConfig to a single audiences array.
            // typedAudiences has a higher priority.
            var audiences = config.project.typedAudiences ?? []
            config.project.audiences.forEach { oldAudience in
                if audiences.filter({ newAudience in newAudience.id == oldAudience.id }).isEmpty {
                    guard oldAudience.id != "$opt_dummy_audience" else { return }
                    audiences.append(oldAudience)
                }
            }
            
            var allUserAttributes = [UserAttribute]()
            audiences.forEach { audience in
                let userAttributes = getUserAttributes(audience: audience)
                userAttributes.forEach { newItem in
                    if allUserAttributes.filter({ $0.name == newItem.name }).isEmpty {
                        allUserAttributes.append(newItem)
                    }
                }
            }
            
            allUserAttributes.forEach {
                schemas.append(AudienceDecisionSchema(audience: $0))
            }
            
            print("[Flag]: \(flag.key)")
            schemas.forEach {
                print($0)
            }
        }
        
        return DecisionTables()
    }
    
    static func getUserAttributes(audience: Audience) -> [UserAttribute] {
        var userAttributes = [UserAttribute]()
        getUserAttributes(conditionHolder: audience.conditionHolder, result: &userAttributes)
        return userAttributes
    }
    
    static func getUserAttributes(conditionHolder: ConditionHolder, result: inout [UserAttribute]) {
        switch conditionHolder {
        case .leaf(let leaf):
            if case .attribute(let userAttribute) = leaf {
                result.append(userAttribute)
            }
        case .array(let array):
            array.forEach {
                getUserAttributes(conditionHolder: $0, result: &result)
            }
        default:
            //print("ignored conditionHolder: \(conditionHolder)")
            break
        }
    }

}
