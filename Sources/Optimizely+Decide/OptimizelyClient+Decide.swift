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
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
              
        var user = user
        
        if user.userId == nil {
            let uuidKey = "optimizely-uuid"
            var uuid = UserDefaults.standard.string(forKey: uuidKey)
            if uuid == nil {
                uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: uuidKey)
            }
            user.userId = uuid
        }
        
        guard let userId = user.userId else {
            throw OptimizelyError.generic    // TODO: refine error type
        }
        
        // userProfileUpdates
        
        if let decisionService = self.decisionService as? DefaultDecisionService {
            let requests = user.userProfileUpdates

            requests.forEach { (key, value) in
                if let key = key, let value = value {
                    decisionService.saveProfile(config: config,
                                                userId: userId,
                                                experimentKey: key,
                                                variationKey: value)
                } else {
                    // clear one or all UPS for the user
                    decisionService.removeProfile(config: config,
                                                  userId: userId,
                                                  experimentKey: key)
                }
            }
            
            user.userProfileUpdates = []
        }
        
        userContext = user
    }
}
    
// MARK: - decide
    
extension OptimizelyClient {
    
    public func decide(key: String,
                       user: OptimizelyUserContext? = nil,
                       options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        
        guard let userContext = user ?? userContext else {
            return OptimizelyDecision.errorDecision(key: key, user: nil, error: .userNotSet)
        }
        guard let config = self.config else {
            return OptimizelyDecision.errorDecision(key: key, user: userContext, error: .sdkNotReady)
        }

        var isFeatureKey = config.getFeatureFlag(key: key) != nil
        var isExperimentKey = config.getExperiment(key: key) != nil
        if let options = options, options.contains(.forExperiment) {
            isFeatureKey = false
            isExperimentKey = true
        }
        
        if isExperimentKey && !isFeatureKey {
            return decide(config: config, experimentKey: key, user: userContext, options: options)
        } else {
            return decide(config: config, featureKey: key, user: userContext, options: options)
        }
    }
    
