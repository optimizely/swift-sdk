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
    ///   - user: A user context.
    public func setUserContext(_ user: OptimizelyUserContext) {        
        userContext = user
    }
    
    /// Set the default decide-options which are commonly applied to all following decide API calls.
    ///
    /// These options will be overridden when each decide-API call provides own options.
    ///
    /// - Parameter options: An array of default decision options.
    public func setDefaultDecideOptions(_ options: [OptimizelyDecideOption]) {
        defaultDecideOptions = options
    }
    
    /// Returns a decision result for a given flag key and a user context, which contains all data required to deliver the flag or experiment.
    ///
    /// If the SDK finds an error (__sdkNotReady__, __userNotSet__, etc), it’ll return a decision with `nil` for `enabled` and `variationKey`. The decision will include an error message in `reasons` (regardless of the __includeReasons__ option).
    ///
    /// - Parameters:
    ///   - key: A flag key for which a decision will be made.
    ///   - user: A user context. This is optional when a user context has been set before.
    ///   - options: An array of options for decision-making.
    /// - Returns: A decision result.
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
        var sentEvent = false
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
        
        let reasonsToReport = decisionReasons.getReasonsToReport(options: allOptions)
        
        if let experimentDecision = decision?.experiment, let variationDecision = decision?.variation {
            if !allOptions.contains(.disableDecisionEvent) {
                sendImpressionEvent(experiment: experimentDecision,
                                    variation: variationDecision,
                                    userId: userId,
                                    attributes: attributes)
                sentEvent = true
            }
        }
        
        sendDecisionNotification(decisionType: .flag,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: decision?.experiment,
                                 variation: decision?.variation,
                                 feature: feature,
                                 featureEnabled: enabled,
                                 variableValues: variableMap,
                                 reasons: reasonsToReport,
                                 sentEvent: sentEvent)
        
        return OptimizelyDecision(enabled: enabled,
                                  variables: optimizelyJSON,
                                  variationKey: decision?.variation?.key,
                                  ruleKey: nil,
                                  flagKey: feature.key,
                                  user: user,
                                  reasons: reasonsToReport)
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
        return defaultDecideOptions + (options ?? [])
    }
    
}
