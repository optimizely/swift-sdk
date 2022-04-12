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

/// An object for user contexts that the SDK will use to make decisions for.
public class OptimizelyUserContext {
    weak var optimizely: OptimizelyClient?
    public var userId: String
    
    var atomicAttributes: AtomicProperty<[String: Any?]>
    public var attributes: [String: Any?] {
        return atomicAttributes.property ?? [:]
    }
    
    var forcedDecisions: AtomicDictionary<OptimizelyDecisionContext, OptimizelyForcedDecision>?
    
    var atomicQualifiedSegments: AtomicArray<String>?
    public var qualifiedSegments: [String]? {
        get {
            return atomicQualifiedSegments?.property
        }
        set {
            if let value = newValue {
                atomicQualifiedSegments = AtomicArray<String>(value)
            } else {
                atomicQualifiedSegments = nil
            }
        }
    }

    var clone: OptimizelyUserContext? {
        guard let optimizely = self.optimizely else { return nil }
        
        let userContext = OptimizelyUserContext(optimizely: optimizely, userId: userId, attributes: attributes)
        if let fds = forcedDecisions {
            userContext.forcedDecisions = AtomicDictionary<OptimizelyDecisionContext, OptimizelyForcedDecision>(fds.property)
        }
        
        if let qs = atomicQualifiedSegments {
            userContext.atomicQualifiedSegments = AtomicArray<String>(qs.property)
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

// MARK: - AudienceSegments

let testApiKeyForAudienceSegments = "W4WzcEs-ABgXorzY7h1LCQ"
let testUserIdForAudienceSegments = "d66a9d81923d4d2f99d8f64338976322"

extension OptimizelyUserContext {
    
    /// Fetch all qualified segments for the given user identifier (**userKey** and **userValue**).
    ///
    /// The **userId** of this context will be used by default when the user identifier is not provided.
    /// The segments fetched will be saved in **qualifiedSegments** and can be accessed any time.
    ///
    /// - Parameters:
    ///   - apiKey: the public API key for the ODP account from which the audience segments will be fetched.
    ///   - userKey: The name of the user identifier (optional).
    ///   - userValue: The value of the user identifier (optional).
    ///   - options: A set of options for fetching qualified segments (optional).
    ///   - completionHandler: A completion handler to be called with the fetch status success/failure.
    public func fetchQualifiedSegments(apiKey: String,
                                       userKey: String? = nil,
                                       userValue: String? = nil,
                                       options: [OptimizelySegmentOption] = [],
                                       completionHandler: @escaping (OptimizelyError?) -> Void) {
        guard let optimizely = self.optimizely else {
            completionHandler(.sdkNotReady)
            return
        }

        let userValue = userValue ?? userId
                
        optimizely.fetchQualifiedSegments(apiKey: apiKey,
                                          userKey: userKey,
                                          userValue: userValue,
                                          options: options) { segments, err in
            guard err == nil, let segments = segments else {
                let error = err ?? OptimizelyError.fetchSegmentsFailed("invalid segments")
                self.logger.e(error)
                completionHandler(error)
                return
            }
                
            self.atomicQualifiedSegments = AtomicArray(segments)
            completionHandler(nil)
        }
    }

    // true if the user is qualified for the given segment name
    public func isQualifiedFor(segment: String) -> Bool {
        return atomicQualifiedSegments?.contains(segment) ?? false
    }
    
}

// MARK: - ForcedDecisions

/// Decision Context
public struct OptimizelyDecisionContext: Hashable {
    public let flagKey: String
    public let ruleKey: String?

    public init(flagKey: String, ruleKey: String? = nil) {
        self.flagKey = flagKey
        self.ruleKey = ruleKey
    }
}

/// Forced Decision
public struct OptimizelyForcedDecision {
    public let variationKey: String
    
    public init(variationKey: String) {
        self.variationKey = variationKey
    }
}

extension OptimizelyUserContext {
        
    /// Sets the forced decision for a given decision context.
    /// - Parameters:
    ///   - context: A decision context.
    ///   - decision: A forced decision.
    /// - Returns: true if the forced decision has been set successfully.
    public func setForcedDecision(context: OptimizelyDecisionContext, decision: OptimizelyForcedDecision) -> Bool {
        // create on the first setForcedDecision call
        
        if forcedDecisions == nil {
            forcedDecisions = AtomicDictionary<OptimizelyDecisionContext, OptimizelyForcedDecision>()
        }
        
        forcedDecisions![context] = decision
        return true
    }
    
    /// Returns the forced decision for a given decision context.
    /// - Parameters:
    ///   - context: A decision context
    /// - Returns: A forced decision or nil if forced decisions are not set for the decision context.
    public func getForcedDecision(context: OptimizelyDecisionContext) -> OptimizelyForcedDecision? {
        guard let fds = forcedDecisions else { return nil }
        
        return fds[context]
    }
    
    /// Removes the forced decision for a given decision context.
    /// - Parameters:
    ///   - context: A decision context.
    /// - Returns: true if the forced decision has been removed successfully.
    public func removeForcedDecision(context: OptimizelyDecisionContext) -> Bool {
        guard let fds = forcedDecisions else { return false }

        if getForcedDecision(context: context) != nil {
            fds[context] = nil
            return true
        }
        
        return false
    }
    
    /// Removes all forced decisions bound to this user context.
    /// - Returns: true if forced decisions have been removed successfully.
    public func removeAllForcedDecisions() -> Bool {
        if let fds = forcedDecisions {
            fds.removeAll()
        }
        
        return true
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
