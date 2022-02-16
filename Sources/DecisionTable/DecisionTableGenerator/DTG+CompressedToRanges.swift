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

// Compressed to Ranges

extension DecisionTableGenerator {
    
    static func createDecisionTableCompressedToRanges(optimizely: OptimizelyClient) -> OptimizelyDecisionTables {
        let config = optimizely.config!
        let flags = config.getFeatureFlags()
        
        var decisionTablesMap = [String: FlagDecisionTable]()
        
        for flag in flags.sorted(by: { $0.key < $1.key }) {
            print("\n[Flag]: \(flag.key)")
            
            let rules = getAllRulesInOrderForFlag(config: config, flag: flag)
            
            let schemas = makeSchemasCompressed(config: config, rules: rules)
            var (compressed, bodyInArray) = makeTableBodyCompressed(optimizely: optimizely, flagKey: flag.key, schemas: schemas)
            if compressed {
                bodyInArray = convertTableBodyCompressedToRanges(bodyInArray: bodyInArray)
            }
            decisionTablesMap[flag.key] = FlagDecisionTable(key: flag.key, schemas: schemas, bodyInArray: bodyInArray, compressed: compressed)
        }
        
        let audiences = makeAllAudiences(config: config)
        let sdkKey = optimizely.sdkKey
        
        let decisionTables = OptimizelyDecisionTables(sdkKey: sdkKey, tables: decisionTablesMap, audiences: audiences)
        saveDecisionTablesToFile(sdkKey: sdkKey, decisionTables: decisionTables, suffix: "table-compressed-ranges")
        
        return decisionTables
    }
    
    // MARK: - Utils
    
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
