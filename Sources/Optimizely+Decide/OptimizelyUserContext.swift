//
// Copyright 2021, Optimizely, Inc. and contributors
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

/// An object for user contexts that the SDK will use to make decisions for.
public class OptimizelyUserContext {
    weak var optimizely: OptimizelyClient?
    public var userId: String
    
    var atomicAttributes: AtomicProperty<[String: Any?]>
    public var attributes: [String: Any?] {
        return atomicAttributes.property ?? [:]
    }
    
    var forcedDecisions: AtomicDictionary<FDKeys, String>?
    
    var clone: OptimizelyUserContext? {
        guard let optimizely = self.optimizely else { return nil }
        
        let userContext = OptimizelyUserContext(optimizely: optimizely, userId: userId, attributes: attributes)
        if let fds = forcedDecisions {
            userContext.forcedDecisions = AtomicDictionary<FDKeys, String>(fds.property)
        }
        
        return userContext
    }
    
    let logger = OPTLoggerFactory.getLogger()
    
    /// OptimizelyUserContext init
    ///
    /// - Parameters:
    ///   - optimizely: An instance of OptimizelyClient to be used for decisions.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    public init(optimizely: OptimizelyClient,
                userId: String,
                attributes: [String: Any?]? = nil) {
        self.optimizely = optimizely
        self.userId = userId
        self.atomicAttributes = AtomicProperty(property: attributes ?? [:])
    }
    
    /// Sets an attribute for a given key.
    /// - Parameters:
    ///   - key: An attribute key
    ///   - value: An attribute value
    public func setAttribute(key: String, value: Any?) {
        atomicAttributes.performAtomic { attributes in
            attributes[key] = value
        }
    }
    
    /// Returns a decision result for a given flag key and a user context, which contains all data required to deliver the flag or experiment.
    ///
    /// If the SDK finds an error (__sdkNotReady__, etc), it’ll return a decision with `nil` for `enabled` and `variationKey`. The decision will include an error message in `reasons` (regardless of the __includeReasons__ option).
    ///
    /// - Parameters:
    ///   - key: A flag key for which a decision will be made.
    ///   - user: A user context. This is optional when a user context has been set before.
    ///   - options: An array of options for decision-making.
    /// - Returns: A decision result.
    public func decide(key: String,
                       options: [OptimizelyDecideOption]? = nil) -> OptimizelyDecision {
        
        guard let optimizely = self.optimizely, let clone = self.clone else {
            return OptimizelyDecision.errorDecision(key: key, user: self, error: .sdkNotReady)
        }
        
        return optimizely.decide(user: clone, key: key, options: options)
    }
    
    /// Returns a key-map of decision results for multiple flag keys and a user context.
    ///
    /// - If the SDK finds an error (__flagKeyInvalid__, etc) for a key, the response will include a decision for the key showing `reasons` for the error (regardless of __includeReasons__ in options).
    /// - The SDK will always return key-mapped decisions. When it can not process requests (on __sdkNotReady__ error), it’ll return an empty map after logging the errors.
    ///
    /// - Parameters:
    ///   - keys: An array of flag keys for which decisions will be made. When set to `nil`, the SDK will return decisions for all active flag keys.
    ///   - options: An array of options for decision-making.
    /// - Returns: A dictionary of all decision results, mapped by flag keys.
    public func decide(keys: [String],
                       options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        
        guard let optimizely = self.optimizely, let clone = self.clone else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        return optimizely.decide(user: clone, keys: keys, options: options)
    }
    
    /// Returns a key-map of decision results for all active flag keys.
    ///
    /// - Parameters:
    ///   - options: An array of options for decision-making.
    /// - Returns: A dictionary of all decision results, mapped by flag keys.
    public func decideAll(options: [OptimizelyDecideOption]? = nil) -> [String: OptimizelyDecision] {
        guard let optimizely = self.optimizely, let clone = self.clone else {
            logger.e(OptimizelyError.sdkNotReady)
            return [:]
        }
        
        return optimizely.decideAll(user: clone, options: options)
    }
    
    /// Tracks an event.
    ///
    /// - Parameters:
    ///   - eventKey: The event name.
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean).
    /// - Throws: `OptimizelyError` if an error is detected.
    public func trackEvent(eventKey: String,
                           eventTags: OptimizelyEventTags? = nil) throws {
        
        guard let optimizely = self.optimizely else {
            throw OptimizelyError.sdkNotReady
        }
        
        try optimizely.track(eventKey: eventKey,
                             userId: userId,
                             attributes: attributes,
                             eventTags: eventTags)
    }
    
}

