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
    
    public static func create(for optimizely: OptimizelyClient, compress: Bool) -> DecisionTables {
        let config = optimizely.config!
        let flags = config.getFeatureFlags()
        
        var decisionTablesMap = [String: FlagDecisionTable]()
        
        for flag in flags.sorted(by: { $0.key < $1.key }) {
            print("\n[Flag]: \(flag.key)")

            let rules = getAllRulesInOrderForFlag(config: config, flag: flag)
            
            var schemas: [DecisionSchema]
            var bodyInArray: [(String, String)]
            if compress {
                schemas = makeSchemasCompressed(config: config, rules: rules)
                bodyInArray = makeTableBodyCompressed(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            } else {
                schemas = makeSchemasUncompressed(config: config, rules: rules)
                bodyInArray = makeTableBodyUncompressed(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            }
                        
            decisionTablesMap[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray)
        }
    
        optimizely.decisionTables = DecisionTables(tables: decisionTablesMap)
        saveDecisionTablesToFile(optimizely: optimizely, compress: compress)
        
        return optimizely.decisionTables
    }
    
}

// MARK: - DecisionSchemas (Uncomprssed)

extension DecisionTableGenerator {
    
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
        
        for (index, audienceId) in allAudienceIds.enumerated() {
            guard let audience = config.getAudience(id: audienceId) else { continue }
            schemas.append(AudienceDecisionSchema(audience: audience))
            
            let maxNumAudiences = 10
            if index >= maxNumAudiences - 1 {
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
    
}

// MARK: - DecisionTable Body (Uncompressed)

extension DecisionTableGenerator {
    
    static func makeTableBodyUncompressed(optimizely: OptimizelyClient, flagKey: String, schemas: [DecisionSchema]) -> [(String, String)] {
        let body = makeAllInputs(schemas: schemas)
        
        var bodyInArray = [(String, String)]()
        
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "any-user-id")
        DecisionTables.modeGenerateDecisionTable = true
        body.forEach { input in
            DecisionTables.schemasForGenerateDecisionTable = schemas
            DecisionTables.inputForGenerateDecisionTable = input
            
            let decision = user.decide(key: flagKey)
            let decisionString = decision.variationKey ?? "nil"
            bodyInArray.append((input, decisionString))
        }
        DecisionTables.modeGenerateDecisionTable = false
        
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
    
}

// MARK: - DecisionSchemas (Comprssed)

extension DecisionTableGenerator {
    
    static func makeSchemasCompressed(config: ProjectConfig, rules: [Experiment]) -> [DecisionSchema] {
        var schemas = [DecisionSchema]()
        
        var allAudienceIds = Set<String>()

        rules.forEach { rule in
            // rule-id (not key) is used for bucketing
            schemas.append(BucketDecisionSchema(bucketKey: rule.id, trafficAllocations: rule.trafficAllocation))
                        
            rule.audienceIds.forEach { id in
                if !allAudienceIds.contains(id) {
                    guard let audience = config.getAudience(id: id) else { return }
                    schemas.append(AudienceDecisionSchema(audience: audience))
                }
            }
            
            allAudienceIds = allAudienceIds.union(rule.audienceIds)
        }
        
        // we need at least one schema (to create table body)
        if schemas.count > 1 {
            schemas = schemas.filter { schema in
                if let schema = schema as? BucketDecisionSchema {
                    // only one bucket (0% or 100%) can be ignored
                    return schema.buckets.count > 1
                } else {
                    // keep all audience schemas
                    return true
                }
            }
        }

        print("\n   [Schemas]")
        schemas.forEach {
            print($0)
        }
        
        return schemas
    }

}

// MARK: - DecisionTable Body (Compressed)

extension DecisionTableGenerator {
    
    static func makeTableBodyCompressed(optimizely: OptimizelyClient, flagKey: String, schemas: [DecisionSchema]) -> [(String, String)] {
        let body = makeAllInputs(schemas: schemas)
        
        var bodyInArray = [(String, String)]()
        
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "any-user-id")
        DecisionTables.modeGenerateDecisionTable = true
        body.forEach { input in
            DecisionTables.schemasForGenerateDecisionTable = schemas
            DecisionTables.inputForGenerateDecisionTable = input
            
            let decision = user.decide(key: flagKey)
            let decisionString = decision.variationKey ?? "nil"
            bodyInArray.append((input, decisionString))
        }
        DecisionTables.modeGenerateDecisionTable = false
        
        print("\n   [DecisionTable]")
        bodyInArray.forEach { (input, decisionString) in
            print("      \(input) -> \(decisionString)")
        }
        
        return bodyInArray
    }

}

// MARK: - Utils

extension DecisionTableGenerator {
    
    static func getAllRulesInOrderForFlag(config: ProjectConfig, flag: FeatureFlag) -> [Experiment] {
        var rules = flag.experimentIds.compactMap { expId in
            return config.allExperiments.filter { $0.id == expId }.first
        }
        
        let rollout = config.project.rollouts.filter { $0.id == flag.rolloutId }.first
        rules.append(contentsOf: rollout?.experiments ?? [])

        return rules
    }
    
    static func saveDecisionTablesToFile(optimizely: OptimizelyClient, compress: Bool) {
        guard var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("FileManager saveDecisionTablesToFile error")
            return
        }
        
        url.appendPathComponent("decisionTables")
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("FileManager saveDecisionTablesToFile create folder error")
                return
            }
        }
        
        let filename = "\(optimizely.sdkKey)" + (compress ? ".table-compressed" : ".table")
        url.appendPathComponent(filename)
        
        var contents = "SDKKey: \(optimizely.sdkKey)\n"
        
        let tables = optimizely.decisionTables.tables
        let sortedFlagKeys = tables.keys.sorted { $0 < $1 }
        sortedFlagKeys.forEach { flagKey in
            let table = tables[flagKey]!
            
            contents += "\n[Flag]: \(flagKey)\n"
            contents += "\n   [Schemas]\n"
            table.schemas.forEach {
                contents += "\($0)\n"
            }
            
            contents += "\n   [DecisionTable]\n"
            
            table.bodyInArray.forEach { (input, decision) in
                contents += "      \(input) -> \(decision)\n"
            }
        }
        
        try? contents.write(to: url, atomically: true, encoding: .utf8)
    }

}
