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

class FlagDecisionTable: Encodable {
    let key: String
    let schemas: SchemaCollection
    let body: [String: String]
    let bodyInArray: [(String, String)]
    var compressed: Bool?
    var compressedToRanges: Bool?
    
    // 0% or 100% rollout case. we can drop the dummy schema.
    var isFullRollout: Bool {
        schemas.array.count == 1 && body.count == 1
    }
    
    init(key: String, schemas: [DecisionSchema], bodyInArray: [(String, String)], compressed: Bool, toRanges: Bool = false) {
        self.key = key
        self.schemas = SchemaCollection(array: schemas)
        self.bodyInArray = bodyInArray
        self.body = Dictionary(uniqueKeysWithValues: bodyInArray)
        if compressed {
            self.compressed = true
        }
        if toRanges {
            self.compressedToRanges = true
        }
    }
    
    func decide(user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        let lookupInput = schemas.array.map { $0.makeLookupInput(user: user) }.joined()
        
        var decision: String?
        if compressedToRanges != nil {
            // dont-cares(*) converted to ranges. compare for ranges
            decision = lookupCompressedToRanges(lookupInput: lookupInput)
        } else if compressed != nil {
            // dont-cares(*) will be compared as is
            decision = lookupCompressed(lookupInput: lookupInput)
        } else {
            decision = body[lookupInput]
        }
        
        // TODO: a simplified decision for testing. a full decision info will be in the table output later.
        return OptimizelyDecision(variationKey: decision,
                                  enabled: true,
                                  variables: OptimizelyJSON.createEmpty(),
                                  ruleKey: lookupInput,   // pass it up for testing
                                  flagKey: key,
                                  userContext: user,
                                  reasons: [])
    }
    
    // MARK: - Lookup compressed
    func lookupCompressed(lookupInput: String) -> String? {
        for key in body.keys {
            if matchWithDontCare(dontCare: key, target: lookupInput) {
                return body[key]
            }
        }
        return nil
    }
    
    func matchWithDontCare(dontCare: String, target: String) -> Bool {
        if dontCare.count != target.count { return false }
        
        let dontCareArray = Array(dontCare)
        let targetArray = Array(target)
        for i in 0..<dontCareArray.count {
            let char = dontCareArray[i]
            if char == "*" { continue }
            if char != targetArray[i] { return false }
        }
        
        return true
    }
    
    // MARK: - Lookup compressed-to-ranges
    
    func lookupCompressedToRanges(lookupInput: String) -> String? {
        let rows = bodyInArray.map { $0.0 }
        let mappedToRange = bst(input: lookupInput, rows: rows, start: 0, end: bodyInArray.count - 1)
        return body[String(mappedToRange)]
    }

    func bst(input: String, rows: [String], start: Int, end: Int) -> String {
        if end == start {
            return rows[end]
        }
        if end == start + 1 {
            if input > rows[start] {
                return rows[end]
            } else {
                return rows[start]
            }
        }
        
        let middle = start + (end - start) / 2
        
        if input == rows[middle] {
            return rows[middle]
        } else if input < rows[middle] {
            return bst(input: input, rows: rows, start: start, end: middle)
        } else {
            return bst(input: input, rows: rows, start: middle, end: end)
        }
    }
    
    // MARK: - JSON encoding
    
    enum CodingKeys: String, CodingKey {
        case key
        case schemas
        case body
        case compressed
        case compressedToRanges
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(key, forKey: .key)
        try container.encode(body, forKey: .body)
        
        if !isFullRollout {
            try container.encode(schemas, forKey: .schemas)
        }
        
        if let comp = compressed, comp {
            try container.encode(comp, forKey: .compressed)
        }
        
        if let comp = compressedToRanges, comp {
            try container.encode(compressedToRanges, forKey: .compressedToRanges)
        }
    }
        
}

public class OptimizelyDecisionTables: Encodable {
    static var modeGenerateDecisionTable = false
    static var schemasForGenerateDecisionTable = [DecisionSchema]()
    static var inputForGenerateDecisionTable = ""
    static var insufficientDecisionInput = false
    public static var modeUseDecisionTable = false

    let sdkKey: String
    let tables: [String: FlagDecisionTable]
    let audiences: [Audience]
    
    init(sdkKey: String, tables: [String: FlagDecisionTable] = [:], audiences: [Audience] = []) {
        self.sdkKey = sdkKey
        self.tables = tables
        self.audiences = audiences
    }
        
    public func decide(user: OptimizelyUserContext,
                       key: String,
                       options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        guard let table = tables[key] else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .sdkNotReady)
        }
        
        return table.decide(user: user, options: options)
    }
    
    // JSON encoding
    
    var tablesArray: [FlagDecisionTable] {
        return Array(tables.values)
    }

    enum CodingKeys: String, CodingKey {
        case sdkKey
        case tablesArray = "decisions"
        case audiences
    }
    
    // this explicit encode method is required to support computed props (tablesArray) for coding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sdkKey, forKey: .sdkKey)
        try container.encode(tablesArray, forKey: .tablesArray)
        try container.encode(audiences, forKey: .audiences)
    }

}

// MARK: - Utils

extension OptimizelyDecisionTables {
    
    public func getRandomUserContext(optimizely: OptimizelyClient, key: String) -> OptimizelyUserContext {
        // random user-id for random bucketing
        
        let userId = String(Int.random(in: 10000..<99999))
        
        guard let table = tables[key] else {
            return OptimizelyUserContext(optimizely: optimizely, userId: userId)
        }

        // create random attribute values from audience-decision-schemas
        
        var attributes = [String: Any]()
        table.schemas.array.forEach { schema in
            if let schema = schema as? AudienceDecisionSchema {
                let randomAttributes = schema.randomAttributes(optimizely: optimizely)
                randomAttributes.forEach { (attributeKey, attributeValue) in
                    attributes[attributeKey] = attributeValue
                }
            }
        }
        
        return OptimizelyUserContext(optimizely: optimizely, userId: userId, attributes: attributes)
    }
    
}
