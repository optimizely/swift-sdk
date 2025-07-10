//
// Copyright 2019-2022, Optimizely, Inc. and contributors
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

struct FeatureDecision {
    var experiment: ExperimentCore?
    let variation: Variation?
    let source: String
    var cmabUUID: String?
}

struct VariationDecision {
    var variation: Variation?
    var cmabError: Bool = false
    var cmabUUID: String?
}

typealias UserProfile = OPTUserProfileService.UPProfile

class DefaultDecisionService: OPTDecisionService {
    let bucketer: OPTBucketer
    let userProfileService: OPTUserProfileService
    let cmabService: CmabService
    let group: DispatchGroup = DispatchGroup()
    // thread-safe lazy logger load (after HandlerRegisterService ready)
    private let threadSafeLogger = ThreadSafeLogger()
    // user-profile-service read-modify-write lock for supporting multiple clients
    static let upsRMWLock = DispatchQueue(label: "ups-rmw")
    
    var logger: OPTLogger {
        return threadSafeLogger.logger
    }
    
    init(userProfileService: OPTUserProfileService,
         cmabService: CmabService = DefaultCmabService.createDefault()) {
        self.bucketer = DefaultBucketer()
        self.userProfileService = userProfileService
        self.cmabService = cmabService
    }
    
    init(userProfileService: OPTUserProfileService,
         bucketer: OPTBucketer,
         cmabService: CmabService = DefaultCmabService.createDefault()) {
        self.bucketer = bucketer
        self.userProfileService = userProfileService
        self.cmabService = cmabService
    }
    
    // MARK: - CMAB decision
    
    /// Get decision for CMAB Experiment
    /// - Parameters:
    ///   - config: The project configuration containing experiment and feature details.
    ///   - experiment: The CMAB experiment to evaluate.
    ///   - user: The user context containing user ID and attributes.
    ///   - bucketingId: User bucketing id
    ///   - isAsync: Controls synchronous or asynchronous decision.
    ///   - options: Optional decision options (e.g., ignore user profile service).
    /// - Returns: A `CMABDecisionResult` containing the CMAB decisions( variation id, cmabUUID) with reasons
    
