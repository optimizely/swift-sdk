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
    var config:ProjectConfig!
    var bucketer:OPTBucketer!
    var userProfileService:OPTUserProfileService!

    internal required init(config:ProjectConfig, bucketer:OPTBucketer, userProfileService:OPTUserProfileService) {
        self.config = config
        self.bucketer = bucketer
        self.userProfileService = userProfileService
    }
    
    // [Jae]: let be configured after initialized (with custom DecisionHandler set up on OPTManger initialization)
    init() {}
    
    func initialize(config:ProjectConfig, bucketer:OPTBucketer, userProfileService:OPTUserProfileService) {
        self.config = config
        self.bucketer = bucketer
        self.userProfileService = userProfileService
    }
    
    
    
    static func createInstance(config: ProjectConfig, bucketer: OPTBucketer, userProfileService:OPTUserProfileService) -> OPTDecisionService? {
        return DefaultDecisionService(config: config, bucketer: bucketer, userProfileService: userProfileService)
    }
    
    func getVariation(userId:String, experiment: Experiment, attributes: Dictionary<String, Any>) -> Variation? {
        let experimentId = experiment.id;
        
        // Acquire bucketingId .
        let bucketingId = getBucketingId(userId:userId, attributes:attributes)
        
        // ---- check if the experiment is running ----
        if experiment.status != Experiment.Status.running {
            return nil;
        }
        
        // ---- check for whitelisted variation registered at runtime ----
        if let variationId = config.whitelistUsers[userId]?[experimentId],
            let variation = experiment.variations.filter({$0.id == variationId }).first {
            return variation;
        }

        // ---- check if the experiment has forced variation ----
        if let variationId = experiment.forcedVariations[userId], let variation = experiment.variations.filter({$0.id == variationId}).first {
            return variation
        }
        
        // ---- check if a valid variation is stored in the user profile ----
        if let variationId = userProfileService.variationId(userId: userId, experimentId: experimentId), let variation = experiment.variations.filter({$0.id == variationId}).first {
            return variation
        }
        
        var bucketedVariation:Variation?
        // ---- check if the user passes audience targeting before bucketing ----
        if let result = isInExperiment(
            experiment:experiment,
            userId:userId,
            attributes:attributes), result == true {
            
            // bucket user into a variation
            bucketedVariation = bucketer.bucketExperiment(experiment: experiment, bucketingId:bucketingId)
            
            if let bucketedVariation = bucketedVariation {
                // save to user profile
                userProfileService.saveProfile(userId: userId, experimentId: experimentId, variationId: bucketedVariation.id)
            }
        }
        
        return bucketedVariation;

    }
    
    func isInExperiment(experiment:Experiment, userId:String, attributes:Dictionary<String, Any>) -> Bool? {
        if let _ = experiment.audienceConditions {
            return experiment.audienceConditions?.evaluate(projectConfig: config, attributes: attributes)
        }
        else if experiment.audienceIds.count > 0 {
            var holder = [ConditionHolder]()
            holder.append(ConditionHolder.string("or"))
            for audienceId in experiment.audienceIds {
                holder.append(ConditionHolder.string(audienceId))
            }
            return holder.evaluate(config: config, attributes: attributes)
        }
        
        return true
    }
    
    func getExperimentInGroup(group:Group, bucketingId:String) -> Experiment? {
        let experiment = bucketer.bucketToExperiment(group:group, bucketingId:bucketingId)
        if let _ = experiment {
            // log
        }

        return experiment;
    }
    
     func getVariationForFeature(featureFlag:FeatureFlag, userId:String, attributes:Dictionary<String, Any>) -> (experiment:Experiment?, variation:Variation?)? {
        //Evaluate in this order:
        
        
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        // TODO: JSON schema does not have groupId, so removed from model. check it out.
        //
        //1. Attempt to check if the feature is in a mutex group.
//        if let groupId = featureFlag.groupId, let variation = getVariationForFeatureGroup(featureFlag: featureFlag, groupId: groupId, userId: userId, attributes: attributes) {
//            return variation
//        }
        //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

        
        
        //2. Attempt to bucket user into experiment using feature flag.
        // Check if the feature flag is under an experiment and the the user is bucketed into one of these experiments
        if let variation = getVariationForFeatureExperiment(featureFlag: featureFlag, userId:userId, attributes:attributes) {
            return variation
        }
        
        //2. Attempt to bucket user into rollout using the feature flag.
        // Check if the feature flag has rollout and the user is bucketed into one of it's rules
        if let variation = getVariationForFeatureRollout(featureFlag: featureFlag, userId:userId, attributes:attributes) {
            return (nil, variation)
        }
        
        return nil;

    }
    
    func getVariationForFeatureGroup(featureFlag:FeatureFlag, groupId:String, userId:String,                attributes:Dictionary<String, Any>) -> (experiment:Experiment?, variation:Variation?)? {
        
        let bucketing_id = getBucketingId(userId:userId, attributes:attributes)
        if let group = config.project.groups.filter({$0.id == groupId}).first {
            
            if let experiment = getExperimentInGroup(group: group, bucketingId:bucketing_id),
                featureFlag.experimentIds.contains(experiment.id),
                let variation = getVariation(userId:userId, experiment:experiment, attributes:attributes) {
                  // log
                    return (experiment,variation)
            }
        }
        else {
            // log unknown group
        }
    
        return nil
    }
    
    func getVariationForFeatureExperiment(featureFlag:FeatureFlag,
                                          userId:String,
                                          attributes:Dictionary<String,Any>) -> (experiment:Experiment?, variation:Variation?)? {
        
        let experimentIds = featureFlag.experimentIds;
        // Check if there are any experiment IDs inside feature flag
        // Evaluate each experiment ID and return the first bucketed experiment variation
        for experimentId in experimentIds {
            if let experiment = config.project.experiments.filter({$0.id == experimentId }).first {
                let variation = getVariation(userId: userId, experiment: experiment, attributes: attributes)
                return (experiment,variation)
            }
        }
        return nil;
    }
    
    func getVariationForFeatureRollout(featureFlag:FeatureFlag,
                                       userId:String,
                                       attributes:Dictionary<String, Any>) -> Variation? {
    
        let bucketingId = getBucketingId(userId: userId, attributes:attributes)
        
        guard featureFlag.rolloutId.trimmingCharacters(in: CharacterSet.whitespaces) != "" else {
            return nil
        }
        guard let rollout = config.project.rollouts.filter({$0.id == featureFlag.rolloutId}).first else {
            return nil
        }
        let rolloutRules = rollout.experiments
        // Evaluate all rollout rules except for last one
        for experiment in rolloutRules[0..<rolloutRules.count.advanced(by: -1)] {
            if isInExperiment(experiment: experiment, userId: userId, attributes: attributes) ?? false {
                if let variation = bucketer.bucketExperiment(experiment: experiment, bucketingId: bucketingId) {
                    return variation
                }
            }
        }
        // Evaluate fall back rule / last rule now
        let experiment = rolloutRules[rolloutRules.count - 1];
        if isInExperiment(experiment: experiment, userId: userId, attributes: attributes) ?? false {
            return bucketer.bucketExperiment(experiment: experiment, bucketingId: bucketingId)
        }
        
        return nil
    }
    
    func getBucketingId(userId:String, attributes:Dictionary<String, Any>) -> String {
        
        // By default, the bucketing ID should be the user ID .
        var bucketingId = userId
        // If the bucketing ID key is defined in attributes, then use that
        // in place of the userID for the murmur hash key
        if let newBucketingId = attributes[Constants.Attributes.OptimizelyBucketIdAttribute] as? String, newBucketingId != "" {
            bucketingId = newBucketingId
        }
        
        return bucketingId;
    }
    
    
}
