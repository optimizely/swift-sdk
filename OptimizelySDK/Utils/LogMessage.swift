//
//  LogMessage.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

enum LogMessage {
    case experimentNotRunning(_ key: String)
    case featureEnabledForUser(_ key: String, _ userId: String)
    case featureNotEnabledForUser(_ key: String, _ userId: String)
    case featureHasNoExperiments(_ key: String)
    case failedToParseValue(_ val: String)
    case failedToParseRevenue(_ val: String)
    case forcedBucketingFailed(_ key: String, _ userId: String)
    case invalidVariationId
    case noRolloutExists(_ key: String)
    //    NOT_ACTIVATING_USER: '%s: Not activating user %s for experiment %s.',
    //    NOT_TRACKING_USER: '%s: Not tracking user %s.',
    case parsedRevenueValue(_ val: String)
    case parsedNumericValue(_ val: String)
    //    RETURNING_STORED_VARIATION: '%s: Returning previously activated variation "%s" of experiment "%s" for user "%s" from user profile.',
    case rolloutHasNoExperiments(_ id: String)
    //    SAVED_VARIATION: '%s: Saved variation "%s" of experiment "%s" for user "%s".',
    //    SAVED_VARIATION_NOT_FOUND: '%s: User %s was previously bucketed into variation with ID %s for experiment %s, but no matching variation was found.',
    //    SHOULD_NOT_DISPATCH_ACTIVATE: '%s: Experiment %s is in "Launched" state. Not activating user.',
    //    SKIPPING_JSON_VALIDATION: '%s: Skipping JSON schema validation.',
    //    TRACK_EVENT: '%s: Tracking event %s for user %s.',
    //    USER_ASSIGNED_TO_VARIATION_BUCKET: '%s: Assigned variation bucket %s to user %s.',
    //    USER_ASSIGNED_TO_EXPERIMENT_BUCKET: '%s: Assigned experiment bucket %s to user %s.',
    //    USER_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is in experiment %s of group %s.',
    case userBucketedIntoTargetingRule(_ userId: String, _ index: Int)
    //    USER_IN_FEATURE_EXPERIMENT: '%s: User %s is in variation %s of experiment %s on the feature %s.',
    //    USER_IN_ROLLOUT: '%s: User %s is in rollout of feature %s.',
    case userBucketedIntoEveryoneTargetingRule(_ userId: String)
    case userNotBucketedIntoEveryoneTargetingRule(_ userId: String)
    //    USER_NOT_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is not in experiment %s of group %s.',
    //    USER_NOT_BUCKETED_INTO_ANY_EXPERIMENT_IN_GROUP: '%s: User %s is not in any experiment of group %s.',
    case userNotBucketedIntoTargetingRule(_ userId: String, _ index: Int)
    //    USER_NOT_IN_FEATURE_EXPERIMENT: '%s: User %s is not in any experiment on the feature %s.',
    //    USER_NOT_IN_ROLLOUT: '%s: User %s is not in rollout of feature %s.',
    case userForcedInVariation(_ key: String, _ userId: String)
    //    USER_MAPPED_TO_FORCED_VARIATION: '%s: Set variation %s for experiment %s and user %s in the forced variation map.',
    case userDoesntMeetConditionsForTargetingRule(_ userId: String, index: Int)
    case userMeetsConditionsForTargetingRule(_ userId: String, index: Int)
    case userHasVariation(_ userId: String, _ expKey: String, _ varKey: String)
    //    USER_HAS_FORCED_VARIATION: '%s: Variation %s is mapped to experiment %s and user %s in the forced variation map.',
    //    USER_HAS_NO_VARIATION: '%s: User %s is in no variation of experiment %s.',
    //    USER_HAS_NO_FORCED_VARIATION: '%s: User %s is not in the forced variation map.',
    //    USER_HAS_NO_FORCED_VARIATION_FOR_EXPERIMENT: '%s: No experiment %s mapped to user %s in the forced variation map.',
    //    USER_NOT_IN_ANY_EXPERIMENT: '%s: User %s is not in any experiment of group %s.',
    //    USER_NOT_IN_EXPERIMENT: '%s: User %s does not meet conditions to be in experiment %s.',
    //    USER_RECEIVED_DEFAULT_VARIABLE_VALUE: '%s: User "%s" is not in any variation or rollout rule. Returning default value for variable "%s" of feature flag "%s".',
    //    FEATURE_NOT_ENABLED_RETURN_DEFAULT_VARIABLE_VALUE: '%s: Feature "%s" is not enabled for user %s. Returning default value for variable "%s".',
    //    VARIABLE_NOT_USED_RETURN_DEFAULT_VARIABLE_VALUE: '%s: Variable "%s" is not used in variation "%s". Returning default value.',
    //    USER_RECEIVED_VARIABLE_VALUE: '%s: Value for variable "%s" of feature flag "%s" is %s for user "%s"',
    //    VALID_DATAFILE: '%s: Datafile is valid.',
    //    VALID_USER_PROFILE_SERVICE: '%s: Valid user profile service provided.',
    //    VARIATION_REMOVED_FOR_USER: '%s: Variation mapped to experiment %s has been removed for user %s.',
    //    VARIABLE_REQUESTED_WITH_WRONG_TYPE: '%s: Requested variable type "%s", but variable is of type "%s". Use correct API to retrieve value. Returning None.',
    //    VALID_BUCKETING_ID: '%s: BucketingId is valid: "%s"',
    //    BUCKETING_ID_NOT_STRING: '%s: BucketingID attribute is not a string. Defaulted to userId',
    //    EVALUATING_AUDIENCE: '%s: Starting to evaluate audience "%s" with conditions: %s.',
    //    EVALUATING_AUDIENCES_COMBINED: '%s: Evaluating audiences for experiment "%s": %s.',
    //    AUDIENCE_EVALUATION_RESULT: '%s: Audience "%s" evaluated to %s.',
    //    AUDIENCE_EVALUATION_RESULT_COMBINED: '%s: Audiences for experiment %s collectively evaluated to %s.',
    //    MISSING_ATTRIBUTE_VALUE: '%s: Audience condition %s evaluated to UNKNOWN because no value was passed for user attribute "%s".',
    //    UNEXPECTED_CONDITION_VALUE: '%s: Audience condition %s evaluated to UNKNOWN because the condition value is not supported.',
    //    UNEXPECTED_TYPE: '%s: Audience condition %s evaluated to UNKNOWN because a value of type "%s" was passed for user attribute "%s".',
    //    UNEXPECTED_TYPE_NULL: '%s: Audience condition %s evaluated to UNKNOWN because a null value was passed for user attribute "%s".',
    //    UNKNOWN_CONDITION_TYPE: '%s: Audience condition %s has an unknown condition type. You may need to upgrade to a newer release of the Optimizely SDK.',
    //    UNKNOWN_MATCH_TYPE: '%s: Audience condition %s uses an unknown match type. You may need to upgrade to a newer release of the Optimizely SDK.',
    //    OUT_OF_BOUNDS: '%s: Audience condition %s evaluated to UNKNOWN because the number value for user attribute "%s" is not in the range [-2^53, +2^53].',
    
//    EXPERIMENT_KEY_NOT_IN_DATAFILE: '%s: Experiment key %s is not in datafile.',
//    FEATURE_NOT_IN_DATAFILE: '%s: Feature key %s is not in datafile.',
//    IMPROPERLY_FORMATTED_EXPERIMENT: '%s: Experiment key %s is improperly formatted.',
//    INVALID_ATTRIBUTES: '%s: Provided attributes are in an invalid format.',
//    INVALID_BUCKETING_ID: '%s: Unable to generate hash for bucketing ID %s: %s',
//    INVALID_DATAFILE: '%s: Datafile is invalid - property %s: %s',
//    INVALID_DATAFILE_MALFORMED: '%s: Datafile is invalid because it is malformed.',
//    INVALID_JSON: '%s: JSON object is not valid.',
//    INVALID_ERROR_HANDLER: '%s: Provided "errorHandler" is in an invalid format.',
//    INVALID_EVENT_DISPATCHER: '%s: Provided "eventDispatcher" is in an invalid format.',
//    INVALID_EVENT_KEY: '%s: Event key %s is not in datafile.',
//    INVALID_EVENT_TAGS: '%s: Provided event tags are in an invalid format.',
//    INVALID_EXPERIMENT_KEY: '%s: Experiment key %s is not in datafile. It is either invalid, paused, or archived.',
//    INVALID_EXPERIMENT_ID: '%s: Experiment ID %s is not in datafile.',
//    INVALID_GROUP_ID: '%s: Group ID %s is not in datafile.',
//    INVALID_LOGGER: '%s: Provided "logger" is in an invalid format.',
    case invalidRolloutId(_ id: String, _ featureKey: String)
//    INVALID_USER_ID: '%s: Provided user ID is in an invalid format.',
//    INVALID_USER_PROFILE_SERVICE: '%s: Provided user profile service instance is in an invalid format: %s.',
//    JSON_SCHEMA_EXPECTED: '%s: JSON schema expected.',
//    NO_DATAFILE_SPECIFIED: '%s: No datafile specified. Cannot start optimizely.',
//    NO_JSON_PROVIDED: '%s: No JSON object to validate against schema.',
//    NO_VARIATION_FOR_EXPERIMENT_KEY: '%s: No variation key %s defined in datafile for experiment %s.',
//    UNDEFINED_ATTRIBUTE: '%s: Provided attribute: %s has an undefined value.',
//    UNRECOGNIZED_ATTRIBUTE: '%s: Unrecognized attribute %s provided. Pruning before sending event to Optimizely.',
//    UNABLE_TO_CAST_VALUE: '%s: Unable to cast value %s to type %s, returning null.',
//    USER_NOT_IN_FORCED_VARIATION: '%s: User %s is not in the forced variation map. Cannot remove their forced variation.',
//    USER_PROFILE_LOOKUP_ERROR: '%s: Error while looking up user profile for user ID "%s": %s.',
//    USER_PROFILE_SAVE_ERROR: '%s: Error while saving user profile for user ID "%s": %s.',
//    VARIABLE_KEY_NOT_IN_DATAFILE: '%s: Variable with key "%s" associated with feature with key "%s" is not in datafile.',
//    VARIATION_ID_NOT_IN_DATAFILE: '%s: No variation ID %s defined in datafile for experiment %s.',
//    VARIATION_ID_NOT_IN_DATAFILE_NO_EXPERIMENT: '%s: Variation ID %s is not in the datafile.',
//    INVALID_INPUT_FORMAT: '%s: Provided %s is in an invalid format.',
//    INVALID_DATAFILE_VERSION: '%s: This version of the JavaScript SDK does not support the given datafile version: %s',
//    INVALID_VARIATION_KEY: '%s: Provided variation key is in an invalid format.',

}


