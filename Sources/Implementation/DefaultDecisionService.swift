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
    var experiment: Experiment?
    let variation: Variation
    let source: String
}

class DefaultDecisionService: OPTDecisionService {
    typealias UserProfile = OPTUserProfileService.UPProfile
    
    private var _decisionBatchInProgress: Bool = false
    
    var decisionBatchInProgress: Bool {
        get {
            return _decisionBatchInProgress
        }
        set {
            // Only save if the value is changing from true to false
            if _decisionBatchInProgress && !newValue {
                saveProfile()
            }
            _decisionBatchInProgress = newValue
        }
    }

    let bucketer: OPTBucketer
    let userProfileService: OPTUserProfileService
    private var userProfile: UserProfile?
    
    // thread-safe lazy logger load (after HandlerRegisterService ready)
    private let threadSafeLogger = ThreadSafeLogger()
    var logger: OPTLogger {
        return threadSafeLogger.logger
    }
    
    // user-profile-service read-modify-write lock for supporting multiple clients
    static let upsRMWLock = DispatchQueue(label: "ups-rmw")
    
    init(userProfileService: OPTUserProfileService) {
        self.bucketer = DefaultBucketer()
        self.userProfileService = userProfileService
    }
    
    func getVariation(config: ProjectConfig,
                      experiment: Experiment,
                      user: OptimizelyUserContext,
                      options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons(options: options)
        
        let userId = user.userId
        let attributes = user.attributes
        let experimentId = experiment.id
        
        // Acquire bucketingId .
        let bucketingId = getBucketingId(userId: userId, attributes: attributes)
        
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
            return DecisionResponse(result: variation, reasons: reasons)
        }
        
        // ---- check to see if user is white-listed for a certain variation ----
        if let variationKey = experiment.forcedVariations[userId] {
            if let variation = experiment.getVariation(key: variationKey) {
                let info = LogMessage.forcedVariationFound(variationKey, userId)
                logger.i(info)
                reasons.addInfo(info)
                return DecisionResponse(result: variation, reasons: reasons)
            }
            
            // mapped to invalid variation - ignore and continue for other deciesions
            let info = LogMessage.forcedVariationFoundButInvalid(variationKey, userId)
            logger.e(info)
            reasons.addInfo(info)
        }
        
        // ---- check if a valid variation is stored in the user profile ----
        let ignoreUPS = (options ?? []).contains(.ignoreUserProfileService)
        
        if !ignoreUPS {
            if userProfile == nil {
                userProfile = userProfileService.lookup(userId: userId)
            }
            
            if let profile = userProfile {
               if let variationId = getVariationIdFromProfile(userId: userId, profile: profile, experimentId: experimentId),
                  let variation = experiment.getVariation(id: variationId) {
                   let info = LogMessage.gotVariationFromUserProfile(variation.key, experiment.key, userId)
                   logger.i(info)
                   reasons.addInfo(info)
                   return DecisionResponse(result: variation, reasons: reasons)
               }
            } else {
                let info = LogMessage.unableToGetUserProfile(experiment.key, userId)
                logger.i(info)
            }
            
        }
             
