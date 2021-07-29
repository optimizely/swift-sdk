//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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
    let experiment: Experiment
    let variation: Variation
    let source: String
}

class DefaultDecisionService: OPTDecisionService {
    
    let bucketer: OPTBucketer
    let userProfileService: OPTUserProfileService
    let logger = OPTLoggerFactory.getLogger()
    
    // user-profile-service read-modify-write lock for supporting multiple clients
    static let upsRMWLock = DispatchQueue(label: "ups-rmw")

    init(userProfileService: OPTUserProfileService) {
        self.bucketer = DefaultBucketer()
        self.userProfileService = userProfileService
    }
    
    func getVariation(config: ProjectConfig,
                      experiment: Experiment,
                      userId: String,
                      attributes: OptimizelyAttributes,
                      options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<Variation> {
        let reasons = DecisionReasons(options: options)
        
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
        
        if !ignoreUPS,
           let variationId = getVariationIdFromProfile(userId: userId, experimentId: experimentId),
           let variation = experiment.getVariation(id: variationId) {
            
            let info = LogMessage.gotVariationFromUserProfile(variation.key, experiment.key, userId)
            logger.i(info)
            reasons.addInfo(info)
            return DecisionResponse(result: variation, reasons: reasons)
        }
        
        var bucketedVariation: Variation?
        // ---- check if the user passes audience targeting before bucketing ----
        let audienceResponse = doesMeetAudienceConditions(config: config,
                                                          experiment: experiment,
                                                          userId: userId,
                                                          attributes: attributes)
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
                    self.saveProfile(userId: userId, experimentId: experimentId, variationId: variation.id)
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
                                    userId: String,
                                    attributes: OptimizelyAttributes,
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
                        result = try conditions.evaluate(project: config.project, attributes: attributes)
                    } else {
                        // empty conditions (backward compatibility with "audienceIds" is ignored if exists even though empty
                        result = true
                    }
                case .leaf:
                    result = try conditions.evaluate(project: config.project, attributes: attributes)
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
                result = try holder.evaluate(project: config.project, attributes: attributes)
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
                                userId: String,
                                attributes: OptimizelyAttributes,
                                options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        let reasons = DecisionReasons(options: options)
        
        // Evaluate in this order:
        
        // 1. Attempt to bucket user into experiment using feature flag.
        // Check if the feature flag is under an experiment and the the user is bucketed into one of these experiments
        var decisionResponse = getVariationForFeatureExperiment(config: config,
                                                                featureFlag: featureFlag,
                                                                userId: userId,
                                                                attributes: attributes,
                                                                options: options)
        reasons.merge(decisionResponse.reasons)
        if let decision = decisionResponse.result {
            return DecisionResponse(result: decision, reasons: reasons)
        }
        
        // 2. Attempt to bucket user into rollout using the feature flag.
        // Check if the feature flag has rollout and the user is bucketed into one of it's rules
        decisionResponse = getVariationForFeatureRollout(config: config,
                                                         featureFlag: featureFlag,
                                                         userId: userId,
                                                         attributes: attributes,
                                                         options: options)
        reasons.merge(decisionResponse.reasons)
        if let decision = decisionResponse.result {
            return DecisionResponse(result: decision, reasons: reasons)
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
        
    }
    
    func getVariationForFeatureExperiment(config: ProjectConfig,
                                          featureFlag: FeatureFlag,
                                          userId: String,
                                          attributes: OptimizelyAttributes,
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
                let decisionResponse = getVariation(config: config,
                                                    experiment: experiment,
                                                    userId: userId,
                                                    attributes: attributes,
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
                                       userId: String,
                                       attributes: OptimizelyAttributes,
                                       options: [OptimizelyDecideOption]? = nil) -> DecisionResponse<FeatureDecision> {
        let reasons = DecisionReasons(options: options)
        
        let bucketingId = getBucketingId(userId: userId, attributes: attributes)
        
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
        
        // Evaluate all rollout rules except for last one
        for index in 0..<rolloutRules.count.advanced(by: -1) {
            let loggingKey = index + 1
            let experiment = rolloutRules[index]
            let decisionResponse = doesMeetAudienceConditions(config: config,
                                                              experiment: experiment,
                                                              userId: userId,
                                                              attributes: attributes,
                                                              logType: .rolloutRule,
                                                              loggingKey: String(loggingKey))
            reasons.merge(decisionResponse.reasons)
            if decisionResponse.result ?? false {
                var info = LogMessage.userMeetsConditionsForTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons.addInfo(info)
                
                let decisionResponse = bucketer.bucketExperiment(config: config,
                                                                 experiment: experiment,
                                                                 bucketingId: bucketingId)
                reasons.merge(decisionResponse.reasons)
                if let variation = decisionResponse.result {
                    info = LogMessage.userBucketedIntoTargetingRule(userId, loggingKey)
                    logger.d(info)
                    reasons.addInfo(info)
                    
                    let featureDecision = FeatureDecision(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
                    return DecisionResponse(result: featureDecision, reasons: reasons)
                }
                info = LogMessage.userNotBucketedIntoTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons.addInfo(info)
                break
            } else {
                let info = LogMessage.userDoesntMeetConditionsForTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons.addInfo(info)
            }
        }
        
        // Evaluate fall back rule / last rule now
        let experiment = rolloutRules[rolloutRules.count - 1]
        
        let decisionResponse = doesMeetAudienceConditions(config: config,
                                                          experiment: experiment,
                                                          userId: userId,
                                                          attributes: attributes,
                                                          logType: .rolloutRule,
                                                          loggingKey: "Everyone Else")
        reasons.merge(decisionResponse.reasons)
        if decisionResponse.result ?? false {
            let decisionResponse = bucketer.bucketExperiment(config: config,
                                                             experiment: experiment,
                                                             bucketingId: bucketingId)
            reasons.merge(decisionResponse.reasons)
            if let variation = decisionResponse.result {
                let info = LogMessage.userBucketedIntoEveryoneTargetingRule(userId)
                logger.d(info)
                reasons.addInfo(info)
                
                let featureDecision = FeatureDecision(experiment: experiment, variation: variation, source: Constants.DecisionSource.rollout.rawValue)
                return DecisionResponse(result: featureDecision, reasons: reasons)
            }
        }
        
        return DecisionResponse(result: nil, reasons: reasons)
    }
    
    func getBucketingId(userId: String, attributes: OptimizelyAttributes) -> String {
        
        // By default, the bucketing ID should be the user ID .
        var bucketingId = userId
        // If the bucketing ID key is defined in attributes, then use that
        // in place of the userID for the murmur hash key
        if let newBucketingId = attributes[Constants.Attributes.OptimizelyBucketIdAttribute] as? String {
            bucketingId = newBucketingId
        }
        
        return bucketingId
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
