/****************************************************************************
 * Copyright 2019, Optimizely, Inc. and contributors                        *
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

class DefaultDecisionService : OPTDecisionService {
    
    let bucketer:OPTBucketer
    let userProfileService:OPTUserProfileService
    lazy var logger = HandlerRegistryService.shared.injectLogger()

    init(userProfileService:OPTUserProfileService) {
        self.bucketer = DefaultBucketer()
        self.userProfileService = userProfileService
    }
    
    func getVariation(config:ProjectConfig, userId:String, experiment: Experiment, attributes: OptimizelyAttributes) -> Variation? {
        let experimentId = experiment.id;
        
        // Acquire bucketingId .
        let bucketingId = getBucketingId(userId:userId, attributes:attributes)
        
        // ---- check if the experiment is running ----
        if !experiment.isActivated {
            logger?.log(level: .info, message: LogMessage.experimentNotRunning(experiment.key).description)
            return nil
        }
        
        // ---- check for whitelisted variation registered at runtime ----
        if let variationId = config.getForcedVariation(experimentKey: experiment.key, userId: userId)?.id,
            let variation = experiment.getVariation(id: variationId) {
            return variation;
        }
        
        // ---- check if the experiment has forced variation ----
        if let variationKey = experiment.forcedVariations[userId] {
            if let variation = experiment.getVariation(key: variationKey) {
                logger?.log(level: .info, message: LogMessage.userForcedInVariation(variationKey, userId).description)
                return variation
            } else {
                logger?.log(level: .error, message: LogMessage.forcedBucketingFailed(variationKey, userId).description)
                return nil
            }
        }
        
        // ---- check if a valid variation is stored in the user profile ----
        if let variationId = self.getVariationIdFromProfile(userId: userId, experimentId: experimentId),
            let variation = experiment.getVariation(id: variationId) {
            return variation
        }
        
        var bucketedVariation:Variation?
        // ---- check if the user passes audience targeting before bucketing ----
        if isInExperiment(config: config, experiment:experiment, userId:userId, attributes:attributes) {
            // bucket user into a variation
            bucketedVariation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId:bucketingId)
            
            if let bucketedVariation = bucketedVariation {
                // save to user profile
                self.saveProfile(userId: userId, experimentId: experimentId, variationId: bucketedVariation.id)
            }
        }
        
        return bucketedVariation;
    }
    
    func isInExperiment(config:ProjectConfig, experiment:Experiment, userId:String, attributes: OptimizelyAttributes) -> Bool {
        
        do {
            if let conditions = experiment.audienceConditions {
                switch conditions {
                case .array(let arrConditions):
                    if arrConditions.count > 0 {
                        return try conditions.evaluate(project: config.project, attributes: attributes)
                    } else {
                        // empty conditions (backward compatibility with "audienceIds" is ignored if exists even though empty
                        return true
                    }
                case .leaf:
                    return try conditions.evaluate(project: config.project, attributes: attributes)
                default:
                    return true
                }
            }
            // backward compatibility with audiencIds list
            else if experiment.audienceIds.count > 0 {
                var holder = [ConditionHolder]()
                holder.append(.logicalOp(.or))
                for id in experiment.audienceIds {
                    holder.append(.leaf(.audienceId(id)))
                }
                
                return try holder.evaluate(project: config.project, attributes: attributes)
            }
        } catch {
            // TODO: add logger
            
            return false
        }
        
        return true
    }
    
    func getVariationForFeature(config:ProjectConfig, featureFlag:FeatureFlag, userId:String, attributes: OptimizelyAttributes) -> (experiment:Experiment?, variation:Variation?)? {
        //Evaluate in this order:
        
        //1. Attempt to bucket user into experiment using feature flag.
        // Check if the feature flag is under an experiment and the the user is bucketed into one of these experiments
        if let pair = getVariationForFeatureExperiment(config: config, featureFlag: featureFlag, userId:userId, attributes:attributes) {
            return pair
        }
        
        //2. Attempt to bucket user into rollout using the feature flag.
        // Check if the feature flag has rollout and the user is bucketed into one of it's rules
        if let variation = getVariationForFeatureRollout(config: config, featureFlag: featureFlag, userId:userId, attributes:attributes) {
            return (nil, variation)
        }
        
        return nil;
        
    }
    
    func getVariationForFeatureExperiment(config:ProjectConfig,
                                          featureFlag: FeatureFlag,
                                          userId: String,
                                          attributes: OptimizelyAttributes) -> (experiment:Experiment?, variation:Variation?)? {
        
        let experimentIds = featureFlag.experimentIds;
        if experimentIds.isEmpty {
            logger?.log(level: .debug, message: LogMessage.featureHasNoExperiments(featureFlag.key).description)
        }
        
        // Check if there are any experiment IDs inside feature flag
        // Evaluate each experiment ID and return the first bucketed experiment variation
        for experimentId in experimentIds {
            if let experiment = config.getExperiment(id: experimentId),
                let variation = getVariation(config: config, userId: userId, experiment: experiment, attributes: attributes) {
                return (experiment,variation)
            }
        }
        return nil;
    }
    
    func getVariationForFeatureRollout(config: ProjectConfig,
                                       featureFlag: FeatureFlag,
                                       userId: String,
                                       attributes: OptimizelyAttributes) -> Variation? {
        
        let bucketingId = getBucketingId(userId: userId, attributes:attributes)
        
        let rolloutId = featureFlag.rolloutId.trimmingCharacters(in: CharacterSet.whitespaces)
        
        guard rolloutId != "" else {
            logger?.log(level: .debug, message: LogMessage.noRolloutExists(featureFlag.key).description)
            return nil
        }
        
        guard let rollout = config.getRollout(id: rolloutId) else {
            logger?.log(level: .debug, message: LogMessage.invalidRolloutId(rolloutId, featureFlag.key).description)
            return nil
        }
        
        let rolloutRules = rollout.experiments
        if rolloutRules.isEmpty {
            logger?.log(level: .error, message: LogMessage.rolloutHasNoExperiments(rolloutId).description)
        }

        // Evaluate all rollout rules except for last one
        for index in 0..<rolloutRules.count.advanced(by: -1) {
            let experiment = rolloutRules[index]
            if isInExperiment(config: config, experiment: experiment, userId: userId, attributes: attributes) {
                logger?.log(level: .debug, message: LogMessage.userMeetsConditionsForTargetingRule(userId, index: index + 1).description)
                
                if let variation = bucketer.bucketExperiment(config:config, experiment: experiment, bucketingId: bucketingId) {
                    logger?.log(level: .debug, message: LogMessage.userBucketedIntoTargetingRule(userId, index + 1).description)
                    
                    return variation
                } else {
                    logger?.log(level: .debug, message: LogMessage.userNotBucketedIntoTargetingRule(userId, index + 1).description)
                }
            } else {
                logger?.log(level: .debug, message: LogMessage.userMeetsConditionsForTargetingRule(userId, index: index + 1).description)
            }
        }
        // Evaluate fall back rule / last rule now
        let experiment = rolloutRules[rolloutRules.count - 1];
        
        if isInExperiment(config: config, experiment: experiment, userId: userId, attributes: attributes) {
            if let variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: bucketingId) {
                logger?.log(level: .debug, message: LogMessage.userBucketedIntoEveryoneTargetingRule(userId).description)
            } else {
                logger?.log(level: .debug, message: LogMessage.userNotBucketedIntoEveryoneTargetingRule(userId).description)
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
        
        return bucketingId;
    }
    
}

// MARK: - UserProfileService Helpers

extension DefaultDecisionService {
    
    func getVariationIdFromProfile(userId: String, experimentId: String) -> String? {
        if let profile = userProfileService.lookup(userId: userId),
            let bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap,
            let experimentMap = bucketMap[experimentId]
        {
            return experimentMap[UserProfileKeys.kVariationId]
        } else {
            return nil
        }
    }
    
    func saveProfile(userId: String, experimentId: String, variationId: String) {
        var profile = userProfileService.lookup(userId: userId) ?? OPTUserProfileService.UPProfile()
        
        var bucketMap = profile[UserProfileKeys.kBucketMap] as? OPTUserProfileService.UPBucketMap ?? OPTUserProfileService.UPBucketMap()
        bucketMap[experimentId] = [UserProfileKeys.kVariationId: variationId]
        
        profile[UserProfileKeys.kBucketMap] = bucketMap
        profile[UserProfileKeys.kUserId] = userId
        
        userProfileService.save(userProfile: profile)
    }
    
}

