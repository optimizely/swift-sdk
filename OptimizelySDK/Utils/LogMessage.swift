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

enum LogMessage {
    case experimentNotRunning(_ key: String)
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
    case userAssignedToVariationBucketValue(_ bucket: Int, _ userId: String)
    case userAssignedToExperimentBucketValue(_ bucket: Int, _ userId: String)
    case userMappedToForcedVariation(_ userId: String, _ expId: String, _ varId: String)
    case userMeetsConditionsForTargetingRule(_ userId: String, _ index: Int)
    case userDoesntMeetConditionsForTargetingRule(_ userId: String, _ index: Int)
    case userBucketedIntoTargetingRule(_ userId: String, _ index: Int)
    case userBucketedIntoEveryoneTargetingRule(_ userId: String)
    case userNotBucketedIntoEveryoneTargetingRule(_ userId: String)
    case userNotBucketedIntoTargetingRule(_ userId: String, _ index: Int)
    case userHasForcedVariation(_ userId: String, _ expKey: String, _ varKey: String)
    case userHasForcedVariationButInvalid(_ userId: String, _ expKey: String)
    case userHasNoForcedVariation(_ userId: String)
    case userHasNoForcedVariationForExperiment(_ userId: String, _ expKey: String)
    case userInFeatureExperiment(_ userId: String, _ varKey: String, _ expKey: String, _ feature: String)
    case userNotInFeatureExperiment(_ userId: String, _ feature: String)
    case userInRollout(_ userId: String, _ feature: String)
    case userNotInRollout(_ userId: String, _ feature: String)
    case userBucketedIntoVariationInExperiment(_ userId: String, _ expKey: String, _ varKey: String)
    case userNotBucketedIntoVariationInExperiment(_ userId: String, _ expKey: String)
    case userBucketedIntoInvalidVariation(_ id: String)
    case userBucketedIntoExperimentInGroup(_ userId: String, _ expKey: String, _ group: String)
    case userNotBucketedIntoExperimentInGroup(_ userId: String, _ expKey: String, _ group: String)
    case userNotBucketedIntoAnyExperimentInGroup(_ userId: String, _ group: String)
    case userBucketedIntoInvalidExperiment(_ id: String)
    case userNotInExperiment(_ userId: String, _ expKey: String)
    case userReceivedDefaultVariableValue(_ userId: String, _ feature: String, _ variable: String)
    case featureNotEnabledReturnDefaultVariableValue(_ userId: String, _ feature: String, _ variable: String)
    case variableNotUsedReturnDefaultVariableValue(_ variable: String)
    case userReceivedVariableValue(_ userId: String, _ feature: String, _ variable: String, _ value: String)
    case variationRemovedForUser(_ userId: String, _ expKey: String)
    case audienceEvaluationResult(_ audience: String, _ result: String)
    case audienceEvaluationResultCombined(_ expKey: String, _ result: String)
    case unrecognizedAttribute(_ key: String)
    case eventBatchFailed
    case eventSendRetyFailed(_ count: Int)
}

