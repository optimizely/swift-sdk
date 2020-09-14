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

@objc(OptimizelyUserContext)
@objcMembers public class ObjcOptimizelyUserContext: NSObject {
    var userContext: OptimizelyUserContext
    
    public var userId: String {
        return userContext.userId
    }
    
    public var attributes: [String: Any] {
        return userContext.attributes
    }
    
    public init(userId: String, attributes: [String: Any]? = nil) {
        userContext = OptimizelyUserContext(userId: userId, attributes: attributes)
    }
    
    init?(user: OptimizelyUserContext?) {
        guard let user = user else { return nil }
        self.userContext = user
    }
    
    public func setAttribute(key: String, value: Any) {
        userContext.setAttribute(key: key, value: value)
    }
}

@objc(OptimizelyDecision)
@objcMembers public class ObjcOptimizelyDecision: NSObject {
    public let enabled: NSNumber?
    public let variables: OptimizelyJSON?
    public let variationKey: String?
    public let ruleKey: String?

    public let flagKey: String
    public let user: ObjcOptimizelyUserContext?
    public let reasons: [String]
    
    init(decision: OptimizelyDecision) {
        if let en = decision.enabled {
            enabled = NSNumber(value: en)
        } else {
            enabled = nil
        }
        
        variables = decision.variables
        variationKey = decision.variationKey
        ruleKey = decision.ruleKey
        
        flagKey = decision.flagKey
        user = ObjcOptimizelyUserContext(user: decision.user)
        reasons = decision.reasons
    }
}


extension OptimizelyClient {
    
    @available(swift, obsoleted: 1.0)
    @objc(setUserContext:)
    public func objcSetUserContext(_ user: ObjcOptimizelyUserContext) {
        setUserContext(user.userContext)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(setDefaultDecideOptions:)
    public func objcSetDefaultDecideOptions(_ options: [Int]) {
        setDefaultDecideOptions(mapOptionsObjcToSwift(options) ?? [])
    }

    @available(swift, obsoleted: 1.0)
    @objc(decideWithKey:user:options:)
    public func objcDecide(key: String,
                           user: ObjcOptimizelyUserContext? = nil,
                           options: [Int]? = nil) -> ObjcOptimizelyDecision {
        return ObjcOptimizelyDecision(decision: decide(key: key,
                                                       user: user?.userContext,
                                                       options: mapOptionsObjcToSwift(options)))
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(decideAllWithKeys:user:options:)
    public func objcDecideAll(keys: [String]?,
                              user: ObjcOptimizelyUserContext? = nil,
                              options: [Int]? = nil) -> [String: ObjcOptimizelyDecision] {
        let decisionsMap = decideAll(keys: keys,
                                     user: user?.userContext,
                                     options: mapOptionsObjcToSwift(options))
        
        return decisionsMap.mapValues { ObjcOptimizelyDecision(decision: $0) }
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(trackWithEventKey:user:eventTags:error:)
    /// Track an event
    ///
    /// - Parameters:
    ///   - eventKey: The event name
    ///   - user: The user context associated with the event to track
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
    /// - Throws: `OptimizelyError` if error is detected
    public func objcTrack(eventKey: String,
                          user: ObjcOptimizelyUserContext? = nil,
                          eventTags: [String: Any]? = nil) throws {
        try track(eventKey: eventKey,
                  user: user?.userContext,
                  eventTags: eventTags)
    }

}

fileprivate func mapOptionsObjcToSwift(_ options: [Int]?) -> [OptimizelyDecideOption]? {
    return options?.compactMap{ OptimizelyDecideOption(rawValue: $0) }
}

fileprivate func mapOptionsSwiftToObjc(_ options: [OptimizelyDecideOption]?) -> [Int]? {
    return options?.compactMap{ $0.rawValue }
}
