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

class FlagDecisionTable {
    let key: String
    let schemas: [DecisionSchema]
    let body: [String: String]
    let bodyInArray: [(String, String)]
    
    init(key: String, schemas: [DecisionSchema], bodyInArray: [(String, String)]) {
        self.key = key
        self.schemas = schemas
        self.bodyInArray = bodyInArray
        self.body = Dictionary(uniqueKeysWithValues: bodyInArray)
    }
    
    func decide(user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        let lookupInput = schemas.map { $0.makeLookupInput(user: user) }.joined()
        let decision = body[lookupInput]
        
        return OptimizelyDecision(variationKey: decision,
                                  enabled: true,
                                  variables: OptimizelyJSON.createEmpty(),
                                  ruleKey: lookupInput,   // pass it up for print
                                  flagKey: key,
                                  userContext: user,
                                  reasons: [])
    }
        
    func mergeDecisionRows(_ row1: (String, String)?, _ row2: (String, String)?) -> (String, String)? {
        return nil
    }

}

public class OptimizelyDecisionTables {
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
