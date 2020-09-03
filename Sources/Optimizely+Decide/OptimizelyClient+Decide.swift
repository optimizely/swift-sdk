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

extension OptimizelyClient {
    
    /// Set a context of the user for which decision APIs will be called.
    ///
    /// The SDK will keep this context until it is called again with a different context data.
    ///
    /// - This API can be called after SDK initialization is completed (otherwise the __sdkNotReady__ error will be returned).
    /// - Only one user outstanding. The user-context can be changed any time by calling the same method with a different user-context value.
    /// - The SDK will copy the parameter value to create an internal user-context data atomically, so any further change in its caller copy after the API call is not reflected into the SDK state.
    /// - Once this API is called, the following other API calls can be called without a user-context parameter to use the same user-context.
    /// - Each Decide API call can contain an optional user-context parameter when the call targets a different user-context. This optional user-context parameter value will be used once only, instead of replacing the saved user-context. This call-based context control can be used to support multiple users at the same time.
    /// - If a user-context has not been set yet and decide APIs are called without a user-context parameter, SDK will return an error decision (__userNotSet__).
    ///
    /// - Parameters:
    ///   - user: a user-context
    /// - Throws: `OptimizelyError` if SDK fails to set the user context
    public func setUserContext(_ user: OptimizelyUserContext) throws {
        guard self.config != nil else { throw OptimizelyError.sdkNotReady }
                              
        userContext = user
    }
}
    
// MARK: - decide
    
extension OptimizelyClient {
    
    public func decide(key: String,
                       user: OptimizelyUserContext? = nil,
                       options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        
        guard let user = user ?? userContext else {
            return OptimizelyDecision.errorDecision(key: key, user: nil, error: .userNotSet)
        }
        
        guard let config = self.config else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .sdkNotReady)
        }
        
        guard let feature = config.getFeatureFlag(key: key) else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .featureKeyInvalid(key))
        }

        let userId = user.userId
        let attributes = user.attributes
        let allOptions = getAllOptions(with: options)
        let decisionReasons = DecisionReasons()
        var tracked = false
        var enabled = false

        let decision = self.decisionService.getVariationForFeature(config: config,
                                                                   featureFlag: feature,
                                                                   userId: userId,
                                                                   attributes: attributes,
                                                                   options: allOptions)
        
        if let featureEnabled = decision?.variation?.featureEnabled {
            enabled = featureEnabled
        }
        
        let variableMap = getDecisionVariableMap(feature: feature,
                                                 variation: decision?.variation,
                                                 enabled: enabled,
                                                 reasons: decisionReasons)
        
        let optimizelyJSON = OptimizelyJSON(map: variableMap)
        if optimizelyJSON == nil {
            decisionReasons.addError(OptimizelyError.invalidDictionary)
        }

        if let experimentDecision = decision?.experiment, let variationDecision = decision?.variation {
            if !allOptions.contains(.disableTracking) {
                sendImpressionEvent(experiment: experimentDecision,
                                    variation: variationDecision,
                                    userId: userId,
                                    attributes: attributes)
                tracked = true
            }
        }
        
        sendDecisionNotification(decisionType: .featureDecide,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: decision?.experiment,
                                 variation: decision?.variation,
                                 feature: feature,
                                 featureEnabled: enabled,
                                 variableValues: variableMap,
                                 tracked: tracked)
        
        return OptimizelyDecision(enabled: enabled,
                                  variables: optimizelyJSON,
                                  variationKey: decision?.variation?.key,
                                  ruleKey: nil,
                                  key: feature.key,
                                  user: user,
                                  reasons: decisionReasons.getReasonsToReport(options: allOptions))
    }
    
}

// MARK: - utils

extension OptimizelyClient {
    
    func getDecisionVariableMap(feature: FeatureFlag,
                                variation: Variation?,
                                enabled: Bool,
                                reasons: DecisionReasons) -> [String: Any] {
        var variableMap = [String: Any]()
        
        for (_, v) in feature.variablesMap {
            var featureValue = v.value
            if enabled, let variable = variation?.getVariable(id: v.id) {
                featureValue = variable.value
            }
            
            var valueParsed: Any? = featureValue
            
            if let valueType = Constants.VariableValueType(rawValue: v.type) {
                switch valueType {
                case .string:
                    break
                case .integer:
                    valueParsed = Int(featureValue)
                case .double:
                    valueParsed = Double(featureValue)
                case .boolean:
                    valueParsed = Bool(featureValue)
                case .json:
                    valueParsed = OptimizelyJSON(payload: featureValue)?.toMap()
                }
            }

            if let value = valueParsed {
                variableMap[v.key] = value
            } else {
                let info = OptimizelyError.variableValueInvalid(v.key)
                logger.e(info)
                reasons.addError(info)
            }
        }

        return variableMap
    }
    
    func getAllOptions(with options: [OptimizelyDecideOption]?) -> [OptimizelyDecideOption] {
        return (userContext?.defaultDecideOptions ?? []) + (options ?? [])
    }
    
}
