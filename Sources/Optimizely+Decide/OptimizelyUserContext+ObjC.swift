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

@objc(OptimizelyUserContext)
@objcMembers public class ObjcOptimizelyUserContext: NSObject {
    var userContext: OptimizelyUserContext
    
    public var userId: String {
        return userContext.userId
    }
    
    public var attributes: [String: Any] {
        return userContext.attributes as [String: Any]
    }
    
    public var optimizely: OptimizelyClient? {
        return userContext.optimizely
    }

    public init(optimizely: OptimizelyClient, userId: String, attributes: [String: Any]? = nil, region: String = "US") {
        userContext = OptimizelyUserContext(optimizely: optimizely, userId: userId, attributes: attributes)
    }
    
    public init(user: OptimizelyUserContext, region: String = "US") {
        self.userContext = user
    }

    public func setAttribute(key: String, value: Any) {
        userContext.setAttribute(key: key, value: value)
    }
    
    public func decide(key: String, options: [Int]? = nil) -> ObjcOptimizelyDecision {
        let decision = userContext.decide(key: key, options: mapOptionsObjcToSwift(options))
        return ObjcOptimizelyDecision(decision: decision)
    }
    
    public func decide(keys: [String], options: [Int]? = nil) -> [String: ObjcOptimizelyDecision] {
        let decisionsMap = userContext.decide(keys: keys, options: mapOptionsObjcToSwift(options))
        return decisionsMap.mapValues { ObjcOptimizelyDecision(decision: $0) }
    }
    
    public func decideAll(options: [Int]? = nil) -> [String: ObjcOptimizelyDecision] {
        let decisionsMap = userContext.decideAll(options: mapOptionsObjcToSwift(options))
        return decisionsMap.mapValues { ObjcOptimizelyDecision(decision: $0) }
    }
    
    public func trackEvent(eventKey: String, eventTags: [String: Any]? = nil) throws {
        try userContext.trackEvent(eventKey: eventKey, eventTags: eventTags)
    }

}

@objc(OptimizelyDecision)
@objcMembers public class ObjcOptimizelyDecision: NSObject {
    public let variationKey: String?
    public let enabled: Bool
    public let variables: OptimizelyJSON
    public let ruleKey: String?

    public let flagKey: String
    public let userContext: ObjcOptimizelyUserContext
    public let reasons: [String]
    
    init(decision: OptimizelyDecision) {
        variationKey = decision.variationKey
        variables = decision.variables
        enabled = decision.enabled
        ruleKey = decision.ruleKey
        
        flagKey = decision.flagKey
        userContext = ObjcOptimizelyUserContext(user: decision.userContext, region: "US")
        reasons = decision.reasons
    }
}

extension OptimizelyClient {
    
    @available(swift, obsoleted: 1.0)
    @objc(createUserContextWithUserId:attributes:)
    public func objcCreateUserContext(userId: String, attributes: [String: Any]? = nil) -> ObjcOptimizelyUserContext {
        let user = createUserContext(userId: userId, attributes: attributes)
        return ObjcOptimizelyUserContext(user: user, region: "US")
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(createUserContextWithUserId:attributes:region:)
    public func objcCreateUserContext(userId: String, attributes: [String: Any]? = nil, region: String) -> ObjcOptimizelyUserContext {
        let user = OptimizelyUserContext(optimizely: self, userId: userId, attributes: attributes, region: region)
        return ObjcOptimizelyUserContext(user: user, region: region)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc public convenience init(sdkKey: String,
                                  logger: OPTLogger?,
                                  eventDispatcher: _ObjcOPTEventDispatcher?,
                                  userProfileService: OPTUserProfileService?,
                                  periodicDownloadInterval: NSNumber?,
                                  defaultLogLevel: OptimizelyLogLevel,
                                  defaultDecideOptions: [Int]?) {
        self.init(sdkKey: sdkKey,
                  logger: logger,
                  eventDispatcher: SwiftEventDispatcher(eventDispatcher),
                  userProfileService: userProfileService,
                  periodicDownloadInterval: periodicDownloadInterval?.intValue,
                  defaultLogLevel: defaultLogLevel,
                  defaultDecideOptions: mapOptionsObjcToSwift(defaultDecideOptions))
    }

}

fileprivate func mapOptionsObjcToSwift(_ options: [Int]?) -> [OptimizelyDecideOption]? {
    return options?.compactMap { OptimizelyDecideOption(rawValue: $0) }
}

fileprivate func mapOptionsSwiftToObjc(_ options: [OptimizelyDecideOption]?) -> [Int]? {
    return options?.compactMap { $0.rawValue }
}