extension LogMessage: CustomStringConvertible {
    var description: String {
        var message: String
        
        switch self {
        case .experimentNotRunning(let key):                                    message = "Experiment (\(key)) is not running."
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
        case .userAssignedToVariationBucketValue(let bucket, let userId):       message = "Assigned variation bucket value (\(bucket)) to user (\(userId))"
        case .userAssignedToExperimentBucketValue(let bucket, let userId):      message = "Assigned experiment bucket value (\(bucket)) to user (\(userId))"
        case .userMappedToForcedVariation(let userId, let expId, let varId):    message = "Set variation (\(varId)) for experiment (\(expId)) and user (\(userId)) in the forced variation map."
        case .userMeetsConditionsForTargetingRule(let userId, let index):       message = "User (\(userId)) meets conditions for targeting rule (\(index))."
        case .userDoesntMeetConditionsForTargetingRule(let userId, let index):  message = "User (\(userId)) does not meet conditions for targeting rule (\(index))."
        case .userBucketedIntoTargetingRule(let userId, let index):             message = "User (\(userId)) bucketed into targeting rule (\(index))."
        case .userNotBucketedIntoTargetingRule(let userId, let index):          message = "User (\(userId)) not bucketed into targeting rule (\(index)) due to traffic allocation. Trying everyone rule."
        case .userBucketedIntoEveryoneTargetingRule(let userId):                message = "User (\(userId)) bucketed into everyone targeting rule."
        case .userNotBucketedIntoEveryoneTargetingRule(let userId):             message = "User (\(userId)) not bucketed into everyone targeting rule due to traffic allocation."
        case .userHasForcedVariation(let userId, let expKey, let varKey):       message = "Variation (\(varKey)) is mapped to experiment (\(expKey)) and user \(userId)) in the forced variation map."
        case .userHasForcedVariationButInvalid(let userId, let expKey):         message = "Invalid variation is mapped to experiment (\(expKey)) and user (\(userId)) in the forced variation map."
        case .userHasNoForcedVariation(let userId):                             message = "User (\(userId)) is not in the forced variation map."
        case .userHasNoForcedVariationForExperiment(let userId, let expKey):    message = "No experiment (\(expKey)) mapped to user (\(userId)) in the forced variation map."
        case .userInFeatureExperiment(let userId, let varKey, let expKey, let feature):  message = "User (\(userId)) is in variation (\(varKey)) of experiment (\(expKey)) on the feature (\(feature))."
        case .userNotInFeatureExperiment(let userId, let feature):              message = "User (\(userId)) is not in any experiment on the feature (\(feature))."
        case .userInRollout(let userId, let feature):                           message = "User (\(userId)) is in rollout of feature (\(feature))."
        case .userNotInRollout(let userId, let feature):                        message = "User (\(userId)) is not in rollout of feature (\(feature))."
        case .userBucketedIntoVariationInExperiment(let userId, let expKey, let varKey): message = "User (\(userId)) is in variation (\(varKey)) of experiment (\(expKey))"
        case .userNotBucketedIntoVariationInExperiment(let userId, let expKey): message = "User (\(userId)) is in no variation of experiment (\(expKey))."
        case .userBucketedIntoInvalidVariation(let id):                         message = "Bucketed into an invalid variation id (\(id))"
        case .userBucketedIntoExperimentInGroup(let userId, let expId, let group): message = "User (\(userId)) is in experiment (\(expId)) of group (\(group))."
        case .userNotBucketedIntoExperimentInGroup(let userId, let expKey, let group): message = "User (\(userId)) is not in experiment (\(expKey)) of group (\(group))."
        case .userNotBucketedIntoAnyExperimentInGroup(let userId, let group):   message = "User (\(userId)) is not in any experiment of group (\(group))."
        case .userBucketedIntoInvalidExperiment(let id):                        message = "Bucketed into an invalid experiment id (\(id))"
        case .userNotInExperiment(let userId, let expKey):                      message = "User (\(userId)) does not meet conditions to be in experiment (\(expKey))."
        case .userReceivedDefaultVariableValue(let userId, let feature, let variable): message = "User (\(userId)) is not in any variation or rollout rule. Returning default value for variable (\(variable)) of feature flag (\(feature))."
        case .featureNotEnabledReturnDefaultVariableValue(let userId, let feature, let variable): message = "Feature (\(feature)) is not enabled for user (\(userId)). Returning default value for variable (\(variable)."
        case .variableNotUsedReturnDefaultVariableValue(let variable):          message = "Variable (\(variable)) is not used in variation. Returning default value."
        case .userReceivedVariableValue(let userId, let feature, let variable, let value): message = "Value for variable (\(variable)) of feature flag (\(feature)) is (\(value)) for user (\(userId))"
        case .variationRemovedForUser(let userId, let expKey):                  message = "Variation mapped to experiment (\(expKey)) has been removed for user (\(userId))."
        case .audienceEvaluationResult(let audience, let result):               message = "Audience (\(audience)) evaluated to (\(result))."
        case .audienceEvaluationResultCombined(let expKey, let result):         message = "Audiences for experiment (\(expKey)) collectively evaluated to (\(result))."
        case .unrecognizedAttribute(let key):                                   message = "Unrecognized attribute (\(key)) provided. Pruning before sending event to Optimizely."
        case .eventBatchFailed:                                                 message = "Failed to batch events"
        case .eventSendRetyFailed(let count):                                   message = "Event dispatch retries failed (\(count)) times"
        }
        
        return message
    }
}
