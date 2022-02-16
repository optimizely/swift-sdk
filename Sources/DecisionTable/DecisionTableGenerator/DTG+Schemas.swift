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

// DecisionTableGenerator + Schemas

extension DecisionTableGenerator {
    
    // MARK: - DecisionSchemas (Uncomprssed)

    static func makeSchemasUncompressed(config: ProjectConfig, rules: [Experiment]) -> [DecisionSchema] {
        var schemas = [DecisionSchema]()
        
        // BucketDecisionSchema

        rules.forEach { rule in
            // rule-id (not key) is used for bucketing
            schemas.append(BucketDecisionSchema(bucketKey: rule.id, trafficAllocations: rule.trafficAllocation))
        }
        
        // AudienceDicisionSchema

        var allAudienceIds = [String]()
        rules.forEach { rule in
            rule.audienceIds.forEach { id in
                if !allAudienceIds.contains(id) {
                    allAudienceIds.append(id)
                }
            }
        }
        
        var numAudiences = 0
        for rule in rules {
            if rule.audienceIds.count > 0, let conditions = rule.audienceConditions {
                schemas.append(AudienceDecisionSchema(audiences: conditions))
                numAudiences += 1
            }
            
            let maxNumAudiences = 10
            if numAudiences >= maxNumAudiences {
                print("[ERROR] the number of audiences for this flag is too large (\(allAudienceIds.count))")
                print("[ERROR] truncated to (\(maxNumAudiences)) to move on")
                schemas.append(ErrorDecisionSchema(name: "Audience Overflow"))
                break
            }
        }

        print("\n   [Schemas]")
        schemas.forEach {
            print($0)
        }
        
        return schemas
    }
    
    // MARK: - DecisionSchemas (Compressed)

    static func makeSchemasCompressed(config: ProjectConfig, rules: [Experiment]) -> [DecisionSchema] {
        var schemas = [DecisionSchema]()
        
        // the order of the rules are important for compressing the table body
        // - the order of decision-flows. if decision made early, we can ignore all other schemas as "dont-care"
        
        rules.forEach { rule in
            // rule-id (not key) is used for bucketing
            schemas.append(BucketDecisionSchema(bucketKey: rule.id, trafficAllocations: rule.trafficAllocation))
                     
            if rule.audienceIds.count > 0, let conditions = rule.audienceConditions {
                schemas.append(AudienceDecisionSchema(audiences: conditions))
            }
        }
        
        // compress: remove all single-bucket BucketDecsionSchemas
        //           keep it if it's the only one schema for the flag (to create table body)
        
        if schemas.count > 1 {
            var compressed = schemas.filter { schema in
                if let schema = schema as? BucketDecisionSchema {
                    // only one bucket (0% or 100%) can be ignored
                    return schema.buckets.count > 1
                } else {
                    // keep all audience schemas
                    return true
                }
            }
            
            if compressed.isEmpty {
                compressed.append(schemas.first!)
            }
            
            schemas = compressed
        }

        print("\n   [Schemas]")
        schemas.forEach {
            print($0)
        }
        
        return schemas
    }

    // MARK: - DecisionSchemas (Compressed + Flat-Audiences)

    static func makeSchemasCompressedFlatAudiences(config: ProjectConfig, rules: [Experiment]) -> [DecisionSchema] {
        var schemas = [DecisionSchema]()
        
        // the order of the rules are important for compressing the table body
        // - the order of decision-flows. if decision made early, we can ignore all other schemas as "dont-care"
        
        rules.forEach { rule in
            // rule-id (not key) is used for bucketing
            schemas.append(BucketDecisionSchema(bucketKey: rule.id, trafficAllocations: rule.trafficAllocation))
                     
            if rule.audienceIds.count > 0, let conditions = rule.audienceConditions {
                schemas.append(AudienceDecisionSchema(audiences: conditions))
            }
        }
        
        // compress: remove all single-bucket BucketDecsionSchemas
        //           keep it if it's the only one schema for the flag (to create table body)
        
        if schemas.count > 1 {
            var compressed = schemas.filter { schema in
                if let schema = schema as? BucketDecisionSchema {
                    // only one bucket (0% or 100%) can be ignored
                    return schema.buckets.count > 1
                } else {
                    // keep all audience schemas
                    return true
                }
            }
            
            if compressed.isEmpty {
                compressed.append(schemas.first!)
            }
            
            schemas = compressed
        }

        print("\n   [Schemas]")
        schemas.forEach {
            print($0)
        }
        
        return schemas
    }

}
