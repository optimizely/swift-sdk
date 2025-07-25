//
// Copyright 2019-2021, 2023 Optimizely, Inc. and contributors
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

enum LogMessage {
    case experimentNotRunning(_ key: String)
    case holdoutNotRunning(_ key: String)
    case featureEnabledForUser(_ key: String, _ userId: String)
    case featureNotEnabledForUser(_ key: String, _ userId: String)
    case featureHasNoExperiments(_ key: String)
    case noRolloutExists(_ key: String)
    case extractRevenueFromEventTags(_ val: String)
    case extractValueFromEventTags(_ val: String)
    case failedToExtractRevenueFromEventTags(_ val: String)
    case failedToExtractValueFromEventTags(_ val: String)
    case gotVariationFromUserProfile(_ varKey: String, _ expKey: String, _ userId: String)
    case rolloutHasNoExperiments(_ id: String)
    case forcedVariationFound(_ key: String, _ userId: String)
    case forcedVariationFoundButInvalid(_ key: String, _ userId: String)
    case savedVariationInUserProfile(_ varId: String, _ expId: String, _ userId: String)
    case userAssignedToBucketValue(_ bucket: Int, _ userId: String)
    case userMappedToForcedVariation(_ userId: String, _ expId: String, _ varId: String)
    case userMeetsConditionsForTargetingRule(_ userId: String, _ rule: String)
    case userMeetsConditionsForHoldout(_ userId: String, _ holdoutKey: String)
    case userDoesntMeetConditionsForTargetingRule(_ userId: String, _ rule: String)
    case userDoesntMeetConditionsForHoldout(_ userId: String, _ holdoutKey: String)
    case userBucketedIntoTargetingRule(_ userId: String, _ rule: String)
    case userNotBucketedIntoTargetingRule(_ userId: String, _ rule: String)
    case userHasForcedDecision(_ userId: String, _ flagKey: String, _ ruleKey: String?, _ varKey: String)
    case userHasForcedDecisionButInvalid(_ userId: String, _ flagKey: String, _ ruleKey: String?)
    case userHasForcedVariation(_ userId: String, _ expKey: String, _ varKey: String)
    case userHasForcedVariationButInvalid(_ userId: String, _ expKey: String)
    case userHasNoForcedVariation(_ userId: String)
    case userHasNoForcedVariationForExperiment(_ userId: String, _ expKey: String)
    case userBucketedIntoVariationInExperiment(_ userId: String, _ expKey: String, _ varKey: String)
    case userBucketedIntoEntity(_ entityId: String)
    case userNotBucketedIntoAnyEntity
    case userBucketedIntoVariationInHoldout(_ userId: String, _ expKey: String, _ varKey: String)
    case userNotBucketedIntoVariation(_ userId: String)
    case userBucketedIntoInvalidVariation(_ id: String)
    case userNotBucketedIntoHoldoutVariation(_ userId: String)
    case userBucketedIntoExperimentInGroup(_ userId: String, _ expKey: String, _ group: String)
    case userNotBucketedIntoExperimentInGroup(_ userId: String, _ expKey: String, _ group: String)
    case userNotBucketedIntoAnyExperimentInGroup(_ userId: String, _ group: String)
    case userBucketedIntoInvalidExperiment(_ id: String)
    case userNotInExperiment(_ userId: String, _ expKey: String)
    case userNotInCmabExperiment(_ userId: String, _ expKey: String)
    case userReceivedDefaultVariableValue(_ userId: String, _ feature: String, _ variable: String)
    case userReceivedAllDefaultVariableValues(_ userId: String, _ feature: String)
    case featureNotEnabledReturnDefaultVariableValue(_ userId: String, _ feature: String, _ variable: String)
    case userReceivedVariableValue(_ value: String, _ variable: String, _ feature: String)
    case variationRemovedForUser(_ userId: String, _ expKey: String)
    case audienceEvaluationStarted(_ audience: String, _ conditions: String)
    case audienceEvaluationResult(_ audience: String, _ result: String)
    case evaluatingAudiencesCombined(_ type: String, _ loggingKey: String, _ conditions: String)
    case audienceEvaluationResultCombined(_ type: String, _ loggingKey: String, _ result: String)
    case unrecognizedAttribute(_ key: String)
    case eventBatchFailed
    case eventSendRetyFailed(_ count: Int)
    case odpEventSendRetyFailed(_ count: Int)
    case failedToConvertMapToString
    case failedToAssignValue
    case valueForKeyNotFound(_ key: String)
    case lowPeriodicDownloadInterval
    case cmabFetchFailed(_ expKey: String)
    case cmabNotSupportedInSyncMode
}

