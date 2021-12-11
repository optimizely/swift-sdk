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
    let schemas: [DecisionSchema]
    let body: [String: String]
    let bodyInArray: [(String, String)]
    let compressed: Bool
    
    enum CodingKeys: CodingKey {
      case key, body, compressed
    }

    init(key: String, schemas: [DecisionSchema], bodyInArray: [(String, String)], compressed: Bool) {
        self.key = key
        self.schemas = schemas
        self.bodyInArray = bodyInArray
        self.body = Dictionary(uniqueKeysWithValues: bodyInArray)
        self.compressed = compressed
    }
    
    func decide(user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        let lookupInput = schemas.map { $0.makeLookupInput(user: user) }.joined()
        
        var decision: String?
        if compressed {
            let input = lookupInput
            let rows = bodyInArray.map { $0.0 }
            let mappedToRange = bst(input: input, rows: rows, start: 0, end: bodyInArray.count - 1)
            decision = body[String(mappedToRange)]
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
        
}

public class OptimizelyDecisionTables: Encodable {
    static var modeGenerateDecisionTable = false
    static var schemasForGenerateDecisionTable = [DecisionSchema]()
    static var inputForGenerateDecisionTable = ""
    static var insufficientDecisionInput = false
    public static var modeUseDecisionTable = false

    let tables: [String: FlagDecisionTable]
    let audiences: [Audience]
    
    init(tables: [String: FlagDecisionTable] = [:], audiences: [Audience] = []) {
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
    
    // JSON
    
    var tablesArray: [FlagDecisionTable] {
        return Array(tables.values)
    }

    enum CodingKeys: String, CodingKey {
        case tablesArray = "decisions"
        case audiences
    }
    
    // this explicit encode method is required to support computed props (tablesArray) for coding
    public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
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
        table.schemas.forEach { schema in
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