    private func getDecisionForCmabExperiment(config: ProjectConfig,
                                              experiment: Experiment,
                                              user: OptimizelyUserContext,
                                              bucketingId: String,
                                              isAsync: Bool,
                                              options: [OptimizelyDecideOption]?) -> DecisionResponse<VariationDecision> {
        let reasons = DecisionReasons(options: options)
        guard let cmab = experiment.cmab else {
            logger.e("The experiment isn't a CMAB experiment")
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        // We do not choose the alternative solution (checking and rejecting if on the main thread)
        // because it would lead to inconsistent decision results:
        // - If the decision is called from the main thread, CMAB logic is skipped and an error is logged.
        // - If called from a background thread, CMAB logic is included.
        // This means the same API could return different results based on thread context, which is confusing for users.
        // Instead, we pass an `isAsync` boolean to ensure that CMAB will be evaluated only for async calls.
        
        guard isAsync else {
            let info = LogMessage.cmabNotSupportedInSyncMode
            logger.e(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        let dummyEntityId = "$"
        let cmabTrafficAllocation = TrafficAllocation(entityId: dummyEntityId, endOfRange: cmab.trafficAllocation)
        let bucketedResponse = (bucketer as? DefaultBucketer)?.bucketToEntityId(config: config, experiment: experiment, bucketingId: bucketingId, trafficAllocation: [cmabTrafficAllocation])
        
        if let _reasons = bucketedResponse?.reasons {
            reasons.merge(_reasons)
        }
        
        let entityId = bucketedResponse?.result
        
        // This means the user is not in the cmab experiment
        if entityId == nil {
            let info = LogMessage.userNotInCmabExperiment(user.userId, experiment.key)
            logger.d(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        // Fetch CMAB decision
        let response = cmabService.getDecision(config: config, userContext: user, ruleId: experiment.id, options: options ?? [])
        var cmabDecision: CmabDecision?
        switch response {
            case .success(let decision):
                cmabDecision = decision
            case .failure:
                let info = LogMessage.cmabFetchFailed(experiment.key)
                self.logger.e(info)
                reasons.addInfo(info)
                let nilVariation = VariationDecision(variation: nil, cmabError: true, cmabUUID: nil)
                return DecisionResponse(result: nilVariation, reasons: reasons)
        }
        
        if let cmabDecision = cmabDecision,
           let experiment = config.getExperiment(id: experiment.id),
           let bucketedVariation = experiment.getVariation(id: cmabDecision.variationId) {
            let variationDecision = VariationDecision(variation: bucketedVariation, cmabUUID: cmabDecision.cmabUUID)
            return DecisionResponse(result: variationDecision, reasons: reasons)
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
    // MARK: - Experiment Decision
    
    /// Determines the variation for a user in a given experiment.
    /// - Parameters:
    ///   - config: The project configuration containing experiment and feature details.
    ///   - experiment: The experiment to evaluate.
    ///   - user: The user context containing user ID and attributes.
    ///   - options: Optional decision options (e.g., ignore user profile service).
    /// - Returns: A `DecisionResponse` containing the assigned variation (if any) and decision reasons.
    func getVariation(config: ProjectConfig,
                      experiment: Experiment,
                      user: OptimizelyUserContext,
                      options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<Variation> {
        let userId = user.userId
        let ignoreUPS = (options ?? []).contains(.ignoreUserProfileService)
        var profileTracker: UserProfileTracker?
        if !ignoreUPS {
            profileTracker = UserProfileTracker(userId: userId, userProfileService: self.userProfileService, logger: self.logger)
            profileTracker?.loadUserProfile()
        }
        
        // isAsync to `false` for backward compatibility
        let response = getVariation(config: config, experiment: experiment, user: user, isAsync: false, userProfileTracker: profileTracker)
        
        if (!ignoreUPS) {
            profileTracker?.save()
        }
        
        return DecisionResponse(result: response.result?.variation, reasons: response.reasons)
    }
    
    /// Determines the variation for a user in an experiment, considering user profile and decision rules.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - experiment: The experiment to evaluate.
    ///   - user: The user context.
    ///   - options: Optional decision options.
    ///   - isAsync: Controls synchronous or asynchronous decision.
    ///   - userProfileTracker: Optional tracker for user profile data.
    /// - Returns: A `DecisionResponse` with the variation (if any) and decision reasons.
    func getVariation(config: ProjectConfig,
                      experiment: Experiment,
                      user: OptimizelyUserContext,
                      options: [OptimizelyDecideOption]? = nil,
                      isAsync: Bool,
                      userProfileTracker: UserProfileTracker?) -> DecisionResponse<VariationDecision> {
        let reasons = DecisionReasons(options: options)
        let userId = user.userId
        let attributes = user.attributes
        let experimentId = experiment.id
        
        // ---- check if the experiment is running ----
        if !experiment.isActivated {
            let info = LogMessage.experimentNotRunning(experiment.key)
            logger.i(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        // ---- check if the user is forced into a variation ----
        let decisionResponse = config.getForcedVariation(experimentKey: experiment.key, userId: userId)
        
        reasons.merge(decisionResponse.reasons)
        
        if let variationId = decisionResponse.result?.id,
           let variation = experiment.getVariation(id: variationId) {
            let variationDecision = VariationDecision(variation: variation)
            return DecisionResponse(result: variationDecision, reasons: reasons)
        }
        
        // ---- check to see if user is white-listed for a certain variation ----
        if let variationKey = experiment.forcedVariations[userId] {
            if let variation = experiment.getVariation(key: variationKey) {
                let info = LogMessage.forcedVariationFound(variationKey, userId)
                logger.i(info)
                reasons.addInfo(info)
                let variationDecision = VariationDecision(variation: variation)
                return DecisionResponse(result: variationDecision, reasons: reasons)
            }
            
            // mapped to invalid variation - ignore and continue for other deciesions
            let info = LogMessage.forcedVariationFoundButInvalid(variationKey, userId)
            logger.e(info)
            reasons.addInfo(info)
        }
        
        // Load variation from tracker
        if let profile = userProfileTracker?.userProfile,
           let variationId = getVariationIdFromProfile(profile: profile, experimentId: experimentId),
           let variation = experiment.getVariation(id: variationId) {
            
            let info = LogMessage.gotVariationFromUserProfile(variation.key, experiment.key, userId)
            logger.i(info)
            reasons.addInfo(info)
            let variationDecision = VariationDecision(variation: variation)
            return DecisionResponse(result: variationDecision, reasons: reasons)
        }
        
        
        var variationDecision: VariationDecision?
        // ---- check if the user passes audience targeting before bucketing ----
        let audienceResponse = doesMeetAudienceConditions(config: config,
                                                          experiment: experiment,
                                                          user: user)
        reasons.merge(audienceResponse.reasons)
        
        if audienceResponse.result ?? false {
            // Acquire bucketingId
            let bucketingId = getBucketingId(userId: userId, attributes: attributes)
            
            if experiment.isCmab {
                let cmabDecisionResponse = getDecisionForCmabExperiment(config: config,
                                                                        experiment: experiment,
                                                                        user: user,
                                                                        bucketingId: bucketingId,
                                                                        isAsync: isAsync,
                                                                        options: options)
                reasons.merge(cmabDecisionResponse.reasons)
                variationDecision = cmabDecisionResponse.result
            } else {
                // bucket user into a variation
                let decisionResponse = bucketer.bucketExperiment(config: config,
                                                                 experiment: experiment,
                                                                 bucketingId: bucketingId)
                reasons.merge(decisionResponse.reasons)
                if let variation = decisionResponse.result {
                    variationDecision = VariationDecision(variation: variation)
                }
            }
            
            if let variation = variationDecision?.variation {
                let info = LogMessage.userBucketedIntoVariationInExperiment(userId, experiment.key, variation.key)
                logger.i(info)
                reasons.addInfo(info)
                userProfileTracker?.updateProfile(experiment: experiment, variation: variation)
            } else {
                let info = LogMessage.userNotBucketedIntoVariation(userId)
                logger.i(info)
                reasons.addInfo(info)
            }
            
        } else {
            let info = LogMessage.userNotInExperiment(userId, experiment.key)
            logger.i(info)
            reasons.addInfo(info)
        }
        
        return DecisionResponse(result: variationDecision, reasons: reasons)
    }
    
    // MARK: - Feature Flag Decision
    
    /// Determines the feature decision for a user for a specific feature flag.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - featureFlag: The feature flag to evaluate.
    ///   - user: The user context.
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the feature decision (if any) and reasons.
    func getVariationForFeature(config: ProjectConfig,
                                featureFlag: FeatureFlag,
                                user: OptimizelyUserContext,
                                options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        // isAsync to `false` for backward compatibility
        self.getVariationForFeature(config: config, featureFlag: featureFlag, user: user, isAsync: false, options: options)
    }
    
    /// Determines the feature decision for a user for a specific feature flag.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - featureFlag: The feature flag to evaluate.
    ///   - user: The user context.
    ///   - isAsync: Controls synchronous or asynchronous decision.
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the feature decision (if any) and reasons.
    func getVariationForFeature(config: ProjectConfig,
                                featureFlag: FeatureFlag,
                                user: OptimizelyUserContext,
                                isAsync: Bool,
                                options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        
        let response = getVariationForFeatureList(config: config, featureFlags: [featureFlag], user: user, isAsync: isAsync, options: options).first
        
        guard response?.result != nil else {
            let reasons = response?.reasons ?? DecisionReasons(options: options)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        return response!
    }
    
    /// Determines feature decisions for a list of feature flags.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - featureFlags: The list of feature flags to evaluate.
    ///   - user: The user context.
    ///   - isAsync: Controls synchronous or asynchronous decision
    ///   - options: Optional decision options.
    /// - Returns: An array of `DecisionResponse` objects, each containing a feature decision and reasons.
    func getVariationForFeatureList(config: ProjectConfig,
                                    featureFlags: [FeatureFlag],
                                    user: OptimizelyUserContext,
                                    isAsync: Bool,
                                    options: [OptimizelyDecideOption]? = nil) -> [DecisionResponse<FeatureDecision>] {
        
        let userId = user.userId
        let ignoreUPS = (options ?? []).contains(.ignoreUserProfileService)
        var profileTracker: UserProfileTracker?
        if !ignoreUPS {
            profileTracker = UserProfileTracker(userId: userId, userProfileService: self.userProfileService, logger: self.logger)
            profileTracker?.loadUserProfile()
        }
        
        var decisions = [DecisionResponse<FeatureDecision>]()
        
        for featureFlag in featureFlags {
            let flagDecisionResponse = getDecisionForFlag(config: config, featureFlag: featureFlag, user: user, userProfileTracker: profileTracker, isAsync: isAsync, options: options)
            decisions.append(flagDecisionResponse)
        }
        
        // save profile
        if !ignoreUPS {
            profileTracker?.save()
        }
        
        return decisions
    }
    
    /// Determines the feature decision for a feature flag, considering holdout, experiment and rollout
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - featureFlag: The feature flag to evaluate.
    ///   - user: The user context.
    ///   - userProfileTracker: Optional tracker for user profile data.
    ///   - isAsync: Controls synchronous or asynchronous decision
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the feature decision (if any) and reasons.
    func getDecisionForFlag(config: ProjectConfig,
                            featureFlag: FeatureFlag,
                            user: OptimizelyUserContext,
                            userProfileTracker: UserProfileTracker? = nil,
                            isAsync: Bool,
                            options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        let reasons = DecisionReasons(options: options)
        
        let holdouts = config.getHoldoutForFlag(id: featureFlag.id)
        for holdout in holdouts {
            let holdoutDecision = getVariationForHoldout(config: config,
                                                         flagKey: featureFlag.key,
                                                         holdout: holdout,
                                                         user: user,
                                                         options: options)
            reasons.merge(holdoutDecision.reasons)
            if let variation = holdoutDecision.result {
                let featureDecision = FeatureDecision(experiment: holdout, variation: variation, source: Constants.DecisionSource.holdout.rawValue)
                return DecisionResponse(result: featureDecision, reasons: reasons)
            }
        }
        
        let flagExpDecision = getVariationForFeatureExperiments(config: config, featureFlag: featureFlag, user: user, userProfileTracker: userProfileTracker, isAsync: isAsync, options: options)
        reasons.merge(flagExpDecision.reasons)
        
        if let decision = flagExpDecision.result {
            return DecisionResponse(result: decision, reasons: reasons)
        }
        
        let rolloutDecision = getVariationForFeatureRollout(config: config, featureFlag: featureFlag, user: user, options: options)
        reasons.merge(rolloutDecision.reasons)
        
        if let decision = rolloutDecision.result {
            return DecisionResponse(result: decision, reasons: reasons)
        } else {
            return DecisionResponse(result: nil, reasons: reasons)
        }
    }
    
    /// Determines the feature decision for a feature flag, considering experiments
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - featureFlag: The feature flag to evaluate.
    ///   - user: The user context.
    ///   - userProfileTracker: Optional tracker for user profile data.
    ///   - isAsync: Controls synchronous or asynchronous decision
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the feature decision (if any) and reasons.
    func getVariationForFeatureExperiments(config: ProjectConfig,
                                           featureFlag: FeatureFlag,
                                           user: OptimizelyUserContext,
                                           userProfileTracker: UserProfileTracker? = nil,
                                           isAsync: Bool,
                                           options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        let reasons = DecisionReasons(options: options)
        
        let experimentIds = featureFlag.experimentIds
        if experimentIds.isEmpty {
            let info = LogMessage.featureHasNoExperiments(featureFlag.key)
            logger.d(info)
            reasons.addInfo(info)
        }
        
        // Check if there are any experiment IDs inside feature flag
        // Evaluate each experiment ID and return the first bucketed experiment variation
        for experimentId in experimentIds {
            if let experiment = config.getExperiment(id: experimentId) {
                let decisionResponse = getVariationFromExperimentRule(config: config,
                                                                      flagKey: featureFlag.key,
                                                                      rule: experiment,
                                                                      user: user,
                                                                      userProfileTracker: userProfileTracker,
                                                                      isAsync: isAsync,
                                                                      options: options)
                reasons.merge(decisionResponse.reasons)
                if let result = decisionResponse.result {
                    if result.cmabError || result.variation != nil {
                        let featureDecision = FeatureDecision(experiment: experiment, variation: result.variation, source: Constants.DecisionSource.featureTest.rawValue, cmabUUID: result.cmabUUID)
                        return DecisionResponse(result: featureDecision, reasons: reasons)
                    }
                }
            }
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
    /// Determines the feature decision for a feature flag's rollout rules.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - featureFlag: The feature flag to evaluate.
    ///   - user: The user context.
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the feature decision (if any) and reasons.
    func getVariationForFeatureRollout(config: ProjectConfig,
                                       featureFlag: FeatureFlag,
                                       user: OptimizelyUserContext,
                                       options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        let reasons = DecisionReasons(options: options)
        
        let rolloutId = featureFlag.rolloutId.trimmingCharacters(in: CharacterSet.whitespaces)
        
        guard !rolloutId.isEmpty else {
            let info = LogMessage.noRolloutExists(featureFlag.key)
            logger.d(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        guard let rollout = config.getRollout(id: rolloutId) else {
            let info = OptimizelyError.rolloutIdInvalid(rolloutId, featureFlag.key)
            logger.d(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        let rolloutRules = rollout.experiments
        if rolloutRules.isEmpty {
            let info = LogMessage.rolloutHasNoExperiments(rolloutId)
            logger.e(info)
            reasons.addInfo(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        var index = 0
        while index < rolloutRules.count {
            let decisionResponse = getVariationFromDeliveryRule(config: config,
                                                                flagKey: featureFlag.key,
                                                                rules: rolloutRules,
                                                                ruleIndex: index,
                                                                user: user,
                                                                options: options)
            reasons.merge(decisionResponse.reasons)
            let (variation, skipToEveryoneElse) = decisionResponse.result!
            
            if let variation = variation {
                let rule = rolloutRules[index]
                let featureDecision = FeatureDecision(experiment: rule, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
                return DecisionResponse(result: featureDecision, reasons: reasons)
            }
            
            // the last rule is special for "Everyone Else"
            index = skipToEveryoneElse ? (rolloutRules.count - 1) : (index + 1)
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
    
    // MARK: - Holdout and Rule Decisions
    
    /// Determines the variation for a holdout group.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - flagKey: The feature flag key.
    ///   - holdout: The holdout group to evaluate.
    ///   - user: The user context.
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the variation (if any) and reasons.
    func getVariationForHoldout(config: ProjectConfig,
                                flagKey: String,
                                holdout: Holdout,
                                user: OptimizelyUserContext,
                                options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons(options: options)
        
        guard holdout.isActivated else {
            let info = LogMessage.holdoutNotRunning(holdout.key)
            reasons.addInfo(info)
            logger.i(info)
            return DecisionResponse(result: nil, reasons: reasons)
        }
        
        // ---- check if the user passes audience targeting before bucketing ----
        let audienceResponse = doesMeetAudienceConditions(config: config,
                                                          experiment: holdout,
                                                          user: user)
        
        reasons.merge(audienceResponse.reasons)
        
        let userId = user.userId
        let attributes = user.attributes
        
        // Acquire bucketingId .
        let bucketingId = getBucketingId(userId: userId, attributes: attributes)
        var bucketedVariation: Variation?
        
        if audienceResponse.result ?? false {
            let info = LogMessage.userMeetsConditionsForHoldout(userId, holdout.key)
            reasons.addInfo(info)
            logger.i(info)
            
            // bucket user into holdout variation
            let decisionResponse = (bucketer as? DefaultBucketer)?.bucketToVariation(experiment: holdout, bucketingId: bucketingId)
            if let reason = decisionResponse?.reasons {
                reasons.merge(reason)
            }
            
            bucketedVariation = decisionResponse?.result
            
            if let variation = bucketedVariation {
                let info = LogMessage.userBucketedIntoVariationInHoldout(userId, holdout.key, variation.key)
                reasons.addInfo(info)
                logger.i(info)
            } else {
                let info = LogMessage.userNotBucketedIntoHoldoutVariation(userId)
                reasons.addInfo(info)
                logger.i(info)
            }
            
        } else {
            let info = LogMessage.userDoesntMeetConditionsForHoldout(userId, holdout.key)
            reasons.addInfo(info)
            logger.i(info)
        }
        
        return DecisionResponse(result: bucketedVariation, reasons: reasons)
    }
    
    /// Determines the variation for an experiment rule within a feature flag.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - flagKey: The feature flag key.
    ///   - rule: The experiment rule to evaluate.
    ///   - user: The user context.
    ///   - userProfileTracker: Optional tracker for user profile data.
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the variation (if any) and reasons.
    func getVariationFromExperimentRule(config: ProjectConfig,
                                        flagKey: String,
                                        rule: Experiment,
                                        user: OptimizelyUserContext,
                                        userProfileTracker: UserProfileTracker?,
                                        isAsync: Bool,
                                        options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<VariationDecision> {
        let reasons = DecisionReasons(options: options)
        // check forced-decision first
        let forcedDecisionResponse = findValidatedForcedDecision(config: config,
                                                                 user: user,
                                                                 context: OptimizelyDecisionContext(flagKey: flagKey, ruleKey: rule.key))
        reasons.merge(forcedDecisionResponse.reasons)
        
        if let variation = forcedDecisionResponse.result {
            let variationDecision = VariationDecision(variation: variation)
            return DecisionResponse(result: variationDecision, reasons: reasons)
        }
        
        let decisionResponse = getVariation(config: config,
                                            experiment: rule,
                                            user: user,
                                            options: options,
                                            isAsync: isAsync,
                                            userProfileTracker: userProfileTracker)
        let variationResult = decisionResponse.result
        reasons.merge(decisionResponse.reasons)
        return DecisionResponse(result: variationResult, reasons: reasons)
    }
    
    /// Determines the variation for a delivery rule in a rollout.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - flagKey: The feature flag key.
    ///   - rules: The list of rollout rules.
    ///   - ruleIndex: The index of the rule to evaluate.
    ///   - user: The user context.
    ///   - options: Optional decision options.
    /// - Returns: A `DecisionResponse` with the variation (if any), a flag indicating whether to skip to the "Everyone Else" rule, and reasons.
    func getVariationFromDeliveryRule(config: ProjectConfig,
                                      flagKey: String,
                                      rules: [Experiment],
                                      ruleIndex: Int,
                                      user: OptimizelyUserContext,
                                      options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<(Variation?, Bool)> {
        let reasons = DecisionReasons(options: options)
        var skipToEveryoneElse = false
        
        // check forced-decision first
        
        let rule = rules[ruleIndex]
        let forcedDecisionResponse = findValidatedForcedDecision(config: config,
                                                                 user: user,
                                                                 context: OptimizelyDecisionContext(flagKey: flagKey, ruleKey: rule.key))
        reasons.merge(forcedDecisionResponse.reasons)
        
        if let variation = forcedDecisionResponse.result {
            return DecisionResponse(result: (variation, skipToEveryoneElse), reasons: reasons)
        }
        
        // regular decision
        
        let userId = user.userId
        let attributes = user.attributes
        let bucketingId = getBucketingId(userId: userId, attributes: attributes)
        
        let everyoneElse = (ruleIndex == rules.count - 1)
        let loggingKey = everyoneElse ? "Everyone Else" : String(ruleIndex + 1)
        
        var bucketedVariation: Variation?
        
        let audienceDecisionResponse = doesMeetAudienceConditions(config: config,
                                                                  experiment: rule,
                                                                  user: user,
                                                                  logType: .rolloutRule,
                                                                  loggingKey: loggingKey)
        reasons.merge(audienceDecisionResponse.reasons)
        if audienceDecisionResponse.result ?? false {
            var info = LogMessage.userMeetsConditionsForTargetingRule(userId, loggingKey)
            logger.d(info)
            reasons.addInfo(info)
            
            let decisionResponse = bucketer.bucketExperiment(config: config,
                                                             experiment: rule,
                                                             bucketingId: bucketingId)
            reasons.merge(decisionResponse.reasons)
            bucketedVariation = decisionResponse.result
            
            if bucketedVariation != nil {
                info = LogMessage.userBucketedIntoTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons.addInfo(info)
            } else if !everyoneElse {
                // skip this logging for EveryoneElse since this has a message not for EveryoneElse
                info = LogMessage.userNotBucketedIntoTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons.addInfo(info)
                
                // skip the rest of rollout rules to the everyone-else rule if audience matches but not bucketed.
                skipToEveryoneElse = true
            }
        } else {
            let info = LogMessage.userDoesntMeetConditionsForTargetingRule(userId, loggingKey)
            logger.d(info)
            reasons.addInfo(info)
        }
        
        return DecisionResponse(result: (bucketedVariation, skipToEveryoneElse), reasons: reasons)
    }
    
    // MARK: - Audience Evaluation
    
    /// Evaluates whether a user meets the audience conditions for an experiment or rule.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - experiment: The experiment or rule to evaluate.
    ///   - user: The user context.
    ///   - logType: The type of evaluation for logging (e.g., experiment or rollout rule).
    ///   - loggingKey: Optional key for logging.
    /// - Returns: A `DecisionResponse` with a boolean indicating whether conditions are met and reasons.
    func doesMeetAudienceConditions(config: ProjectConfig,
                                    experiment: ExperimentCore,
                                    user: OptimizelyUserContext,
                                    logType: Constants.EvaluationLogType = .experiment,
                                    loggingKey: String? = nil) -> DecisionResponse<Bool> {
        let reasons = DecisionReasons()
        
        var result = true   // success as default (no condition, etc)
        let evType = logType.rawValue
        let finalLoggingKey = loggingKey ?? experiment.key
        
        do {
            if let conditions = experiment.audienceConditions {
                logger.d { () -> String in
                    return LogMessage.evaluatingAudiencesCombined(evType, finalLoggingKey, Utils.getConditionString(conditions: conditions)).description
                }
                switch conditions {
                    case .array(let arrConditions):
                        if arrConditions.count > 0 {
                            result = try conditions.evaluate(project: config.project, user: user)
                        } else {
                            // empty conditions (backward compatibility with "audienceIds" is ignored if exists even though empty
                            result = true
                        }
                    case .leaf:
                        result = try conditions.evaluate(project: config.project, user: user)
                    default:
                        result = true
                }
            }
            // backward compatibility with audienceIds list
            else if experiment.audienceIds.count > 0 {
                var holder = [ConditionHolder]()
                holder.append(.logicalOp(.or))
                for id in experiment.audienceIds {
                    holder.append(.leaf(.audienceId(id)))
                }
                logger.d { () -> String in
                    return LogMessage.evaluatingAudiencesCombined(evType, finalLoggingKey, Utils.getConditionString(conditions: holder)).description
                }
                result = try holder.evaluate(project: config.project, user: user)
            }
        } catch {
            if let error = error as? OptimizelyError {
                logger.i(error)
                reasons.addInfo(error)
            }
            result = false
        }
        
        logger.i(.audienceEvaluationResultCombined(evType, finalLoggingKey, result.description))
        
        return DecisionResponse(result: result, reasons: reasons)
    }
    
    // MARK: - Utilities
    
    /// Retrieves the bucketing ID for a user, defaulting to user ID unless overridden in attributes.
    /// - Parameters:
    ///   - userId: The user's ID.
    ///   - attributes: The user's attributes.
    /// - Returns: The bucketing ID to use for variation assignment.
    func getBucketingId(userId: String, attributes: OptimizelyAttributes) -> String {
        // By default, the bucketing ID should be the user ID .
        var bucketingId = userId
        // If the bucketing ID key is defined in attributes, then use that
        // in place of the userID for the murmur hash key
        if let newBucketingId = attributes[Constants.Attributes.reservedBucketIdAttribute] as? String {
            bucketingId = newBucketingId
        }
        
        return bucketingId
    }
    
    /// Finds and validates a forced decision for a given context.
    /// - Parameters:
    ///   - config: The project configuration.
    ///   - user: The user context.
    ///   - context: The decision context (flag and rule keys).
    /// - Returns: A `DecisionResponse` with the forced variation (if valid) and reasons.
    func findValidatedForcedDecision(config: ProjectConfig,
                                     user: OptimizelyUserContext,
                                     context: OptimizelyDecisionContext) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons()
        
        if let variationKey = user.getForcedDecision(context: context)?.variationKey {
            let userId = user.userId
            
            if let variation = config.getFlagVariationByKey(flagKey: context.flagKey, variationKey: variationKey) {
                let info = LogMessage.userHasForcedDecision(userId, context.flagKey, context.ruleKey, variationKey)
                logger.i(info)
                reasons.addInfo(info)
                return DecisionResponse(result: variation, reasons: reasons)
            } else {
                let info = LogMessage.userHasForcedDecisionButInvalid(userId, context.flagKey, context.ruleKey)
                logger.i(info)
                reasons.addInfo(info)
            }
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
}

// MARK: - UserProfileService Helpers

extension DefaultDecisionService {
    func getVariationIdFromProfile(userId: String,
                                   experimentId: String) -> String? {
        if let profile = userProfileService.lookup(userId: userId),
           let bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap,
           let experimentMap = bucketMap[experimentId],
           let variationId = experimentMap[UserProfileKeys.kVariationId] {
            return variationId
        } else {
            return nil
        }
    }
    
    func getVariationIdFromProfile(profile: UserProfile?,
                                   experimentId: String) -> String? {
        if let _profile = profile,
           let bucketMap = _profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap,
           let experimentMap = bucketMap[experimentId],
           let variationId = experimentMap[UserProfileKeys.kVariationId] {
            return variationId
        } else {
            return nil
        }
    }
    
    func saveProfile(userId: String,
                     experimentId: String,
                     variationId: String) {
        DefaultDecisionService.upsRMWLock.sync {
            var profile = self.userProfileService.lookup(userId: userId) ?? OPTUserProfileService.UPProfile()
            
            var bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
            bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
            
            profile[UserProfileKeys.kBucketMap] = bucketMap
            profile[UserProfileKeys.kUserId] = userId
            
            self.userProfileService.save(userProfile: profile)
            
            self.logger.i(.savedVariationInUserProfile(variationId, experimentId, userId))
        }
    }
}
