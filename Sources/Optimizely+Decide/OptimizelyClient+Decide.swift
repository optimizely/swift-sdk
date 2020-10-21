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
    
    /// Create a context of the user for which decision APIs will be called.
    ///
    /// A user context will be created successfully even when the SDK is not fully configured yet.
    ///
    /// - Parameters:
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: An OptimizelyUserContext associated with this OptimizelyClient
    public func createUserContext(userId: String,
                                  attributes: [String: Any]? = nil) -> OptimizelyUserContext {
        return OptimizelyUserContext(optimizely: self, userId: userId, attributes: attributes)
    }
    
    func decide(user: OptimizelyUserContext,
                key: String,
                options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        
        guard let config = self.config else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .sdkNotReady)
        }
        
        guard let feature = config.getFeatureFlag(key: key) else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .featureKeyInvalid(key))
        }
        
        let userId = user.userId
        let attributes = user.attributes
        let allOptions = defaultDecideOptions + (options ?? [])
        let decisionReasons = DecisionReasons()
        var sentEvent = false
        var enabled = false
    
        let decision = decisionService.getVariationForFeature(config: config,
                                                              featureFlag: feature,
                                                              userId: userId,
                                                              attributes: attributes,
                                                              options: allOptions)
        
        if let featureEnabled = decision?.variation?.featureEnabled {
            enabled = featureEnabled
        }
        
        var variableMap = [String: Any]()
        if !allOptions.contains(.excludeVariables) {
            variableMap = getDecisionVariableMap(feature: feature,
                                                 variation: decision?.variation,
                                                 enabled: enabled,
                                                 reasons: decisionReasons)
        }
        
        var optimizelyJSON: OptimizelyJSON
        if let opt = OptimizelyJSON(map: variableMap) {
            optimizelyJSON = opt
        } else {
            decisionReasons.addError(OptimizelyError.invalidJSONVariable)
            optimizelyJSON = OptimizelyJSON.createEmpty()
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
        
        // TODO: add ruleKey values when available later. Use a copy of experimentKey for now.
        let ruleKey = decision?.experiment?.key
        
        sendDecisionNotification(userId: userId,
                                 attributes: attributes,
                                 decisionInfo: DecisionInfo(decisionType: .flag,
                                                            experiment: decision?.experiment,
                                                            variation: decision?.variation,
                                                            feature: feature,
                                                            featureEnabled: enabled,
                                                            variableValues: variableMap,
                                                            ruleKey: ruleKey,
                                                            reasons: reasonsToReport,
                                                            sentEvent: sentEvent))
        
        return OptimizelyDecision(variationKey: decision?.variation?.key,
                                  enabled: enabled,
                                  variables: optimizelyJSON,
                                  ruleKey: ruleKey,
                                  flagKey: feature.key,
                                  userContext: user,
                                  reasons: reasonsToReport)
    }
    
    func decide(user: OptimizelyUserContext, keys: [String], options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        guard config != nil else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        guard keys.count > 0 else { return [:] }
        
        let allOptions = defaultDecideOptions + (options ?? [])

        var decisions = [String: OptimizelyDecision]()
        
        keys.forEach { key in
            let decision = decide(user: user, key: key, options: options)
            if !allOptions.contains(.enabledFlagsOnly) || decision.enabled {
                decisions[key] = decision
            }
        }
                
        return decisions
    }

    func decideAll(user: OptimizelyUserContext, options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        guard let config = self.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }

        return decide(user: user, keys: config.featureFlagKeys, options: options)
    }

}

// MARK: - Utils

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
                                    
            if let value = parseFeatureVaraible(value: featureValue, type: v.type) {
                variableMap[v.key] = value
            } else {
                let info = OptimizelyError.variableValueInvalid(v.key)
                logger.e(info)
                reasons.addError(info)
            }
        }
        
        return variableMap
    }
    
    func parseFeatureVaraible(value: String, type: String) -> Any? {
        var valueParsed: Any? = value
        
        if let valueType = Constants.VariableValueType(rawValue: type) {
            switch valueType {
            case .string:
                break
            case .integer:
                valueParsed = Int(value)
            case .double:
                valueParsed = Double(value)
            case .boolean:
                valueParsed = Bool(value)
            case .json:
                valueParsed = OptimizelyJSON(payload: value)?.toMap()
            }
        }
        
        return valueParsed
    }
    
}