// MARK: - ForcedDecisions

extension OptimizelyUserContext {
    
    struct FDKeys: Hashable {
        let flagKey: String
        let ruleKey: String?
    }

    /// Sets the forced decision (variation key) for a given flag and an optional rule.
    /// - Parameters:
    ///   - flagKey: A flag key.
    ///   - ruleKey: An experiment or delivery rule key (optional).
    ///   - variationKey: A variation key.
    /// - Returns: true if the forced decision has been set successfully.
    public func setForcedDecision(flagKey: String,
                                  ruleKey: String? = nil,
                                  variationKey: String) -> Bool {
        
        guard optimizely?.config != nil else {
            logger.e(OptimizelyError.sdkNotReady)
            return false
        }
        
        // create on the first setForcedDecision call
        
        if forcedDecisions == nil {
            forcedDecisions = AtomicDictionary<FDKeys, String>()
        }
        
        forcedDecisions![FDKeys(flagKey: flagKey, ruleKey: ruleKey)] = variationKey
        return true
    }
    
    /// Returns the forced decision for a given flag and an optional rule.
    /// - Parameters:
    ///   - flagKey: A flag key.
    ///   - ruleKey: An experiment or delivery rule key (optional).
    /// - Returns: A variation key or nil if forced decisions are not set for the parameters.
    public func getForcedDecision(flagKey: String, ruleKey: String? = nil) -> String? {
        guard optimizely?.config != nil else {
            logger.e(OptimizelyError.sdkNotReady)
            return nil
        }
        
        guard forcedDecisions != nil else { return nil }
        
        return findForcedDecision(flagKey: flagKey, ruleKey: ruleKey)
    }
    
    /// Removes the forced decision for a given flag and an optional rule.
    /// - Parameters:
    ///   - flagKey: A flag key.
    ///   - ruleKey: An experiment or delivery rule key (optional).
    /// - Returns: true if the forced decision has been removed successfully.
    public func removeForcedDecision(flagKey: String, ruleKey: String? = nil) -> Bool {
        guard optimizely?.config != nil else {
            logger.e(OptimizelyError.sdkNotReady)
            return false
        }
        
        guard let fds = forcedDecisions else { return false }

        if findForcedDecision(flagKey: flagKey, ruleKey: ruleKey) != nil {
            fds[FDKeys(flagKey: flagKey, ruleKey: ruleKey)] = nil
            return true
        }
        
        return false
    }
    
    /// Removes all forced decisions bound to this user context.
    /// - Returns: true if forced decisions have been removed successfully.
    public func removeAllForcedDecisions() -> Bool {
        guard optimizely?.config != nil else {
            logger.e(OptimizelyError.sdkNotReady)
            return false
        }
        
        if let fds = forcedDecisions {
            fds.removeAll()
        }
        
        return true
    }
    
    func findForcedDecision(flagKey: String, ruleKey: String? = nil) -> String? {
        guard let fds = forcedDecisions else { return nil }
        
        return fds[FDKeys(flagKey: flagKey, ruleKey: ruleKey)]
    }
    
    func findValidatedForcedDecision(flagKey: String,
                                     ruleKey: String?,
                                     options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons(options: options)
        
        if let variationKey = findForcedDecision(flagKey: flagKey, ruleKey: ruleKey) {
            if let variation = optimizely?.getFlagVariationByKey(flagKey: flagKey, variationKey: variationKey) {
                let info = LogMessage.userHasForcedDecision(userId, flagKey, ruleKey, variationKey)
                logger.d(info)
                reasons.addInfo(info)
                return DecisionResponse(result: variation, reasons: reasons)
            } else {
                let info = LogMessage.userHasForcedDecisionButInvalid(userId, flagKey, ruleKey)
                logger.d(info)
                reasons.addInfo(info)
            }
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
}

// MARK: - Equatable

extension OptimizelyUserContext: Equatable {
    
    public static func == (lhs: OptimizelyUserContext, rhs: OptimizelyUserContext) -> Bool {
        return lhs.userId == rhs.userId &&
            (lhs.attributes as NSDictionary).isEqual(to: rhs.attributes as [AnyHashable: Any])
    }
    
}

// MARK: - CustomStringConvertible

extension OptimizelyUserContext: CustomStringConvertible {
    public var description: String {
        return "{ userId: \(userId), attributes: \(attributes) }"
    }
}
