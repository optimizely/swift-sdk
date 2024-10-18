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
        
    private var atomicAttributes: AtomicProperty<[String: Any?]>
    public var attributes: [String: Any?] {
        return atomicAttributes.property ?? [:]
    }
    
    private var atomicForcedDecisions: AtomicProperty<[OptimizelyDecisionContext: OptimizelyForcedDecision]>
    var forcedDecisions: [OptimizelyDecisionContext: OptimizelyForcedDecision]? {
        return atomicForcedDecisions.property
    }
    
    private var atomicQualifiedSegments: AtomicProperty<[String]>
    /// an array of segment names that the user is qualified for. The result of **fetchQualifiedSegments()** will be saved here.
    public var qualifiedSegments: [String]? {
        get {
            return atomicQualifiedSegments.property
        }
        // keep this public set api for clients to set directly (testing/debugging)
        set {
            atomicQualifiedSegments.property = newValue
        }
    }

    var clone: OptimizelyUserContext? {
        guard let optimizely = self.optimizely else { return nil }
        
        let userContext = OptimizelyUserContext(optimizely: optimizely, userId: userId, attributes: attributes, identify: false)
        
        if let fds = forcedDecisions {
            userContext.atomicForcedDecisions.property = fds
        }
        
        if let qs = qualifiedSegments {
            userContext.atomicQualifiedSegments.property = qs
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
    public convenience init(optimizely: OptimizelyClient,
                            userId: String,
                            attributes: [String: Any?]? = nil) {
        self.init(optimizely: optimizely, userId: userId, attributes: attributes ?? [:], identify: true)
    }
    
    init(optimizely: OptimizelyClient,
         userId: String,
         attributes: [String: Any?],
         identify: Bool) {
        self.optimizely = optimizely
        self.userId = userId
        
        let lock = DispatchQueue(label: "user-context")
        self.atomicAttributes = AtomicProperty(property: attributes, lock: lock)
        self.atomicForcedDecisions = AtomicProperty(property: nil, lock: lock)
        self.atomicQualifiedSegments = AtomicProperty(property: nil, lock: lock)
        let _vuid = optimizely.vuid
        if identify {
            // async call so event building overhead is not blocking context creation
            lock.async {
                self.optimizely?.identifyUserToOdp(userId: userId, vuid: _vuid)
            }
        }
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

// MARK: - ODP

extension OptimizelyUserContext {
    
    /// Fetch (non-blocking) all qualified segments for the user context.
    ///
    /// The segments fetched will be saved in **qualifiedSegments** and can be accessed any time.
    /// On failure, **qualifiedSegments** will be nil and one of these errors will be returned:
    /// - OptimizelyError.invalidSegmentIdentifier
    /// - OptimizelyError.fetchSegmentsFailed(String)
    ///
    /// - Parameters:
    ///   - options: A set of options for fetching qualified segments (optional).
    ///   - completionHandler: A completion handler to be called with the fetch result. On success, it'll pass a nil error. On failure, it'll pass a non-nil error .
    public func fetchQualifiedSegments(options: [OptimizelySegmentOption] = [],
                                       completionHandler: @escaping (OptimizelyError?) -> Void) {
        // on failure, qualifiedSegments should be reset if a previous value exists.
        self.atomicQualifiedSegments.property = nil

        guard let optimizely = self.optimizely else {
            completionHandler(.sdkNotReady)
            return
        }
        
        optimizely.fetchQualifiedSegments(userId: userId, options: options) { segments, err in
            guard err == nil, let segments = segments else {
                let error = err ?? OptimizelyError.fetchSegmentsFailed("invalid segments")
                self.logger.e(error)
                completionHandler(error)
                return
            }
                
            self.atomicQualifiedSegments.property = segments
            completionHandler(nil)
        }
    }
    
    /// Fetch (non-blocking) all qualified segments for the user context.
    ///
    /// The segments fetched will be saved in **qualifiedSegments** and can be accessed any time.
    /// On failure, **qualifiedSegments** will be nil and one of these errors will be thrown:
    /// - OptimizelyError.invalidSegmentIdentifier
    /// - OptimizelyError.fetchSegmentsFailed(String)
    ///
    /// - Parameters:
    ///   - options: A set of options for fetching qualified segments (optional).
    /// - Throws: `OptimizelyError` if error is detected
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func fetchQualifiedSegments(options: [OptimizelySegmentOption] = []) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            fetchQualifiedSegments { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    /// Fetch (blocking) all qualified segments for the user context.
    ///
    /// Note that this call will block the calling thread until fetching is completed.
    /// The segments fetched will be saved in **qualifiedSegments** and can be accessed any time.
    /// On failure, **qualifiedSegments** will be nil and one of these errors will be thrown:
    /// - OptimizelyError.invalidSegmentIdentifier
    /// - OptimizelyError.fetchSegmentsFailed(String)
    ///
    /// - Parameters:
    ///   - options: A set of options for fetching qualified segments (optional).
    public func fetchQualifiedSegments(options: [OptimizelySegmentOption] = []) throws {
        var error: OptimizelyError?
        
        let semaphore = DispatchSemaphore(value: 0)
        fetchQualifiedSegments(options: options) { asyncError in
            error = asyncError
            semaphore.signal()
        }
        semaphore.wait()
        
        if let err = error { throw err }
    }
    
    /// Check if the user is qualified for the given segment.
    ///
    /// - Parameter segment: the segment name to check qualification for.
    /// - Returns: true if qualified.
    public func isQualifiedFor(segment: String) -> Bool {
        return atomicQualifiedSegments.property?.contains(segment) ?? false
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
public struct OptimizelyForcedDecision: Equatable {
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
            atomicForcedDecisions.property = [:]
        }
        
        atomicForcedDecisions.performAtomic { property in
            property[context] = decision
        }
        
        return true
    }
    
    /// Returns the forced decision for a given decision context.
    /// - Parameters:
    ///   - context: A decision context
    /// - Returns: A forced decision or nil if forced decisions are not set for the decision context.
    public func getForcedDecision(context: OptimizelyDecisionContext) -> OptimizelyForcedDecision? {
        return atomicForcedDecisions.property?[context]
    }
    
    /// Removes the forced decision for a given decision context.
    /// - Parameters:
    ///   - context: A decision context.
    /// - Returns: true if the forced decision has been removed successfully.
    public func removeForcedDecision(context: OptimizelyDecisionContext) -> Bool {
        var exist = false
        atomicForcedDecisions.performAtomic { property in
            exist = property[context] != nil
            property[context] = nil
        }
        
        return exist
    }
    
    /// Removes all forced decisions bound to this user context.
    /// - Returns: true if forced decisions have been removed successfully.
    public func removeAllForcedDecisions() -> Bool {
        atomicForcedDecisions.property = nil
        return true
    }
    
}

// MARK: - Equatable

extension OptimizelyUserContext: Equatable {
    
    public static func == (lhs: OptimizelyUserContext, rhs: OptimizelyUserContext) -> Bool {
        return lhs.userId == rhs.userId &&
        (lhs.attributes as NSDictionary).isEqual(to: rhs.attributes as [AnyHashable: Any]) &&
        lhs.forcedDecisions == rhs.forcedDecisions &&
        lhs.qualifiedSegments == rhs.qualifiedSegments
    }
    
}

// MARK: - CustomStringConvertible

extension OptimizelyUserContext: CustomStringConvertible {
    public var description: String {
        return "{ userId: \(userId), attributes: \(attributes) }"
    }
}
