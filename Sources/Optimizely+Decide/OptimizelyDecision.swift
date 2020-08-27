/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/
    
import Foundation

public struct OptimizelyDecision {
    public let enabled: Bool?
    public let variables: OptimizelyJSON?
    public let variationKey: String?
    public let ruleKey: String?

    public let key: String
    public let user: OptimizelyUserContext?
    public let reasons: [String]
}

extension OptimizelyDecision {
    static func errorDecision(key: String, user: OptimizelyUserContext?, error: OptimizelyError) -> OptimizelyDecision {
        return OptimizelyDecision(enabled: nil,
                                  variables: nil,
                                  variationKey: nil,
                                  ruleKey: nil,
                                  key: key,
                                  user: user,
                                  reasons: [error.reason])
    }
}

extension OptimizelyDecision: Equatable {
    public static func ==(lhs: OptimizelyDecision, rhs: OptimizelyDecision) -> Bool {
        if !(lhs.variationKey == rhs.variationKey &&
            lhs.enabled == rhs.enabled &&
            lhs.key == rhs.key &&
            lhs.user == rhs.user &&
            lhs.reasons == rhs.reasons) {
            return false
        }
        
        return (lhs.variables == nil && rhs.variables == nil) ||
            (lhs.variables != nil && rhs.variables != nil && lhs.variables! == rhs.variables!)
    }
}
