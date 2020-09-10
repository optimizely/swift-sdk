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
    
    /// A boolean value indicating the flag is enabled or not.
    public let enabled: Bool?
    
    /// A collection of variables assocaited with the decision.
    public let variables: OptimizelyJSON?
    
    /// A variation key of the decision.
    public let variationKey: String?
    
    /// A rule key of the decision.
    public let ruleKey: String?

    /// A flag key for which the decision has been made for.
    public let flagKey: String
    
    /// A user context for which the decision has been made for.
    public let user: OptimizelyUserContext?
    
    /// An array of error/info/debug messages describing why the decision has been made.
    public let reasons: [String]
}

extension OptimizelyDecision {
    static func errorDecision(key: String, user: OptimizelyUserContext?, error: OptimizelyError) -> OptimizelyDecision {
        return OptimizelyDecision(enabled: nil,
                                  variables: nil,
                                  variationKey: nil,
                                  ruleKey: nil,
                                  flagKey: key,
                                  user: user,
                                  reasons: [error.reason])
    }
    
    var hasFailed: Bool {
        return variationKey == nil && enabled == nil
    }
}

extension OptimizelyDecision: Equatable {
    public static func ==(lhs: OptimizelyDecision, rhs: OptimizelyDecision) -> Bool {
        if !(lhs.enabled == rhs.enabled &&
            lhs.variationKey == rhs.variationKey &&
            lhs.ruleKey == rhs.ruleKey &&
            lhs.flagKey == rhs.flagKey &&
            lhs.user == rhs.user &&
            lhs.reasons == rhs.reasons) {
            return false
        }
        
        return (lhs.variables == nil && rhs.variables == nil) ||
            (lhs.variables != nil && rhs.variables != nil && lhs.variables! == rhs.variables!)
    }
}
