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
    
    init(bucketer: OPTBucketer, userProfileService:OPTUserProfileService) {
        self.bucketer = bucketer
        self.userProfileService = userProfileService
    }

    func getVariation(config:ProjectConfig, userId:String, experiment: Experiment, attributes: OptimizelyAttributes) -> Variation? {
        let experimentId = experiment.id;
        
        // Acquire bucketingId .
        let bucketingId = getBucketingId(userId:userId, attributes:attributes)
        
        // ---- check if the experiment is running ----
        if experiment.status != Experiment.Status.running {
            return nil;
        }
        
        // ---- check for whitelisted variation registered at runtime ----
        if let variationId = config.getForcedVariation(experimentKey: experiment.key, userId: userId)?.id,
            let variation = experiment.getVariation(id: variationId) {
            return variation;
        }

        // ---- check if the experiment has forced variation ----
        if let variationKey = experiment.forcedVariations[userId],
            let variation = experiment.getVariation(key: variationKey) {
            return variation
        }
        
        // ---- check if a valid variation is stored in the user profile ----
        if let variationId = self.getVariationIdFromProfile(userId: userId, experimentId: experimentId),
            let variation = experiment.getVariation(id: variationId) {
            return variation
        }
        
        var bucketedVariation:Variation?
        // ---- check if the user passes audience targeting before bucketing ----
        if let result = isInExperiment(
            config: config,
            experiment:experiment,
            userId:userId,
            attributes:attributes), result == true {
            
            // bucket user into a variation
            bucketedVariation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId:bucketingId)
            
            if let bucketedVariation = bucketedVariation {
                // save to user profile
                self.saveProfile(userId: userId, experimentId: experimentId, variationId: bucketedVariation.id)
            }
        }
        
        return bucketedVariation;

    }
    
    func isInExperiment(config:ProjectConfig, experiment:Experiment, userId:String, attributes: OptimizelyAttributes) -> Bool? {
        
        if let conditions = experiment.audienceConditions {
            switch conditions {
            case .array(let arrConditions):
                if arrConditions.count > 0 {
                    // TODO: [Jae] fix with OptimizelyError
                    return try? conditions.evaluate(project: config.project, attributes: attributes)
                } else {
                    // empty conditions (backward compatibility with "audienceIds" is ignored if exists even though empty
                    return true
                }
            case .leaf:
                // TODO: [Jae] fix with OptimizelyError
                return try? conditions.evaluate(project: config.project, attributes: attributes)
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
            
            // TODO: [Jae] fix with OptimizelyError
            return try? holder.evaluate(project: config.project, attributes: attributes)
        }
        
        return true
    }
    
    func getExperimentInGroup(config:ProjectConfig, group:Group, bucketingId:String) -> Experiment? {
        let experiment = bucketer.bucketToExperiment(config: config, group:group, bucketingId:bucketingId)
        if let _ = experiment {
            // log
        }

        return experiment;
    }
    
    func getVariationForFeature(config:ProjectConfig, featureFlag:FeatureFlag, userId:String, attributes: OptimizelyAttributes) -> (experiment:Experiment?, variation:Variation?)? {
        //Evaluate in this order:
        
        //1. Attempt to bucket user into experiment using feature flag.
        // Check if the feature flag is under an experiment and the the user is bucketed into one of these experiments
        if let variation = getVariationForFeatureExperiment(config: config, featureFlag: featureFlag, userId:userId, attributes:attributes) {
            return variation
        }
        
        //2. Attempt to bucket user into rollout using the feature flag.
        // Check if the feature flag has rollout and the user is bucketed into one of it's rules
        if let variation = getVariationForFeatureRollout(config: config, featureFlag: featureFlag, userId:userId, attributes:attributes) {
            return (nil, variation)
        }
        
        return nil;

    }
    
    func getVariationForFeatureGroup(config:ProjectConfig,
                                     featureFlag: FeatureFlag,
                                     groupId: String,
                                     userId: String,
                                     attributes: OptimizelyAttributes) -> (experiment:Experiment?, variation:Variation?)? {
        
        let bucketing_id = getBucketingId(userId:userId, attributes:attributes)
        if let group = config.project.groups.filter({$0.id == groupId}).first {
            
            if let experiment = getExperimentInGroup(config: config, group: group, bucketingId:bucketing_id),
                featureFlag.experimentIds.contains(experiment.id),
                let variation = getVariation(config: config, userId:userId, experiment:experiment, attributes:attributes) {
                  // log
                    return (experiment,variation)
            }
        }
        else {
            // log unknown group
        }
    
        return nil
    }
    
    func getVariationForFeatureExperiment(config:ProjectConfig,
                                          featureFlag: FeatureFlag,
                                          userId: String,
                                          attributes: OptimizelyAttributes) -> (experiment:Experiment?, variation:Variation?)? {
        
        let experimentIds = featureFlag.experimentIds;
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
    
    func getVariationForFeatureRollout(config:ProjectConfig,
                                       featureFlag: FeatureFlag,
                                       userId: String,
                                       attributes: OptimizelyAttributes) -> Variation? {
    
        let bucketingId = getBucketingId(userId: userId, attributes:attributes)
        
        let rolloutId = featureFlag.rolloutId.trimmingCharacters(in: CharacterSet.whitespaces)
        
        guard rolloutId != "" else { return nil }
        
        guard let rollout = config.getRollout(id: rolloutId) else { return nil }
        
        let rolloutRules = rollout.experiments
        // Evaluate all rollout rules except for last one
        for experiment in rolloutRules[0..<rolloutRules.count.advanced(by: -1)] {
            if isInExperiment(config: config, experiment: experiment, userId: userId, attributes: attributes) ?? false {
                if let variation = bucketer.bucketExperiment(config:config, experiment: experiment, bucketingId: bucketingId) {
                    return variation
                }
            }
        }
        // Evaluate fall back rule / last rule now
        let experiment = rolloutRules[rolloutRules.count - 1];
        if isInExperiment(config: config, experiment: experiment, userId: userId, attributes: attributes) ?? false {
            return bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: bucketingId)
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

