//
// Copyright 2021-2023, Optimizely, Inc. and contributors
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
    
    /// Create a context with the device vuid for which decision APIs will be called.
    ///
    /// - Parameter attributes: A map of attribute names to current user attribute values.
    /// - Returns: An OptimizelyUserContext associated with this OptimizelyClient
    public func createUserContext(attributes: [String: Any]? = nil) -> OptimizelyUserContext {
        return OptimizelyUserContext(optimizely: self, userId: vuid, attributes: attributes)
    }
    
    func createUserContext(userId: String,
                           attributes: OptimizelyAttributes? = nil) -> OptimizelyUserContext {
        return createUserContext(userId: userId,
                                 attributes: (attributes ?? [:]) as [String: Any])
    }
        
    /// Create a user context to be used internally without sending an ODP identify event.
    ///
    /// - Parameters:
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: An OptimizelyUserContext associated with this OptimizelyClient
    func makeInternalUserContext(userId: String,
                                 attributes: OptimizelyAttributes? = nil) -> OptimizelyUserContext {
        return OptimizelyUserContext(optimizely: self, userId: userId,
                                     attributes: (attributes ?? [:]) as [String: Any],
                                     identify: false)
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
        let reasons = DecisionReasons(options: allOptions)
        var decisionEventDispatched = false
        var enabled = false
        
        var decision: FeatureDecision?
        
        // check forced-decisions first
        
        let forcedDecisionResponse = decisionService.findValidatedForcedDecision(config: config,
                                                                                 user: user,
                                                                                 context: OptimizelyDecisionContext(flagKey: key))
        reasons.merge(forcedDecisionResponse.reasons)
        
        if let variation = forcedDecisionResponse.result {
            decision = FeatureDecision(experiment: nil, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
        } else {
            // regular decision

            let decisionResponse = decisionService.getVariationForFeature(config: config,
                                                                          featureFlag: feature,
                                                                          user: user,
                                                                          options: allOptions)
            reasons.merge(decisionResponse.reasons)
            decision = decisionResponse.result
       }
        
        if let featureEnabled = decision?.variation.featureEnabled {
            enabled = featureEnabled
        }
        
        if !allOptions.contains(.disableDecisionEvent) {
            let ruleType = decision?.source ?? Constants.DecisionSource.rollout.rawValue
            if shouldSendDecisionEvent(source: ruleType, decision: decision) {
                sendImpressionEvent(experiment: decision?.experiment,
                                    variation: decision?.variation,
                                    userId: userId,
                                    attributes: attributes,
                                    flagKey: feature.key,
                                    ruleType: ruleType,
                                    enabled: enabled,
                                    clientName: clientName)
                decisionEventDispatched = true
            }
        }
        
        var variableMap = [String: Any]()
        if !allOptions.contains(.excludeVariables) {
            let decisionResponse = getDecisionVariableMap(feature: feature,
                                                          variation: decision?.variation,
                                                          enabled: enabled)
            reasons.merge(decisionResponse.reasons)
            variableMap = decisionResponse.result ?? [:]
        }
        
        var optimizelyJSON: OptimizelyJSON
        if let opt = OptimizelyJSON(map: variableMap) {
            optimizelyJSON = opt
        } else {
            reasons.addError(OptimizelyError.invalidJSONVariable)
            optimizelyJSON = OptimizelyJSON.createEmpty()
        }
        
        let ruleKey = decision?.experiment?.key
        let reasonsToReport = reasons.toReport()
        
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
                                                            decisionEventDispatched: decisionEventDispatched))
        
        return OptimizelyDecision(variationKey: decision?.variation.key,
                                  enabled: enabled,
                                  variables: optimizelyJSON,
                                  ruleKey: ruleKey,
                                  flagKey: feature.key,
                                  userContext: user,
                                  reasons: reasonsToReport)
    }
    
    func decide(user: OptimizelyUserContext,
                keys: [String],
                options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        guard config != nil else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        guard keys.count > 0 else { return [:] }
        
        let allOptions = defaultDecideOptions + (options ?? [])
        
        var decisions = [String: OptimizelyDecision]()
        
        let enabledFlagsOnly = allOptions.contains(.enabledFlagsOnly)
        keys.forEach { key in
            let decision = decide(user: user, key: key, options: options)
            if !enabledFlagsOnly || decision.enabled {
                decisions[key] = decision
            }
        }
        
        return decisions
    }
    
    func decideAll(user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
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
                                enabled: Bool) -> DecisionResponse<[String: Any]> {
        let reasons = DecisionReasons()
        
        var variableMap = [String: Any]()
        
        for v in feature.variables {
            var featureValue = v.defaultValue ?? ""
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
        
        return DecisionResponse(result: variableMap, reasons: reasons)
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
