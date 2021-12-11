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
    
    public static func create(for optimizely: OptimizelyClient) -> OptimizelyDecisionTables {
        let config = optimizely.config!
        let flags = config.getFeatureFlags()
        
        var decisionTablesMap = [String: FlagDecisionTable]()
        var decisionTablesMapCompressed = [String: FlagDecisionTable]()
        var decisionTablesMapCompressedRanges = [String: FlagDecisionTable]()

        for flag in flags.sorted(by: { $0.key < $1.key }) {
            print("\n[Flag]: \(flag.key)")

            let rules = getAllRulesInOrderForFlag(config: config, flag: flag)
            
            var schemas = [DecisionSchema]()
            var bodyInArray = [(String, String)]()
            var compressed = false
            
            // simple table (uncompressed)
            
            schemas = makeSchemasUncompressed(config: config, rules: rules)
            bodyInArray = makeTableBodyUncompressed(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            decisionTablesMap[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray, compressed: false)

            // compressed (smaller schemas + dont-care body)
            
            schemas = makeSchemasCompressed(config: config, rules: rules)
            (compressed, bodyInArray) = makeTableBodyCompressed(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            decisionTablesMapCompressed[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray, compressed: compressed)

            // compressed with ranges (for supporting client hash)
            
            if compressed {
                bodyInArray = convertTableBodyCompressedToRanges(bodyInArray: bodyInArray)
            }
            decisionTablesMapCompressedRanges[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray, compressed: compressed)
        }
    
        let audiences = makeAllAudiences(config: config)
        
        let decisionTables = OptimizelyDecisionTables(tables: decisionTablesMap, audiences: audiences)
        saveDecisionTablesToFile(sdkKey: optimizely.sdkKey, decisionTables: decisionTables, suffix: "table")
        
        let decisionTablesCompressed = OptimizelyDecisionTables(tables: decisionTablesMapCompressed, audiences: audiences)
        saveDecisionTablesToFile(sdkKey: optimizely.sdkKey, decisionTables: decisionTablesCompressed, suffix: "table-compressed")
        
        let decisionTablesCompressedRanges = OptimizelyDecisionTables(tables: decisionTablesMapCompressedRanges, audiences: audiences)
        saveDecisionTablesToFile(sdkKey: optimizely.sdkKey, decisionTables: decisionTablesCompressedRanges, suffix: "table-compressed-ranges")

        // set decision table for decide tests
        // optimizely.decisionTables = decisionTables
        optimizely.decisionTables = decisionTablesCompressedRanges

        return decisionTables
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
    
}

// MARK: - DecisionTable Body (Uncompressed)

extension DecisionTableGenerator {
    
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
    
}

// MARK: - DecisionSchemas (Comprssed)

extension DecisionTableGenerator {
    
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

}

// MARK: - DecisionTable Body (Compressed)

extension DecisionTableGenerator {
    
    static func makeTableBodyCompressed(optimizely: OptimizelyClient, flagKey: String, schemas: [DecisionSchema]) -> (Bool, [(String, String)]) {
        var bodyInArray = [(String, String)]()
        var compressed = false

        guard let firstSchema = schemas.first else {
            return (compressed, bodyInArray)
        }
        
        let user = OptimizelyUserContext(optimizely: optimizely, userId: "any-user-id")

        // TODO: change this to depth-first (recursion), so decision table looks like increasing order
        
        var sets = [String]()
        sets.append(contentsOf: firstSchema.allLookupInputs)
        
        while sets.count > 0 {
            var item = sets.removeFirst()
    
            // print("compressed: item = \(item)")
            
            // check early decision with the current input.
            // if we can make a decision with it, it means we do not need the rest of the schemas.
            // mark the rest of schemas as "dont-care" and prune the input.
            if let decision = makeDecisionForInput(user: user, flagKey: flagKey, schemas: schemas, input: item) {
                let decisionString = decision.variationKey ?? "nil"
                let remainingCount = schemas.count - item.count
                if remainingCount > 0 {
                    item += String(repeating: "*", count: remainingCount)
                    compressed = true
                }
                bodyInArray.append((item, decisionString))
                
                // print("compressed:    decision --> \(decisionString)")
            } else {
                let index = item.count
                let schema = schemas[index]
                sets.append(contentsOf: schema.allLookupInputs.map { item + $0 })
                
                // print("compressed:    append \(schema.allLookupInputs.map { item + $0 })")
            }
        }
        
        return (compressed, bodyInArray)
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

    static func convertTableBodyCompressedToRanges(bodyInArray: [(String, String)]) -> [(String, String)] {
        var converted = [(String, String)]()
        
        bodyInArray.forEach { (input, decision) in
            var numbered = input
            
            // contiguous "*"s at the tail are convereted to "...1111" to find the upper ranges
            
            var tailCnt = 0
            for char in Array(input).reversed() {
                if char == "*" {
                    tailCnt += 1
                } else {
                    break
                }
            }
            if tailCnt > 0 {
                let range = input.index(input.endIndex, offsetBy: -tailCnt)...
                numbered.replaceSubrange(range, with: String(repeating: "1", count: tailCnt))
            }
            
            // extend remaing dont-cares ("*") to (0,1) combos
            
            var combos = [[String]]()
            let source = numbered.map { String($0) }
            extendDontCares(source: source, index: 0, current: [], combos: &combos)
            
            let comboStrs = combos.map { $0.joined() }
            comboStrs.forEach {
                converted.append(($0, decision))
            }
            
        }
        
        // sorted to increasing order for BST
        
        return converted.sorted { $0.0 < $1.0 }
    }
    
    static func extendDontCares(source: [String], index: Int, current: [String], combos: inout [[String]]) {
        if index == source.count {
            combos.append(current)
            return
        }
        
        let char = source[index]
        if char == "*" {
            extendDontCares(source: source, index: index + 1, current: current + ["1"], combos: &combos)
            extendDontCares(source: source, index: index + 1, current: current + ["0"], combos: &combos)
        } else {
            extendDontCares(source: source, index: index + 1, current: current + [char], combos: &combos)
        }
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
    
    static func makeAllAudiences(config: ProjectConfig) -> [Audience] {
        let project = config.project!

        var audiences = project.typedAudiences ?? []
        project.audiences.forEach { oldAudience in
            if audiences.filter({ newAudience in newAudience.id == oldAudience.id }).isEmpty {
                guard oldAudience.id != "$opt_dummy_audience" else { return }
                audiences.append(oldAudience)
            }
        }

        return audiences
    }
    
    static func saveDecisionTablesToFile(sdkKey: String, decisionTables: OptimizelyDecisionTables, suffix: String) {
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
        
        let filename = "\(sdkKey).\(suffix)"
        let urlText = url.appendingPathComponent(filename)
        let contentsInText = decisionTableInTextFormat(sdkKey: sdkKey, decisionTables: decisionTables)
        try? contentsInText.write(to: urlText, atomically: true, encoding: .utf8)
        
        let urlJson = url.appendingPathComponent("\(filename).json")
        let contentsInJson = decisionTableInJSONFormat(sdkKey: sdkKey, decisionTables: decisionTables)
        try? contentsInJson.write(to: urlJson, atomically: true, encoding: .utf8)
    }
    
    static func decisionTableInTextFormat(sdkKey: String, decisionTables: OptimizelyDecisionTables) -> String {
        var contents = "SDKKey: \(sdkKey)\n"
        
        let sortedFlagKeys = decisionTables.tables.keys.sorted { $0 < $1 }
        sortedFlagKeys.forEach { flagKey in
            let table = decisionTables.tables[flagKey]!
            
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
        
        if decisionTables.audiences.count > 0 {
            contents += "\n\n[Audiences]\n"
            decisionTables.audiences.forEach { audience in
                contents += "   \(audience.name) (\(audience.id)) \(audience.conditions)\n"
            }
        }

        return contents
    }

    static func decisionTableInJSONFormat(sdkKey: String, decisionTables: OptimizelyDecisionTables) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let data = try encoder.encode(decisionTables)
            let str = String(data: data, encoding: .utf8) ?? "invalid JSON data"
            return str
        } catch {
            return "JSON failed: \(error)"
        }
    }

}