extension LogMessage: CustomStringConvertible {
    var description: String {
        var message: String
        
        switch self {
        case .experimentNotRunning(let key):                                    message = "Experiment (\(key)) is not running."
        case .holdoutNotRunning(let key):                                       message = "Holdout (\(key)) is not running."
        case .featureEnabledForUser(let key, let userId):                       message = "Feature (\(key)) is enabled for user (\(userId))."
        case .featureNotEnabledForUser(let key, let userId):                    message = "Feature (\(key)) is not enabled for user (\(userId))."
        case .featureHasNoExperiments(let key):                                 message = "Feature (\(key)) is not attached to any experiments."
        case .noRolloutExists(let key):                                         message = "There is no rollout of feature (\(key))."
        case .extractRevenueFromEventTags(let val):                             message = "Parsed revenue (\(val)) from event tags."
        case .extractValueFromEventTags(let val):                               message = "Parsed value (\(val)) from event tags."
        case .failedToExtractRevenueFromEventTags(let val):                     message = "Failed to parse revenue (\(val)) from event tags."
        case .failedToExtractValueFromEventTags(let val):                       message = "Failed to parse value (\(val)) from event tags."
        case .gotVariationFromUserProfile(let varKey, let expKey, let userId):  message = "Returning previously activated variation (\(varKey)) of experiment (\(expKey)) for user (\(userId)) from user profile."
        case .rolloutHasNoExperiments(let id):                                  message = "Rollout of feature (\(id)) has no experiments"
        case .forcedVariationFound(let key, let userId):                        message = "Forced variation (\(key)) is found for user (\(userId))"
        case .forcedVariationFoundButInvalid(let key, let userId):              message = "Forced variation (\(key)) is found for user (\(userId)), but it's not in datafile."
        case .savedVariationInUserProfile(let varId, let expId, let userId):    message = "Saved variation (\(varId)) of experiment (\(expId)) for user (\(userId))."
        case .userAssignedToBucketValue(let bucket, let userId):                message = "Assigned bucket (\(bucket)) to user with bucketing ID (\(userId))."
        case .userMappedToForcedVariation(let userId, let expId, let varId):    message = "Set variation (\(varId)) for experiment (\(expId)) and user (\(userId)) in the forced variation map."
        case .userMeetsConditionsForTargetingRule(let userId, let rule):        message = "User (\(userId)) meets conditions for targeting rule (\(rule))."
        case .userMeetsConditionsForHoldout(let userId, let holdoutKey):        message = "User (\(userId)) meets conditions for holdout(\(holdoutKey))."
        case .userDoesntMeetConditionsForTargetingRule(let userId, let rule):   message = "User (\(userId)) does not meet conditions for targeting rule (\(rule))."
        case .userDoesntMeetConditionsForHoldout(let userId, let holdoutKey):   message = "User (\(userId)) does not meet conditions for holdout (\(holdoutKey))."
        case .userBucketedIntoTargetingRule(let userId, let rule):              message = "User (\(userId)) is in the traffic group of targeting rule (\(rule))."
        case .userNotBucketedIntoTargetingRule(let userId, let rule):           message = "User (\(userId)) is not in the traffic group for targeting rule (\(rule)). Checking (Everyone Else) rule now."
        case .userHasForcedDecision(let userId, let flagKey, let ruleKey, let varKey):
            let target = (ruleKey != nil) ? "flag (\(flagKey)), rule (\(ruleKey!))" : "flag (\(flagKey))"
            message = "Variation (\(varKey)) is mapped to \(target) and user (\(userId)) in the forced decision map."
        case .userHasForcedDecisionButInvalid(let userId, let flagKey, let ruleKey):
            let target = (ruleKey != nil) ? "flag (\(flagKey)), rule (\(ruleKey!))" : "flag (\(flagKey))"
            message = "Invalid variation is mapped to \(target) and user (\(userId)) in the forced decision map."
        case .userHasForcedVariation(let userId, let expKey, let varKey):       message = "Variation (\(varKey)) is mapped to experiment (\(expKey)) and user \(userId)) in the forced variation map."
        case .userHasForcedVariationButInvalid(let userId, let expKey):         message = "Invalid variation is mapped to experiment (\(expKey)) and user (\(userId)) in the forced variation map."
        case .userHasNoForcedVariation(let userId):                             message = "User (\(userId)) is not in the forced variation map."
        case .userHasNoForcedVariationForExperiment(let userId, let expKey):    message = "No experiment (\(expKey)) mapped to user (\(userId)) in the forced variation map."
        case .userBucketedIntoVariationInExperiment(let userId, let expKey, let varKey): message = "User (\(userId)) is in variation (\(varKey)) of experiment (\(expKey))"
        case .userBucketedIntoEntity(let entityId):                             message = "User bucketed into entity (\(entityId))"
        case .userNotBucketedIntoAnyEntity:                                     message = "User not bucketed into any entity"
        case .userBucketedIntoVariationInHoldout(let userId, let holdoutKey, let varKey): message = "User (\(userId)) is in variation (\(varKey)) of holdout (\(holdoutKey))"
        case .userNotBucketedIntoVariation(let userId):                         message = "User (\(userId)) is in no variation."
        case .userNotBucketedIntoHoldoutVariation(let userId):                  message = "User (\(userId)) is in no holdout variation."
        case .userBucketedIntoInvalidVariation(let id):                         message = "Bucketed into an invalid variation id (\(id))"
        case .userBucketedIntoExperimentInGroup(let userId, let expId, let group): message = "User (\(userId)) is in experiment (\(expId)) of group (\(group))."
        case .userNotBucketedIntoExperimentInGroup(let userId, let expKey, let group): message = "User (\(userId)) is not in experiment (\(expKey)) of group (\(group))."
        case .userNotBucketedIntoAnyExperimentInGroup(let userId, let group):   message = "User (\(userId)) is not in any experiment of group (\(group))."
        case .userBucketedIntoInvalidExperiment(let id):                        message = "Bucketed into an invalid experiment id (\(id))"
        case .userNotInExperiment(let userId, let expKey):                      message = "User (\(userId)) does not meet conditions to be in experiment (\(expKey))."
        case .userNotInCmabExperiment(let userId, let expKey):                  message = "User (\(userId)) does not fall into cmab traffic allocation in experiment (\(expKey))."
        case .userReceivedDefaultVariableValue(let userId, let feature, let variable): message = "User (\(userId)) is not in any variation or rollout rule. Returning default value for variable (\(variable)) of feature flag (\(feature))."
        case .userReceivedAllDefaultVariableValues(let userId, let feature): message = "User (\(userId)) is not in any variation or rollout rule. Returning default value for all variables of feature flag (\(feature))."
        case .featureNotEnabledReturnDefaultVariableValue(let userId, let feature, let variable): message = "Feature (\(feature)) is not enabled for user (\(userId)). Returning the default variable value (\(variable))."
        case .userReceivedVariableValue(let value, let variable, let feature): message = "Got variable value (\(value)) for variable (\(variable)) of feature flag (\(feature))."
        case .variationRemovedForUser(let userId, let expKey):                  message = "Variation mapped to experiment (\(expKey)) has been removed for user (\(userId))."
        case .audienceEvaluationStarted(let audience, let conditions):          message = "Starting to evaluate audience (\(audience)) with conditions: (\(conditions))."
        case .audienceEvaluationResult(let audience, let result):               message = "Audience (\(audience)) evaluated to (\(result))."
        case .evaluatingAudiencesCombined(let type, let loggingKey, let conditions):      message = "Evaluating audiences for (\(type)) (\(loggingKey)): (\(conditions))."
        case .audienceEvaluationResultCombined(let type, let loggingKey, let result):      message = "Audiences for \(type) (\(loggingKey)) collectively evaluated to (\(result))."
        case .unrecognizedAttribute(let key):                                   message = "Unrecognized attribute (\(key)) provided. Pruning before sending event to Optimizely."
        case .eventBatchFailed:                                                 message = "Failed to batch events"
        case .eventSendRetyFailed(let count):                                   message = "Event dispatch retries failed (\(count)) times"
        case .odpEventSendRetyFailed(let count):                                message = "ODP event dispatch retries failed (\(count)) times"
        case .failedToConvertMapToString:                                       message = "Provided map could not be converted to string."
        case .failedToAssignValue:                                              message = "Value for path could not be assigned to provided type."
        case .valueForKeyNotFound(let key):                                     message = "Value for JSON key (\(key)) not found."
        case .lowPeriodicDownloadInterval:                                      message = "Polling intervals below 30 seconds are not recommended."
        case .cmabFetchFailed(let key):                                         message = "Failed to fetch CMAB data for experiment: \(key)."
        case .cmabNotSupportedInSyncMode:                                       message = "CMAB is not supported in sync mode."
        }
        
        return message
    }
}

extension LogMessage: ReasonProtocol {
    var reason: String {
        return description
    }
}
