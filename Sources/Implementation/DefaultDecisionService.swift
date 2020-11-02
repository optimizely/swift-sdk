/****************************************************************************
 * Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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

class DefaultDecisionService: OPTDecisionService {
    
    let bucketer: OPTBucketer
    let userProfileService: OPTUserProfileService
    lazy var logger = OPTLoggerFactory.getLogger()
    
    init(userProfileService: OPTUserProfileService) {
        self.bucketer = DefaultBucketer()
        self.userProfileService = userProfileService
    }
    
    func getVariation(config: ProjectConfig,
                      experiment: Experiment,
                      userId: String,
                      attributes: OptimizelyAttributes,
                      options: [OptimizelyDecideOption]? = nil,
                      reasons: DecisionReasons? = nil) -> Variation? {
        let experimentId = experiment.id
        
        // Acquire bucketingId .
        let bucketingId = getBucketingId(userId: userId, attributes: attributes)
        
        // ---- check if the experiment is running ----
        if !experiment.isActivated {
            let info = LogMessage.experimentNotRunning(experiment.key)
            logger.i(info)
            reasons?.addInfo(info)
            return nil
        }
        
        // ---- check if the user is forced into a variation ----
        if let variationId = config.getForcedVariation(experimentKey: experiment.key, userId: userId)?.id,
           let variation = experiment.getVariation(id: variationId) {
            return variation
        }
        
        // ---- check to see if user is white-listed for a certain variation ----
        if let variationKey = experiment.forcedVariations[userId] {
            if let variation = experiment.getVariation(key: variationKey) {
                let info = LogMessage.forcedVariationFound(variationKey, userId)
                logger.i(info)
                reasons?.addInfo(info)
                return variation
            }
            
            // mapped to invalid variation - ignore and continue for other deciesions
            let info = LogMessage.forcedVariationFoundButInvalid(variationKey, userId)
            logger.e(info)
            reasons?.addInfo(info)
        }
        
        // ---- check if a valid variation is stored in the user profile ----
        let ignoreUPS = (options ?? []).contains(.ignoreUserProfileService)

        if !ignoreUPS,
           let variationId = self.getVariationIdFromProfile(userId: userId, experimentId: experimentId),
           let variation = experiment.getVariation(id: variationId) {
            
            let info = LogMessage.gotVariationFromUserProfile(variation.key, experiment.key, userId)
            logger.i(info)
            reasons?.addInfo(info)
            return variation
        }
        
        var bucketedVariation: Variation?
        // ---- check if the user passes audience targeting before bucketing ----
        if doesMeetAudienceConditions(config: config,
                                      experiment: experiment,
                                      userId: userId,
                                      attributes: attributes,
                                      reasons: reasons) {
            // bucket user into a variation
            bucketedVariation = bucketer.bucketExperiment(config: config,
                                                          experiment: experiment,
                                                          bucketingId: bucketingId,
                                                          reasons: reasons)
            
            if let bucketedVariation = bucketedVariation {
                let info = LogMessage.userBucketedIntoVariationInExperiment(userId, experiment.key,
                                                                            bucketedVariation.key)
                logger.i(info)
                reasons?.addInfo(info)
                // save to user profile
                if !ignoreUPS {
                    self.saveProfile(userId: userId, experimentId: experimentId, variationId: bucketedVariation.id)
                }
            } else {
                let info = LogMessage.userNotBucketedIntoVariation(userId)
                logger.i(info)
                reasons?.addInfo(info)
            }
            
        } else {
            let info = LogMessage.userNotInExperiment(userId, experiment.key)
            logger.i(info)
            reasons?.addInfo(info)
        }
        
        return bucketedVariation
    }
    
    func doesMeetAudienceConditions(config: ProjectConfig,
                                    experiment: Experiment,
                                    userId: String,
                                    attributes: OptimizelyAttributes,
                                    logType: Constants.EvaluationLogType = .experiment,
                                    loggingKey: String? = nil,
                                    reasons: DecisionReasons? = nil) -> Bool {
        
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
                reasons?.addInfo(error)
            }
            result = false
        }
        
        logger.i(.audienceEvaluationResultCombined(evType, finalLoggingKey, result.description))
        
        return result
    }
    
    func getVariationForFeature(config: ProjectConfig,
                                featureFlag: FeatureFlag,
                                userId: String,
                                attributes: OptimizelyAttributes,
                                options: [OptimizelyDecideOption]? = nil,
                                reasons: DecisionReasons? = nil) -> (experiment: Experiment, variation: Variation, source: String)? {
        //Evaluate in this order:
        
        //1. Attempt to bucket user into experiment using feature flag.
        // Check if the feature flag is under an experiment and the the user is bucketed into one of these experiments
        if let pair = getVariationForFeatureExperiment(config: config,
                                                       featureFlag: featureFlag,
                                                       userId: userId,
                                                       attributes: attributes,
                                                       options: options,
                                                       reasons: reasons) {
            return pair
        }
        
        //2. Attempt to bucket user into rollout using the feature flag.
        // Check if the feature flag has rollout and the user is bucketed into one of it's rules
        if let pair = getVariationForFeatureRollout(config: config,
                                                         featureFlag: featureFlag,
                                                         userId: userId,
                                                         attributes: attributes,
                                                         reasons: reasons) {
            return pair
        }
        
        return nil
        
    }
    
    func getVariationForFeatureExperiment(config: ProjectConfig,
                                          featureFlag: FeatureFlag,
                                          userId: String,
                                          attributes: OptimizelyAttributes,
                                          options: [OptimizelyDecideOption]? = nil,
                                          reasons: DecisionReasons? = nil) -> (experiment: Experiment, variation: Variation, source: String)? {
        
        let experimentIds = featureFlag.experimentIds
        if experimentIds.isEmpty {
            let info = LogMessage.featureHasNoExperiments(featureFlag.key)
            logger.d(info)
            reasons?.addInfo(info)
        }
        
        // Check if there are any experiment IDs inside feature flag
        // Evaluate each experiment ID and return the first bucketed experiment variation
        for experimentId in experimentIds {
            if let experiment = config.getExperiment(id: experimentId),
                let variation = getVariation(config: config,
                                             experiment: experiment,
                                             userId: userId,
                                             attributes: attributes,
                                             options: options,
                                             reasons: reasons) {
                return (experiment, variation, Constants.DecisionSource.featureTest.rawValue)
            }
        }
        return nil
    }
    
    func getVariationForFeatureRollout(config: ProjectConfig,
                                       featureFlag: FeatureFlag,
                                       userId: String,
                                       attributes: OptimizelyAttributes,
                                       reasons: DecisionReasons? = nil) -> (experiment: Experiment, variation: Variation, source: String)? {
        
        let bucketingId = getBucketingId(userId: userId, attributes: attributes)
        
        let rolloutId = featureFlag.rolloutId.trimmingCharacters(in: CharacterSet.whitespaces)
        
        guard !rolloutId.isEmpty else {
            let info = LogMessage.noRolloutExists(featureFlag.key)
            logger.d(info)
            reasons?.addInfo(info)
            return nil
        }
        
        guard let rollout = config.getRollout(id: rolloutId) else {
            let info = OptimizelyError.rolloutIdInvalid(rolloutId, featureFlag.key)
            logger.d(info)
            reasons?.addInfo(info)
            return nil
        }
        
        let rolloutRules = rollout.experiments
        if rolloutRules.isEmpty {
            let info = LogMessage.rolloutHasNoExperiments(rolloutId)
            logger.e(info)
            reasons?.addInfo(info)
            return nil
        }
        
        // Evaluate all rollout rules except for last one
        for index in 0..<rolloutRules.count.advanced(by: -1) {
            let loggingKey = index + 1
            let experiment = rolloutRules[index]
            if doesMeetAudienceConditions(config: config,
                                          experiment: experiment,
                                          userId: userId,
                                          attributes: attributes,
                                          logType: .rolloutRule,
                                          loggingKey: String(loggingKey),
                                          reasons: reasons) {
                var info = LogMessage.userMeetsConditionsForTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons?.addInfo(info)
                if let variation = bucketer.bucketExperiment(config: config,
                                                             experiment: experiment,
                                                             bucketingId: bucketingId,
                                                             reasons: reasons) {
                    info = LogMessage.userBucketedIntoTargetingRule(userId, loggingKey)
                    logger.d(info)
                    reasons?.addInfo(info)
                    return (experiment, variation, Constants.DecisionSource.rollout.rawValue)
                }
                info = LogMessage.userNotBucketedIntoTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons?.addInfo(info)
                break
            } else {
                let info = LogMessage.userDoesntMeetConditionsForTargetingRule(userId, loggingKey)
                logger.d(info)
                reasons?.addInfo(info)
            }
        }
        // Evaluate fall back rule / last rule now
        let experiment = rolloutRules[rolloutRules.count - 1]
        
        if doesMeetAudienceConditions(config: config,
                                      experiment: experiment,
                                      userId: userId,
                                      attributes: attributes,
                                      logType: .rolloutRule,
                                      loggingKey: "Everyone Else",
                                      reasons: reasons) {
            if let variation = bucketer.bucketExperiment(config: config,
                                                         experiment: experiment,
                                                         bucketingId: bucketingId,
                                                         reasons: reasons) {
                let info = LogMessage.userBucketedIntoEveryoneTargetingRule(userId)
                logger.d(info)
                reasons?.addInfo(info)
                
                return (experiment, variation, Constants.DecisionSource.rollout.rawValue)
            }
        }
        
        return nil
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
                                   experimentId: String,
                                   reasons: DecisionReasons? = nil) -> String? {
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
                     variationId: String,
                     reasons: DecisionReasons? = nil) {
        var profile = userProfileService.lookup(userId: userId) ?? OPTUserProfileService.UPProfile()
        
        var bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
        bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
        
        profile[UserProfileKeys.kBucketMap] = bucketMap
        profile[UserProfileKeys.kUserId] = userId
        
        userProfileService.save(userProfile: profile)
        
        logger.i(.savedVariationInUserProfile(variationId, experimentId, userId))
    }
    
}
