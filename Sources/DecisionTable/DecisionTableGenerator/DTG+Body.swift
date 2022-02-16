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

// DecisionTableGenerator + Body

extension DecisionTableGenerator {

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
       
    // MARK: - DecisionTable Body (Compressed)

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
    
    // MARK: - DecisionTable Body (Compressed + Flat-Audiences)

    static func makeTableBodyCompressedFlatAudiences(optimizely: OptimizelyClient, flagKey: String, schemas: [DecisionSchema]) -> (Bool, [(String, String)]) {
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

    // MARK: - Utils
    
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
