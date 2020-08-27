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
        var decisionFromFeatureTest = false

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
            decisionFromFeatureTest = true
            
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
                                  variationKey: decisionFromFeatureTest ? decision?.variation?.key : nil,
                                  ruleKey: nil,
                                  key: feature.key,
                                  user: user,
                                  reasons: decisionReasons.getReasonsToReport(options: allOptions))
    }
    
}
    
// MARK: - decideAll
        
extension OptimizelyClient {

    public func decideAll(keys: [String]?,
                          user: OptimizelyUserContext? = nil,
                          options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        
        guard let userContext = user ?? userContext else {
            logger.e(OptimizelyError.userNotSet)
            return [:]
        }
        guard let config = self.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        let allOptions = getAllOptions(with: options)

        let keys = keys ?? {
            if allOptions.contains(.forExperiment) {
                return config.allExperiments.map{ $0.key }
            } else {
                return config.getFeatureFlags().map{ $0.key }
            }
        }()
        
        guard let firstKey = keys.first else { return [:] }
        
        var isFeatureKey = config.getFeatureFlag(key: firstKey) != nil
        var isExperimentKey = config.getExperiment(key: firstKey) != nil
        if allOptions.contains(.forExperiment) {
            isFeatureKey = false
            isExperimentKey = true
        }
        
        if isExperimentKey && !isFeatureKey {
            return decideAll(config: config, experimentKeys: keys, user: userContext, options: allOptions)
        } else {
            return decideAll(config: config, featureKeys: keys, user: userContext, options: allOptions)
        }
    }
    
    func decideAll(config: ProjectConfig,
                   featureKeys: [String],
                   user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]) -> [String: OptimizelyDecision] {
        var decisions = [String: OptimizelyDecision]()
        
        for key in featureKeys {
            let decision = decide(config: config, featureKey: key, user: user, options: options)
            if !options.contains(.enabledOnly) || (decision.enabled != nil && decision.enabled!) {
                decisions[key] = decision
            }
        }
                
        return decisions
    }

    func decideAll(config: ProjectConfig,experimentKeys: [String],
                   user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]) -> [String: OptimizelyDecision] {
        var decisions = [String: OptimizelyDecision]()
        
        for key in experimentKeys {
            let decision = decide(config: config, experimentKey: key, user: user, options: options)
            decisions[key] = decision
        }
                
        return decisions
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
