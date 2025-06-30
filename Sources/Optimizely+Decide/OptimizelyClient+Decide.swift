//
// Copyright 2021-2022, Optimizely, Inc. and contributors
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
    public func createUserContext(attributes: [String: Any]? = nil) -> OptimizelyUserContext? {
        guard let vuid = self.vuid else {
            logger.e("Vuid is not enabled or invalid VUID. User context not created.")
            return nil
        }
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
        
        guard let _ = config.getFeatureFlag(key: key) else {
            return OptimizelyDecision.errorDecision(key: key, user: user, error: .featureKeyInvalid(key))
        }

        var allOptions = defaultDecideOptions + (options ?? [])
        allOptions.removeAll(where: { $0 == .enabledFlagsOnly })
        
        let decisionMap = decide(user: user, keys: [key], options: allOptions, opType: .sync, ignoreDefaultOptions: true)
        return decisionMap[key] ?? OptimizelyDecision.errorDecision(key: key, user: user, error: .generic)
    }
    
    func decideAsync(user: OptimizelyUserContext,
                     key: String,
                     options: [OptimizelyDecideOption]? = nil,
                     completion: @escaping DecideCompletion) {
        decisionQueue.async {
            guard let config = self.config else {
                let decision = OptimizelyDecision.errorDecision(key: key, user: user, error: .sdkNotReady)
                completion(decision)
                return
            }
            
            guard let _ = config.getFeatureFlag(key: key) else {
                let decision = OptimizelyDecision.errorDecision(key: key, user: user, error: .featureKeyInvalid(key))
                completion(decision)
                return
            }
            
            var allOptions = self.defaultDecideOptions + (options ?? [])
            allOptions.removeAll(where: { $0 == .enabledFlagsOnly })
            
            let decisionMap = self.decide(user: user, keys: [key], options: allOptions, opType: .async, ignoreDefaultOptions: true)
            let decision = decisionMap[key] ?? OptimizelyDecision.errorDecision(key: key, user: user, error: .generic)
            completion(decision)
        }
    }
    
    func decide(user: OptimizelyUserContext,
                keys: [String],
                options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        return decide(user: user, keys: keys, options: options, opType: .sync, ignoreDefaultOptions: false)
    }
    
    func decideAsync(user: OptimizelyUserContext,
                     keys: [String],
                     options: [OptimizelyDecideOption]? = nil,
                     completion: @escaping DecideForKeysCompletion) {
        decisionQueue.async {
            let decisions = self.decide(user: user, keys: keys, options: options, opType: .async, ignoreDefaultOptions: false)
            completion(decisions)
        }
    }
    
    func decide(user: OptimizelyUserContext,
                keys: [String],
                options: [OptimizelyDecideOption]? = nil,
                ignoreDefaultOptions: Bool) -> [String: OptimizelyDecision] {
        return self.decide(user: user, keys: keys, options: options, opType: .sync, ignoreDefaultOptions: ignoreDefaultOptions)
    }
    
    func decideAsync(user: OptimizelyUserContext,
                     keys: [String],
                     options: [OptimizelyDecideOption]? = nil,
                     ignoreDefaultOptions: Bool,
                     completion: @escaping DecideForKeysCompletion) {
        decisionQueue.async {
            let decisions = self.decide(user: user, keys: keys, options: options, opType: .async, ignoreDefaultOptions: ignoreDefaultOptions)
            completion(decisions)
        }
    }
    
    private func decide(user: OptimizelyUserContext,
                        keys: [String],
                        options: [OptimizelyDecideOption]? = nil,
                        opType: OPType,
                        ignoreDefaultOptions: Bool) -> [String: OptimizelyDecision] {
        guard let config = self.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        var decisionMap = [String : OptimizelyDecision]()
        
        guard keys.count > 0 else { return decisionMap }
        
        var validKeys = [String]()
        var flagsWithoutForceDecision = [FeatureFlag]()
        var flagDecisions = [String : FeatureDecision]()
        var decisionReasonMap = [String : DecisionReasons]()
        
        let allOptions = ignoreDefaultOptions ? (options ?? []) : defaultDecideOptions + (options ?? [])
        
        for key in keys {
            guard let flags = config.getFeatureFlag(key: key) else {
                decisionMap[key] = OptimizelyDecision.errorDecision(key: key, user: user, error: .featureKeyInvalid(key))
                continue
            }
            
            validKeys.append(key)
            
            // check forced-decisions first
            let forcedDecisionResponse = decisionService.findValidatedForcedDecision(config: config,
                                                                                     user: user,
                                                                                     context: OptimizelyDecisionContext(flagKey: key))
            
            let decisionReasons = DecisionReasons(options: allOptions)
            decisionReasons.merge(forcedDecisionResponse.reasons)
            decisionReasonMap[key] = decisionReasons
            
            if let variation = forcedDecisionResponse.result {
                let featureDecision = FeatureDecision(experiment: nil, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
                flagDecisions[key] = featureDecision
            } else {
                flagsWithoutForceDecision.append(flags)
            }
        }
        
        let decisionList = (decisionService as? DefaultDecisionService)?.getVariationForFeatureList(config: config, featureFlags: flagsWithoutForceDecision, user: user, opType: opType, options: allOptions)
        
        for index in 0..<flagsWithoutForceDecision.count {
            if decisionList?.indices.contains(index) ?? false {
                let decision = decisionList?[index]
                let result = decision?.result
                let flagKey = flagsWithoutForceDecision[index].key
                flagDecisions[flagKey] = result
                let _reasons = decisionReasonMap[flagKey]
                if decision?.reasons != nil {
                    _reasons?.merge(decision!.reasons)
                    decisionReasonMap[flagKey] = _reasons
                }
            }
        }
        
        for index in 0..<validKeys.count {
            let key = validKeys[index]
            let flagDecision = flagDecisions[key]
            let decisionReasons = decisionReasonMap[key] ?? DecisionReasons(options: allOptions)
            let optimizelyDecision = createOptimizelyDecision(flagKey: key,
                                                              user: user,
                                                              flagDecision: flagDecision,
                                                              decisionReasons: decisionReasons,
                                                              allOptions: allOptions,
                                                              config: config)
            if (!allOptions.contains(.enabledFlagsOnly) || optimizelyDecision.enabled) {
                decisionMap[key] = optimizelyDecision
            }
        }
        
        return decisionMap
    }
    
    func decideAll(user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        guard let config = self.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        return decide(user: user, keys: config.featureFlagKeys, options: options)
    }
    
    func decideAllAsync(user: OptimizelyUserContext,
                        options: [OptimizelyDecideOption]? = nil,
                        completion: @escaping DecideForKeysCompletion)  {
        
        decisionQueue.async {
            guard let config = self.config else {
                self.logger.e(OptimizelyError.sdkNotReady)
                completion([:])
                return
            }
            
            let decision = self.decide(user: user, keys: config.featureFlagKeys, options: options,  opType: .async, ignoreDefaultOptions: false)
            completion(decision)
        }
    }

    private func createOptimizelyDecision(flagKey: String,
                                          user: OptimizelyUserContext,
                                          flagDecision: FeatureDecision?,
                                          decisionReasons: DecisionReasons,
                                          allOptions: [OptimizelyDecideOption],
                                          config: ProjectConfig) -> OptimizelyDecision {
        
        guard let feature = config.getFeatureFlag(key: flagKey) else {
            return OptimizelyDecision.errorDecision(key: flagKey, user: user, error: .featureKeyInvalid(flagKey))
        }
        
        let userId = user.userId
        let attributes = user.attributes
        let flagEnabled = flagDecision?.variation.featureEnabled ?? false
        
        logger.i("Feature \(flagKey) is enabled for user \(userId) \(flagEnabled)")
        
        var decisionEventDispatched = false
        
        if !allOptions.contains(.disableDecisionEvent) {
            let ruleType = flagDecision?.source ?? Constants.DecisionSource.rollout.rawValue
            if shouldSendDecisionEvent(source: ruleType, decision: flagDecision) {
                sendImpressionEvent(experiment: flagDecision?.experiment,
                                    variation: flagDecision?.variation,
                                    userId: userId,
                                    attributes: attributes,
                                    flagKey: feature.key,
                                    ruleType: ruleType,
                                    enabled: flagEnabled)
                decisionEventDispatched = true
            }
        }
        
        var variableMap = [String: Any]()
        if !allOptions.contains(.excludeVariables) {
            let decisionResponse = getDecisionVariableMap(feature: feature,
                                                          variation: flagDecision?.variation,
                                                          enabled: flagEnabled)
            decisionReasons.merge(decisionResponse.reasons)
            variableMap = decisionResponse.result ?? [:]
        }
        
        var optimizelyJSON: OptimizelyJSON
        if let opt = OptimizelyJSON(map: variableMap) {
            optimizelyJSON = opt
        } else {
            decisionReasons.addError(OptimizelyError.invalidJSONVariable)
            optimizelyJSON = OptimizelyJSON.createEmpty()
        }
        
        let ruleKey = flagDecision?.experiment?.key
        let reasonsToReport = decisionReasons.toReport()
        
        sendDecisionNotification(userId: userId,
                                 attributes: attributes,
                                 decisionInfo: DecisionInfo(decisionType: .flag,
                                                            experiment: flagDecision?.experiment,
                                                            variation: flagDecision?.variation,
                                                            feature: feature,
                                                            featureEnabled: flagEnabled,
                                                            variableValues: variableMap,
                                                            ruleKey: ruleKey,
                                                            reasons: reasonsToReport,
                                                            decisionEventDispatched: decisionEventDispatched))
        
        return OptimizelyDecision(variationKey: flagDecision?.variation.key,
                                  enabled: flagEnabled,
                                  variables: optimizelyJSON,
                                  ruleKey: ruleKey,
                                  flagKey: feature.key,
                                  userContext: user,
                                  reasons: reasonsToReport)
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
