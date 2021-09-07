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
    
    init(key: String, schemas: [DecisionSchema], body: [String: String]) {
        self.key = key
        self.schemas = schemas
        self.body = body
    }
    
    func decide(user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        let lookupInput = schemas.map { $0.makeLookupInput(user: user) }.joined()
        print("[LookupInput] \(lookupInput)")
        if let decision = body[lookupInput] {
            return OptimizelyDecision(variationKey: decision,
                                      enabled: true,
                                      variables: OptimizelyJSON.createEmpty(),
                                      ruleKey: nil,
                                      flagKey: key,
                                      userContext: user,
                                      reasons: [])
        } else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .sdkNotReady)
        }
    }
}

public class DecisionTables {
    let tables: [String: FlagDecisionTable]
    
    init(tables: [String: FlagDecisionTable] = [:]) {
        self.tables = tables
    }
        
    public func decide(user: OptimizelyUserContext,
                       key: String,
                       options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        guard let table = tables[key] else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .sdkNotReady)
        }
        
        return table.decide(user: user, options: options)
    }
    
    public func getRandomUserContext(optimizely: OptimizelyClient, flagKey: String) -> OptimizelyUserContext {
        let userId = String(Int.random(in: 10000..<99999))
        
        var attributes = [String: Any]()
        
        return OptimizelyUserContext(optimizely: optimizely, userId: userId, attributes: attributes)
    }
}