    func decide(config: ProjectConfig,
                featureKey: String,
                user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]?) -> OptimizelyDecision {
        
        guard let userId = user.userId else {
            return OptimizelyDecision.errorDecision(key: featureKey, user: user, error: .userIdInvalid)
        }
        guard let feature = config.getFeatureFlag(key: featureKey) else {
            return OptimizelyDecision.errorDecision(key: featureKey, user: user, error: .featureKeyInvalid(featureKey))
        }
        
        var reasonsRequired = [OptimizelyError]()
        var reasonsOptional = [OptimizelyError]()   // TODO
        
        let attributes = user.attributes
        
        let decision = self.decisionService.getVariationForFeature(config: config,
                                                                   featureFlag: feature,
                                                                   userId: userId,
                                                                   attributes: attributes)
        var enabled = false
        if let featureEnabled = decision?.variation?.featureEnabled {
            enabled = featureEnabled
        }
        
        var variableMap = [String: Any]()
        for (_, v) in feature.variablesMap {
            var featureValue = v.value
            if enabled, let variable = decision?.variation?.getVariable(id: v.id) {
                featureValue = variable.value
            }
            
            var valueParsed: Any? = featureValue
            
            if let valueType = Constants.VariableValueType(rawValue: v.type) {
                switch valueType {
                case .string:
                    break
                case .integer:
                    valueParsed = Int(featureValue)
                    break
                case .double:
                    valueParsed = Double(featureValue)
                    break
                case .boolean:
                    valueParsed = Bool(featureValue)
                    break
                case .json:
                    valueParsed = OptimizelyJSON(payload: featureValue)?.toMap()
                    break
                }
            }

            if let value = valueParsed {
                variableMap[v.key] = value
            } else {
                logger.e(OptimizelyError.variableValueInvalid(v.key))
            }
        }
        
        sendDecisionNotification(decisionType: .featureDecide,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: decision?.experiment,
                                 variation: decision?.variation,
                                 feature: feature,
                                 featureEnabled: enabled,
                                 variableValues: variableMap)
        
        let optimizelyJSON = OptimizelyJSON(map: variableMap)
        if optimizelyJSON == nil {
            reasonsRequired.append(.invalidDictionary)
        }

        var reasons = reasonsRequired
        if let options = options, options.contains(.includeReasons) {
            reasons.append(contentsOf: reasonsOptional)
        }
                
        return OptimizelyDecision(variationKey: nil,
                                  enabled: enabled,
                                  variables: optimizelyJSON,
                                  key: feature.key,
                                  user: user,
                                  reasons: reasons.map{ $0.reason })
    }
    
    func decide(config: ProjectConfig,
                experimentKey: String,
                user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]?) -> OptimizelyDecision {
        
        guard let userId = user.userId else {
            return OptimizelyDecision.errorDecision(key: experimentKey, user: user, error: .userIdInvalid)
        }
        guard let experiment = config.getExperiment(key: experimentKey) else {
            return OptimizelyDecision.errorDecision(key: experimentKey, user: user, error: .experimentKeyInvalid(experimentKey))
        }
        
        var reasonsRequired = [OptimizelyError]()   // TODO
        var reasonsOptional = [OptimizelyError]()   // TODO

        let attributes = user.attributes
        
        let variation = decisionService.getVariation(config: config,
                                                     userId: userId,
                                                     experiment: experiment,
                                                     attributes: attributes)
        
        if let variationDecision = variation {
            sendDecisionNotification(decisionType: .experimentDecide,
                                     userId: userId,
                                     attributes: attributes,
                                     experiment: experiment,
                                     variation: variationDecision)
        }

        var reasons = reasonsRequired
        if let options = options, options.contains(.includeReasons) {
            reasons.append(contentsOf: reasonsOptional)
        }

        return OptimizelyDecision(variationKey: variation?.key,
                                  enabled: nil,
                                  variables: nil,
                                  key: experiment.key,
                                  user: user,
                                  reasons: reasons.map{ $0.reason })
    }
}
    
// MARK: - decideAll
        
extension OptimizelyClient {

    public func decideAll(keys: [String]?,
                          user: OptimizelyUserContext?,
                          options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        
        guard let userContext = user ?? userContext else {
            logger.e(OptimizelyError.userNotSet)
            return [:]
        }
        guard let config = self.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }

        let keys = keys ?? {
            if let options = options, options.contains(.forExperiment) {
                return config.allExperiments.map{ $0.key }
            } else {
                return config.getFeatureFlags().map{ $0.key }
            }
        }()
        
        guard let firstKey = keys.first else { return [:] }
        
        var isFeatureKey = config.getFeatureFlag(key: firstKey) != nil
        var isExperimentKey = config.getExperiment(key: firstKey) != nil
        if let options = options, options.contains(.forExperiment) {
            isFeatureKey = false
            isExperimentKey = true
        }
        
        if isExperimentKey && !isFeatureKey {
            return decideAll(config: config, experimentKeys: keys, user: userContext, options: options)
        } else {
            return decideAll(config: config, featureKeys: keys, user: userContext, options: options)
        }
    }
    
    func decideAll(config: ProjectConfig,
                   featureKeys: [String],
                   user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]?) -> [String: OptimizelyDecision] {
        var decisions = [String: OptimizelyDecision]()
        
        for key in featureKeys {
            let decision = decide(config: config, featureKey: key, user: user, options: options)
            decisions[key] = decision
        }
                
        return decisions
    }

    func decideAll(config: ProjectConfig,experimentKeys: [String],
                   user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]?) -> [String: OptimizelyDecision] {
        var decisions = [String: OptimizelyDecision]()
        
        for key in experimentKeys {
            let decision = decide(config: config, experimentKey: key, user: user, options: options)
            decisions[key] = decision
        }
                
        return decisions
    }

}