        var bucketedVariation: Variation?
        // ---- check if the user passes audience targeting before bucketing ----
        let audienceResponse = doesMeetAudienceConditions(config: config,
                                                          experiment: experiment,
                                                          user: user)
        reasons.merge(audienceResponse.reasons)
        if audienceResponse.result ?? false {
            // bucket user into a variation
            let decisionResponse = bucketer.bucketExperiment(config: config,
                                                             experiment: experiment,
                                                             bucketingId: bucketingId)
            reasons.merge(decisionResponse.reasons)
            bucketedVariation = decisionResponse.result
            
            if let variation = bucketedVariation {
                let info = LogMessage.userBucketedIntoVariationInExperiment(userId, experiment.key, variation.key)
                logger.i(info)
                reasons.addInfo(info)
                // save to user profile
                if !ignoreUPS {
                    let buckerUserProfile = userProfile ?? UserProfile()
                    updateVariation(userId: userId, profile: buckerUserProfile, experimentId: experimentId, variationId: variation.key)
                }
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
        
        return DecisionResponse(result: bucketedVariation, reasons: reasons)
    }
    
    func doesMeetAudienceConditions(config: ProjectConfig,
                                    experiment: Experiment,
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
    
    func getVariationForFeature(config: ProjectConfig,
                                featureFlag: FeatureFlag,
                                user: OptimizelyUserContext,
                                options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        let reasons = DecisionReasons(options: options)
        
        // Evaluate in this order:
        
        // 1. Attempt to bucket user into experiment using feature flag.
        // Check if the feature flag is under an experiment and the the user is bucketed into one of these experiments
        var decisionResponse = getVariationForFeatureExperiment(config: config,
                                                                featureFlag: featureFlag,
                                                                user: user,
                                                                options: options)
        reasons.merge(decisionResponse.reasons)
        if let decision = decisionResponse.result {
            return DecisionResponse(result: decision, reasons: reasons)
        }
        
        // 2. Attempt to bucket user into rollout using the feature flag.
        // Check if the feature flag has rollout and the user is bucketed into one of it's rules
        decisionResponse = getVariationForFeatureRollout(config: config,
                                                         featureFlag: featureFlag,
                                                         user: user,
                                                         options: options)
        reasons.merge(decisionResponse.reasons)
        if let decision = decisionResponse.result {
            return DecisionResponse(result: decision, reasons: reasons)
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
    func getVariationForFeatureExperiment(config: ProjectConfig,
                                          featureFlag: FeatureFlag,
                                          user: OptimizelyUserContext,
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
                                                                      options: options)
                reasons.merge(decisionResponse.reasons)
                if let variation = decisionResponse.result {
                    let featureDecision = FeatureDecision(experiment: experiment, variation: variation, source: Constants.DecisionSource.featureTest.rawValue)
                    return DecisionResponse(result: featureDecision, reasons: reasons)
                }
            }
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
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
    
    func getVariationFromExperimentRule(config: ProjectConfig,
                                        flagKey: String,
                                        rule: Experiment,
                                        user: OptimizelyUserContext,
                                        options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons(options: options)
        
        // check forced-decision first
        
        let forcedDecisionResponse = findValidatedForcedDecision(config: config,
                                                                 user: user,
                                                                 context: OptimizelyDecisionContext(flagKey: flagKey, ruleKey: rule.key))
        reasons.merge(forcedDecisionResponse.reasons)
        
        if let variation = forcedDecisionResponse.result {
            return DecisionResponse(result: variation, reasons: reasons)
        }
        
        // regular decision
        
        let decisionResponse = getVariation(config: config,
                                            experiment: rule,
                                            user: user,
                                            options: options)
        reasons.merge(decisionResponse.reasons)
        let variation = decisionResponse.result
        
        return DecisionResponse(result: variation, reasons: reasons)
    }
    
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
                                   profile: UserProfile,
                                   experimentId: String) -> String? {
        if let bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap,
           let experimentMap = bucketMap[experimentId],
           let variationId = experimentMap[UserProfileKeys.kVariationId] {
            return variationId
        } else {
            return nil
        }
    }
    
    func updateVariation(userId: String,
                         profile: UserProfile,
                         experimentId: String,
                         variationId: String) {
        DefaultDecisionService.upsRMWLock.sync {
            var _profile = profile
            var bucketMap = _profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
            bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
            
            _profile[UserProfileKeys.kBucketMap] = bucketMap
            _profile[UserProfileKeys.kUserId] = userId
            
            /// Update user profile
            userProfile = _profile
            
            if !_decisionBatchInProgress {
                saveProfile(userId: userId, experimentId: experimentId, variationId: variationId)
            }
        }
    }
    
    func saveProfile(userId: String? = nil, experimentId: String? = nil, variationId: String? = nil) {
        guard let profile = userProfile else { return }
        
        self.userProfileService.save(userProfile: profile)
        
        self.logger.i(.savedVariationInUserProfile(variationId ?? "", experimentId ?? "", userId ?? ""))
    }
    
}
