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

/// An object for user contexts that the SDK will use to make decisions for.
public class OptimizelyUserContext {
    weak var optimizely: OptimizelyClient?
    var userId: String
    var attributes: [String: Any]
    
    lazy var logger = OPTLoggerFactory.getLogger()
    
    /// OptimizelyUserContext init
    ///
    /// - Parameters:
    ///   - optimizely: an instance of OptimizelyClient to be used for decisions.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    public init(optimizely: OptimizelyClient,
                userId: String,
                attributes: [String: Any]? = nil) {
        self.optimizely = optimizely
        self.userId = userId
        self.attributes = attributes ?? [:]
    }
    
    /// Set an attribute for a given key.
    /// - Parameters:
    ///   - key: An attribute key
    ///   - value: An attribute value
    public func setAttribute(key: String, value: Any) {
        attributes[key] = value
    }
    
    /// Returns a decision result for a given flag key and a user context, which contains all data required to deliver the flag or experiment.
    ///
    /// If the SDK finds an error (__sdkNotReady__, __userContextInvalid__, etc), it’ll return a decision with `nil` for `enabled` and `variationKey`. The decision will include an error message in `reasons` (regardless of the __includeReasons__ option).
    ///
    /// - Parameters:
    ///   - key: A flag key for which a decision will be made.
    ///   - user: A user context. This is optional when a user context has been set before.
    ///   - options: An array of options for decision-making.
    /// - Returns: A decision result.
    public func decide(key: String,
                       options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        
        guard let optimizely = self.optimizely, let config = optimizely.config else {
            return OptimizelyDecision.errorDecision(key: key, user: self, error: .sdkNotReady)
        }
        
        guard let feature = config.getFeatureFlag(key: key) else {
            return OptimizelyDecision.errorDecision(key: key, user: self, error: .featureKeyInvalid(key))
        }
        
        let allOptions = getAllOptions(with: options)
        let decisionReasons = DecisionReasons()
        var sentEvent = false
        var enabled = false
    
        let decision = optimizely.decisionService.getVariationForFeature(config: config,
                                                                         featureFlag: feature,
                                                                         userId: userId,
                                                                         attributes: attributes,
                                                                         options: allOptions,
                                                                         reasons: decisionReasons)
        
        if let featureEnabled = decision?.variation?.featureEnabled {
            enabled = featureEnabled
        }
        
        var variableMap = [String : Any]()
        if !allOptions.contains(.excludeVariables) {
            variableMap = getDecisionVariableMap(feature: feature,
                                                 variation: decision?.variation,
                                                 enabled: enabled,
                                                 reasons: decisionReasons)
        }
        
        let optimizelyJSON = OptimizelyJSON(map: variableMap)
        if optimizelyJSON == nil {
            decisionReasons.addError(OptimizelyError.invalidJSONVariable)
        }
        
        let reasonsToReport = decisionReasons.getReasonsToReport(options: allOptions)
        
        if let experimentDecision = decision?.experiment, let variationDecision = decision?.variation {
            if !allOptions.contains(.disableDecisionEvent) {
                optimizely.sendImpressionEvent(experiment: experimentDecision,
                                               variation: variationDecision,
                                               userId: userId,
                                               attributes: attributes)
                sentEvent = true
            }
        }
        
        optimizely.sendDecisionNotification(decisionType: .flag,
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
                                  userContext: self,
                                  reasons: reasonsToReport)
    }

    /// Returns a key-map of decision results for multiple flag keys and a user context.
    ///
    /// - If the SDK finds an error (__flagKeyInvalid__, etc) for a key, the response will include a decision for the key showing `reasons` for the error (regardless of __includeReasons__ in options).
    /// - The SDK will always return key-mapped decisions. When it can not process requests (on __sdkNotReady__ or __userContextInvalid__ errors), it’ll return an empty map after logging the errors.
    ///
    /// - Parameters:
    ///   - keys: An array of flag keys for which decisions will be made. When set to `nil`, the SDK will return decisions for all active flag keys.
    ///   - options: An array of options for decision-making.
    /// - Returns: A dictionary of all decision results, mapped by flag keys.
    public func decideAll(keys: [String],
                          options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        
        guard let optimizely = self.optimizely, let _ = optimizely.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        guard keys.count > 0 else { return [:] }
        
        let allOptions = getAllOptions(with: options)
        
        var decisions = [String: OptimizelyDecision]()
        
        keys.forEach { key in
            let decision = decide(key: key, options: options)
            if !allOptions.contains(.enabledOnly) || (decision.enabled != nil && decision.enabled!) {
                decisions[key] = decision
            }
        }
                
        return decisions
    }
    
    /// Returns a key-map of decision results for all active flag keys.
    ///
    /// - Parameters:
    ///   - options: An array of options for decision-making.
    /// - Returns: A dictionary of all decision results, mapped by flag keys.
    public func decideAll(options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        guard let optimizely = self.optimizely, let config = optimizely.config else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }

        let keys = config.getFeatureFlags().map{ $0.key }

        return decideAll(keys: keys, options: options)
    }

    /// Track an event.
    ///
    /// - Parameters:
    ///   - eventKey: The event name.
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean).
    /// - Throws: `OptimizelyError` if an error is detected.
    public func trackEvent(eventKey: String,
                           eventTags: OptimizelyEventTags? = nil) throws {
        
        guard let optimizely = self.optimizely, let _ = optimizely.config else {
            throw OptimizelyError.sdkNotReady
        }

        try optimizely.track(eventKey: eventKey,
                             userId: userId,
                             attributes: attributes,
                             eventTags: eventTags)
    }

}

extension OptimizelyUserContext {
    
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
        return (optimizely?.defaultDecideOptions ?? []) + (options ?? [])
    }
    
}

extension OptimizelyUserContext: Equatable {
    
    public static func ==(lhs: OptimizelyUserContext, rhs: OptimizelyUserContext) -> Bool {
        return lhs.userId == rhs.userId &&
            (lhs.attributes as NSDictionary).isEqual(to: rhs.attributes)
    }
    
}
