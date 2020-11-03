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

/// A decision struct that the SDK makes for a flag key and a user context.
public struct OptimizelyDecision {
    
    /// The variation key of the decision. This value will be nil when decision making fails.
    public let variationKey: String?
    
    /// The boolean value indicating if the flag is enabled or not.
    public let enabled: Bool
    
    /// The collection of variables assocaited with the decision.
    public let variables: OptimizelyJSON
    
    /// The rule key of the decision.
    public let ruleKey: String?

    /// The flag key for which the decision has been made for.
    public let flagKey: String
    
    /// The user context for which the decision has been made for.
    public let userContext: OptimizelyUserContext
    
    /// An array of error/info/debug messages describing why the decision has been made.
    public let reasons: [String]
}

extension OptimizelyDecision {
    static func errorDecision(key: String, user: OptimizelyUserContext, error: OptimizelyError) -> OptimizelyDecision {
        return OptimizelyDecision(variationKey: nil,
                                  enabled: false,
                                  variables: OptimizelyJSON.createEmpty(),
                                  ruleKey: nil,
                                  flagKey: key,
                                  userContext: user,
                                  reasons: [error.reason])
    }
    
    var hasFailed: Bool {
        return variationKey == nil
    }
}

extension OptimizelyDecision: Equatable {
    public static func == (lhs: OptimizelyDecision, rhs: OptimizelyDecision) -> Bool {
        return lhs.variationKey == rhs.variationKey &&
            lhs.enabled == rhs.enabled &&
            lhs.variables == rhs.variables &&
            lhs.ruleKey == rhs.ruleKey &&
            lhs.flagKey == rhs.flagKey &&
            lhs.userContext == rhs.userContext &&
            lhs.reasons == rhs.reasons
    }
}