extension LogMessage: CustomStringConvertible {
    var description: String {
        var message: String
        
        switch self {
            //[NU]    ACTIVATE_USER: '%s: Activating user %s in experiment %s.',
            //[NU]    DISPATCH_CONVERSION_EVENT: '%s: Dispatching conversion event to URL %s with params %s.',
            //[NU]    DISPATCH_IMPRESSION_EVENT: '%s: Dispatching impression event to URL %s with params %s.',
            //[NU]    DEPRECATED_EVENT_VALUE: '%s: Event value is deprecated in %s call.',
            case .experimentNotRunning(let key):                        message = "Experiment \(key) is not running."
            case .featureEnabledForUser(let key, let userId):           message = "Feature \(key) is enabled for user \(userId)."
            case .featureNotEnabledForUser(let key, let userId):        message = "Feature \(key) is not enabled for user \(userId)."
            case .featureHasNoExperiments(let key):                     message = "Feature \(key) is not attached to any experiments."
            case .failedToParseValue(let val):                          message = "Failed to parse event value \(val) from event tags."
            case .failedToParseRevenue(let val):                        message = "Failed to parse revenue value \(val) from event tags."
            case .forcedBucketingFailed(let key, let userId):           message = "Variation key \(key) is not in datafile. Not activating user \(userId)"
            //[NU]    INVALID_OBJECT: '%s: Optimizely object is not valid. Failing %s.',
            //[NU]    INVALID_CLIENT_ENGINE: '%s: Invalid client engine passed: %s. Defaulting to node-sdk.',
            case .invalidVariationId:                                   message = "Bucketed into an invalid variation ID. Returning nil."
            //[NU]    NOTIFICATION_LISTENER_EXCEPTION: '%s: Notification listener for (%s) threw exception: %s',
            case .noRolloutExists(let key):                             message = "There is no rollout of feature \(key)."
            //    NOT_ACTIVATING_USER: '%s: Not activating user %s for experiment %s.',
            //    NOT_TRACKING_USER: '%s: Not tracking user %s.',
            case .parsedRevenueValue(let val):                          message = "Parsed revenue value \(val) from event tags."
            case .parsedNumericValue(let val):                          message = "Parsed event value \(val) from event tags."
            //    RETURNING_STORED_VARIATION: '%s: Returning previously activated variation "%s" of experiment "%s" for user "%s" from user profile.',
            case .rolloutHasNoExperiments(let id):                      message = "Rollout of feature \(id) has no experiments"
            //    SAVED_VARIATION: '%s: Saved variation "%s" of experiment "%s" for user "%s".',
            //    SAVED_VARIATION_NOT_FOUND: '%s: User %s was previously bucketed into variation with ID %s for experiment %s, but no matching variation was found.',
            //    SHOULD_NOT_DISPATCH_ACTIVATE: '%s: Experiment %s is in "Launched" state. Not activating user.',
            //    SKIPPING_JSON_VALIDATION: '%s: Skipping JSON schema validation.',
            //    TRACK_EVENT: '%s: Tracking event %s for user %s.',
            //    USER_ASSIGNED_TO_VARIATION_BUCKET: '%s: Assigned variation bucket %s to user %s.',
            //    USER_ASSIGNED_TO_EXPERIMENT_BUCKET: '%s: Assigned experiment bucket %s to user %s.',
            //    USER_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is in experiment %s of group %s.',
            case .userBucketedIntoTargetingRule(let userId, let index):  message = "User \(userId) bucketed into targeting rule \(index)."
            //    USER_IN_FEATURE_EXPERIMENT: '%s: User %s is in variation %s of experiment %s on the feature %s.',
            //    USER_IN_ROLLOUT: '%s: User %s is in rollout of feature %s.',
            case .userBucketedIntoEveryoneTargetingRule(let userId):   message = "User \(userId) bucketed into everyone targeting rule."
            case .userNotBucketedIntoEveryoneTargetingRule(let userId): message = "User \(userId) not bucketed into everyone targeting rule due to traffic allocation."
            //    USER_NOT_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is not in experiment %s of group %s.',
            //    USER_NOT_BUCKETED_INTO_ANY_EXPERIMENT_IN_GROUP: '%s: User %s is not in any experiment of group %s.',
            case .userNotBucketedIntoTargetingRule(let userId, let index):  message = "User \(userId) not bucketed into targeting rule \(index) due to traffic allocation. Trying everyone rule."
            //    USER_NOT_IN_FEATURE_EXPERIMENT: '%s: User %s is not in any experiment on the feature %s.',
            //    USER_NOT_IN_ROLLOUT: '%s: User %s is not in rollout of feature %s.',
            case .userForcedInVariation(let key, let userId):           message = "User \(userId) is forced in variation \(key)"
            //    USER_MAPPED_TO_FORCED_VARIATION: '%s: Set variation %s for experiment %s and user %s in the forced variation map.',
            case .userDoesntMeetConditionsForTargetingRule(let userId, let index):   message = "User \(userId) does not meet conditions for targeting rule \(index)."
            case .userMeetsConditionsForTargetingRule(let userId, let index): message = "User \(userId) meets conditions for targeting rule \(index)."
            case .userHasVariation(let userId, let expKey, let varKey):    message = "User \(userId) is in variation \(varKey) of experiment \(expKey)"
            //    USER_HAS_FORCED_VARIATION: '%s: Variation %s is mapped to experiment %s and user %s in the forced variation map.',
            //    USER_HAS_NO_VARIATION: '%s: User %s is in no variation of experiment %s.',
            //    USER_HAS_NO_FORCED_VARIATION: '%s: User %s is not in the forced variation map.',
            //    USER_HAS_NO_FORCED_VARIATION_FOR_EXPERIMENT: '%s: No experiment %s mapped to user %s in the forced variation map.',
            //    USER_NOT_IN_ANY_EXPERIMENT: '%s: User %s is not in any experiment of group %s.',
            //    USER_NOT_IN_EXPERIMENT: '%s: User %s does not meet conditions to be in experiment %s.',
            //    USER_RECEIVED_DEFAULT_VARIABLE_VALUE: '%s: User "%s" is not in any variation or rollout rule. Returning default value for variable "%s" of feature flag "%s".',
            //    FEATURE_NOT_ENABLED_RETURN_DEFAULT_VARIABLE_VALUE: '%s: Feature "%s" is not enabled for user %s. Returning default value for variable "%s".',
            //    VARIABLE_NOT_USED_RETURN_DEFAULT_VARIABLE_VALUE: '%s: Variable "%s" is not used in variation "%s". Returning default value.',
            //    USER_RECEIVED_VARIABLE_VALUE: '%s: Value for variable "%s" of feature flag "%s" is %s for user "%s"',
            //    VALID_DATAFILE: '%s: Datafile is valid.',
            //    VALID_USER_PROFILE_SERVICE: '%s: Valid user profile service provided.',
            //    VARIATION_REMOVED_FOR_USER: '%s: Variation mapped to experiment %s has been removed for user %s.',
            //    VARIABLE_REQUESTED_WITH_WRONG_TYPE: '%s: Requested variable type "%s", but variable is of type "%s". Use correct API to retrieve value. Returning None.',
            //    VALID_BUCKETING_ID: '%s: BucketingId is valid: "%s"',
            //    BUCKETING_ID_NOT_STRING: '%s: BucketingID attribute is not a string. Defaulted to userId',
            //    EVALUATING_AUDIENCE: '%s: Starting to evaluate audience "%s" with conditions: %s.',
            //    EVALUATING_AUDIENCES_COMBINED: '%s: Evaluating audiences for experiment "%s": %s.',
            //    AUDIENCE_EVALUATION_RESULT: '%s: Audience "%s" evaluated to %s.',
            //    AUDIENCE_EVALUATION_RESULT_COMBINED: '%s: Audiences for experiment %s collectively evaluated to %s.',
            //    MISSING_ATTRIBUTE_VALUE: '%s: Audience condition %s evaluated to UNKNOWN because no value was passed for user attribute "%s".',
            //    UNEXPECTED_CONDITION_VALUE: '%s: Audience condition %s evaluated to UNKNOWN because the condition value is not supported.',
            //    UNEXPECTED_TYPE: '%s: Audience condition %s evaluated to UNKNOWN because a value of type "%s" was passed for user attribute "%s".',
            //    UNEXPECTED_TYPE_NULL: '%s: Audience condition %s evaluated to UNKNOWN because a null value was passed for user attribute "%s".',
            //    UNKNOWN_CONDITION_TYPE: '%s: Audience condition %s has an unknown condition type. You may need to upgrade to a newer release of the Optimizely SDK.',
            //    UNKNOWN_MATCH_TYPE: '%s: Audience condition %s uses an unknown match type. You may need to upgrade to a newer release of the Optimizely SDK.',
            //    OUT_OF_BOUNDS: '%s: Audience condition %s evaluated to UNKNOWN because the number value for user attribute "%s" is not in the range [-2^53, +2^53].',

//            EXPERIMENT_KEY_NOT_IN_DATAFILE: '%s: Experiment key %s is not in datafile.',
//            FEATURE_NOT_IN_DATAFILE: '%s: Feature key %s is not in datafile.',
//            IMPROPERLY_FORMATTED_EXPERIMENT: '%s: Experiment key %s is improperly formatted.',
//            INVALID_ATTRIBUTES: '%s: Provided attributes are in an invalid format.',
//            INVALID_BUCKETING_ID: '%s: Unable to generate hash for bucketing ID %s: %s',
//            INVALID_DATAFILE: '%s: Datafile is invalid - property %s: %s',
//            INVALID_DATAFILE_MALFORMED: '%s: Datafile is invalid because it is malformed.',
//            INVALID_JSON: '%s: JSON object is not valid.',
//            INVALID_ERROR_HANDLER: '%s: Provided "errorHandler" is in an invalid format.',
//            INVALID_EVENT_DISPATCHER: '%s: Provided "eventDispatcher" is in an invalid format.',
//            INVALID_EVENT_KEY: '%s: Event key %s is not in datafile.',
//            INVALID_EVENT_TAGS: '%s: Provided event tags are in an invalid format.',
//            INVALID_EXPERIMENT_KEY: '%s: Experiment key %s is not in datafile. It is either invalid, paused, or archived.',
//            INVALID_EXPERIMENT_ID: '%s: Experiment ID %s is not in datafile.',
//            INVALID_GROUP_ID: '%s: Group ID %s is not in datafile.',
//            INVALID_LOGGER: '%s: Provided "logger" is in an invalid format.',
            case .invalidRolloutId(let id, let featureKey):     message = "Invalid rollout ID \(id) attached to feature \(featureKey)"
//            INVALID_USER_ID: '%s: Provided user ID is in an invalid format.',
//            INVALID_USER_PROFILE_SERVICE: '%s: Provided user profile service instance is in an invalid format: %s.',
//            JSON_SCHEMA_EXPECTED: '%s: JSON schema expected.',
//            NO_DATAFILE_SPECIFIED: '%s: No datafile specified. Cannot start optimizely.',
//            NO_JSON_PROVIDED: '%s: No JSON object to validate against schema.',
//            NO_VARIATION_FOR_EXPERIMENT_KEY: '%s: No variation key %s defined in datafile for experiment %s.',
//            UNDEFINED_ATTRIBUTE: '%s: Provided attribute: %s has an undefined value.',
//            UNRECOGNIZED_ATTRIBUTE: '%s: Unrecognized attribute %s provided. Pruning before sending event to Optimizely.',
//            UNABLE_TO_CAST_VALUE: '%s: Unable to cast value %s to type %s, returning null.',
//            USER_NOT_IN_FORCED_VARIATION: '%s: User %s is not in the forced variation map. Cannot remove their forced variation.',
//            USER_PROFILE_LOOKUP_ERROR: '%s: Error while looking up user profile for user ID "%s": %s.',
//            USER_PROFILE_SAVE_ERROR: '%s: Error while saving user profile for user ID "%s": %s.',
//            VARIABLE_KEY_NOT_IN_DATAFILE: '%s: Variable with key "%s" associated with feature with key "%s" is not in datafile.',
//            VARIATION_ID_NOT_IN_DATAFILE: '%s: No variation ID %s defined in datafile for experiment %s.',
//            VARIATION_ID_NOT_IN_DATAFILE_NO_EXPERIMENT: '%s: Variation ID %s is not in the datafile.',
//            INVALID_INPUT_FORMAT: '%s: Provided %s is in an invalid format.',
//            INVALID_DATAFILE_VERSION: '%s: This version of the JavaScript SDK does not support the given datafile version: %s',
//            INVALID_VARIATION_KEY: '%s: Provided variation key is in an invalid format.',

            
            default:  message = "UNKNOWN"
        }
        
        return message
    }
}
