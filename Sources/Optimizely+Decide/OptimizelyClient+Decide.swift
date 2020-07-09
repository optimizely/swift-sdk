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
        
        // bucketingId
        
        if let bucketingId = user.bucketingId {
            user.attributes[Constants.Attributes.OptimizelyBucketIdAttribute] = bucketingId
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
                       user: OptimizelyUserContext?,
                       options: [OptimizelyDecideOption]? = nil) throws -> OptimizelyDecision {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        guard let user = user ?? userContext else { throw OptimizelyError.userIdInvalid }

        var isFeatureKey = config.getFeatureFlag(key: key) != nil
        if let options = options, options.contains(.forExperiment) {
            isFeatureKey = false
        }
        
        if isFeatureKey {
            return try decide(featureKey: key, user: user, options: options)
        } else {
            return try decide(experimentKey: key, user: user, options: options)
        }
    }
    
    func decide(featureKey: String,
                user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]?) throws -> OptimizelyDecision {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        guard let userId = user.userId else { throw OptimizelyError.userIdInvalid }
        guard let feature = config.getFeatureFlag(key: featureKey) else {
            throw OptimizelyError.featureKeyInvalid(featureKey)
        }
        
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
        
        guard let optimizelyJSON = OptimizelyJSON(map: variableMap) else {
            throw OptimizelyError.invalidDictionary
        }
        
        sendDecisionNotification(decisionType: .featureDecide,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: decision?.experiment,
                                 variation: decision?.variation,
                                 feature: feature,
                                 featureEnabled: enabled,
                                 variableValues: variableMap)
        
        // TODO: fix reasons
        let reasonsForDecision = [String]()
        
        var reasons: [String]? = nil
        if let options = options, options.contains(.includeReasons) {
            reasons = reasonsForDecision
        }
        
        return OptimizelyDecision(variationKey: nil,
                                  enabled: enabled,
                                  variables: optimizelyJSON,
                                  key: feature.key,
                                  user: user,
                                  reasons: reasons)
    }
    
    func decide(experimentKey: String,
                user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]?) throws -> OptimizelyDecision {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        guard let userId = user.userId else { throw OptimizelyError.userIdInvalid }
        guard let experiment = config.getExperiment(key: experimentKey) else {
            throw OptimizelyError.experimentKeyInvalid(experimentKey)
        }
        
        let attributes = user.attributes
        
        let variationDecision = decisionService.getVariation(config: config,
                                                             userId: userId,
                                                             experiment: experiment,
                                                             attributes: attributes)
        
        guard let variation = variationDecision else {
            throw OptimizelyError.variationUnknown(userId, experiment.key)
        }
        
        sendDecisionNotification(decisionType: .experimentDecide,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: experiment,
                                 variation: variation)

        // TODO: fix reasons
        let reasonsForDecision = [String]()
        
        var reasons: [String]? = nil
        if let options = options, options.contains(.includeReasons) {
            reasons = reasonsForDecision
        }
        
        return OptimizelyDecision(variationKey: variation.key,
                                  enabled: nil,
                                  variables: nil,
                                  key: experiment.key,
                                  user: user,
                                  reasons: reasons)
    }
}
    
// MARK: - decideAll
        
extension OptimizelyClient {

    public func decideAll(keys: [String]?,
                          user: OptimizelyUserContext?,
                          options: [OptimizelyDecideOption]? = nil) throws -> [String: OptimizelyDecision] {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        guard let user = user ?? userContext else { throw OptimizelyError.userIdInvalid }

        let keys = keys ?? {
            if let options = options, options.contains(.forExperiment) {
                return config.allExperiments.map{ $0.key }
            } else {
                return config.getFeatureFlags().map{ $0.key }
            }
        }()
        
        guard let firstKey = keys.first else { return [:] }
        
        var isFeatureKey = config.getFeatureFlag(key: firstKey) != nil
        if let options = options, options.contains(.forExperiment) {
            isFeatureKey = false
        }
        
        if isFeatureKey {
            return try decideAll(featureKeys: keys, user: user, options: options)
        } else {
            return try decideAll(experimentKeys: keys, user: user, options: options)
        }
    }
    
    func decideAll(featureKeys: [String],
                user: OptimizelyUserContext,
                options: [OptimizelyDecideOption]?) throws -> [String: OptimizelyDecision] {
        var decisions = [String: OptimizelyDecision]()
        
        for key in featureKeys {
            do {
                let decision = try decide(featureKey: key, user: user, options: options)
                decisions[key] = decision
            } catch {
                let reasons = [error.localizedDescription]
                decisions[key] = OptimizelyDecision(variationKey: nil,
                                                    enabled: nil,
                                                    variables: nil,
                                                    key: key,
                                                    user: user,
                                                    reasons: reasons)
            }
        }
                
        return decisions
    }

    func decideAll(experimentKeys: [String],
                   user: OptimizelyUserContext,
                   options: [OptimizelyDecideOption]?) throws -> [String: OptimizelyDecision] {
        var decisions = [String: OptimizelyDecision]()
        
        for key in experimentKeys {
            do {
                let decision = try decide(experimentKey: key, user: user, options: options)
                decisions[key] = decision
            } catch {
                let reasons = [error.localizedDescription]
                decisions[key] = OptimizelyDecision(variationKey: nil,
                                                    enabled: nil,
                                                    variables: nil,
                                                    key: key,
                                                    user: user,
                                                    reasons: reasons)
            }
        }
                
        return decisions
    }

}
