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

// Uncompressed

extension DecisionTableGenerator {

    static func createDecisionTableUncompressed(optimizely: OptimizelyClient) -> OptimizelyDecisionTables {
        let config = optimizely.config!
        let flags = config.getFeatureFlags()

        var decisionTablesMap = [String: FlagDecisionTable]()

        for flag in flags.sorted(by: { $0.key < $1.key }) {
            print("\n[Flag]: \(flag.key)")

            let rules = getAllRulesInOrderForFlag(config: config, flag: flag)
            
            let schemas = makeSchemasUncompressed(config: config, rules: rules)
            let bodyInArray = makeTableBodyUncompressed(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            decisionTablesMap[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray, compressed: false)
        }
    
        let audiences = makeAllAudiences(config: config)
        let sdkKey = optimizely.sdkKey
        
        let decisionTables = OptimizelyDecisionTables(sdkKey: sdkKey, tables: decisionTablesMap, audiences: audiences)
        saveDecisionTablesToFile(sdkKey: sdkKey, decisionTables: decisionTables, suffix: "table")
        
        return decisionTables
    }

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
    
    // MARK: - DecisionTable Body (Uncompressed)

    static func makeTableBodyUncompressed(optimizely: OptimizelyClient, flagKey: String, schemas: [DecisionSchema]) -> [(String, String)] {
        let body = makeAllInputs(schemas: schemas)
        
        var bodyInArray = [(String, String)]()
        
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "any-user-id")
        OptimizelyDecisionTables.modeGenerateDecisionTable = true
        body.forEach { input in
            OptimizelyDecisionTables.schemasForGenerateDecisionTable = schemas
            OptimizelyDecisionTables.inputForGenerateDecisionTable = input
            OptimizelyDecisionTables.insufficientDecisionInput = false

            let decision = user.decide(key: flagKey)
            let decisionString = decision.variationKey ?? "nil"
            bodyInArray.append((input, decisionString))
        }
        OptimizelyDecisionTables.modeGenerateDecisionTable = false
        
        print("\n   [DecisionTable]")
        bodyInArray.forEach { (input, decisionString) in
            print("      \(input) -> \(decisionString)")
        }
        
        return bodyInArray
    }
    
    static func makeAllInputs(schemas: [DecisionSchema]) -> [String] {
        var sets = [String]()
        
        guard let firstSchema = schemas.first else {
            return sets
        }
        
        sets.append(contentsOf: firstSchema.allLookupInputs)
        
        while sets.count > 0 {
            var item = sets[0]
            if item.count == schemas.count {
                break
            }
                
            item = sets.removeFirst()
            let index = item.count
            let schema = schemas[index]
            sets.append(contentsOf: schema.allLookupInputs.map { item + $0 })
        }
        
        return sets
    }

    static func makeDecisionForInput(user: OptimizelyUserContext, flagKey: String, schemas: [DecisionSchema], input: String) -> OptimizelyDecision? {
        OptimizelyDecisionTables.schemasForGenerateDecisionTable = schemas
        OptimizelyDecisionTables.inputForGenerateDecisionTable = input
        OptimizelyDecisionTables.insufficientDecisionInput = false

        OptimizelyDecisionTables.modeGenerateDecisionTable = true
        let decision = user.decide(key: flagKey)
        OptimizelyDecisionTables.modeGenerateDecisionTable = false
        
        if OptimizelyDecisionTables.insufficientDecisionInput {
            return nil
        } else {
            return decision
        }
    }

}
