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
    //    FORCED_BUCKETING_FAILED: '%s: Variation key %s is not in datafile. Not activating user %s.',
    //    INVALID_OBJECT: '%s: Optimizely object is not valid. Failing %s.',
    //    INVALID_CLIENT_ENGINE: '%s: Invalid client engine passed: %s. Defaulting to node-sdk.',
    //    INVALID_VARIATION_ID: '%s: Bucketed into an invalid variation ID. Returning null.',
    //    NOTIFICATION_LISTENER_EXCEPTION: '%s: Notification listener for (%s) threw exception: %s',
    //    NO_ROLLOUT_EXISTS: '%s: There is no rollout of feature %s.',
    //    NOT_ACTIVATING_USER: '%s: Not activating user %s for experiment %s.',
    //    NOT_TRACKING_USER: '%s: Not tracking user %s.',
    case parsedRevenueValue(_ val: String)
    case parsedNumericValue(_ val: String)
    //    RETURNING_STORED_VARIATION: '%s: Returning previously activated variation "%s" of experiment "%s" for user "%s" from user profile.',
    //    ROLLOUT_HAS_NO_EXPERIMENTS: '%s: Rollout of feature %s has no experiments',
    //    SAVED_VARIATION: '%s: Saved variation "%s" of experiment "%s" for user "%s".',
    //    SAVED_VARIATION_NOT_FOUND: '%s: User %s was previously bucketed into variation with ID %s for experiment %s, but no matching variation was found.',
    //    SHOULD_NOT_DISPATCH_ACTIVATE: '%s: Experiment %s is in "Launched" state. Not activating user.',
    //    SKIPPING_JSON_VALIDATION: '%s: Skipping JSON schema validation.',
    //    TRACK_EVENT: '%s: Tracking event %s for user %s.',
    //    USER_ASSIGNED_TO_VARIATION_BUCKET: '%s: Assigned variation bucket %s to user %s.',
    //    USER_ASSIGNED_TO_EXPERIMENT_BUCKET: '%s: Assigned experiment bucket %s to user %s.',
    //    USER_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is in experiment %s of group %s.',
    //    USER_BUCKETED_INTO_TARGETING_RULE: '%s: User %s bucketed into targeting rule %s.',
    //    USER_IN_FEATURE_EXPERIMENT: '%s: User %s is in variation %s of experiment %s on the feature %s.',
    //    USER_IN_ROLLOUT: '%s: User %s is in rollout of feature %s.',
    //    USER_BUCKETED_INTO_EVERYONE_TARGETING_RULE: '%s: User %s bucketed into everyone targeting rule.',
    //    USER_NOT_BUCKETED_INTO_EVERYONE_TARGETING_RULE: '%s: User %s not bucketed into everyone targeting rule due to traffic allocation.',
    //    USER_NOT_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is not in experiment %s of group %s.',
    //    USER_NOT_BUCKETED_INTO_ANY_EXPERIMENT_IN_GROUP: '%s: User %s is not in any experiment of group %s.',
    //    USER_NOT_BUCKETED_INTO_TARGETING_RULE: '%s User %s not bucketed into targeting rule %s due to traffic allocation. Trying everyone rule.',
    //    USER_NOT_IN_FEATURE_EXPERIMENT: '%s: User %s is not in any experiment on the feature %s.',
    //    USER_NOT_IN_ROLLOUT: '%s: User %s is not in rollout of feature %s.',
    //    USER_FORCED_IN_VARIATION: '%s: User %s is forced in variation %s.',
    //    USER_MAPPED_TO_FORCED_VARIATION: '%s: Set variation %s for experiment %s and user %s in the forced variation map.',
    //    USER_DOESNT_MEET_CONDITIONS_FOR_TARGETING_RULE: '%s: User %s does not meet conditions for targeting rule %s.',
    //    USER_MEETS_CONDITIONS_FOR_TARGETING_RULE: '%s: User %s meets conditions for targeting rule %s.',
    //    USER_HAS_VARIATION: '%s: User %s is in variation %s of experiment %s.',
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
            //    FORCED_BUCKETING_FAILED: '%s: Variation key %s is not in datafile. Not activating user %s.',
            //    INVALID_OBJECT: '%s: Optimizely object is not valid. Failing %s.',
            //    INVALID_CLIENT_ENGINE: '%s: Invalid client engine passed: %s. Defaulting to node-sdk.',
            //    INVALID_VARIATION_ID: '%s: Bucketed into an invalid variation ID. Returning null.',
            //    NOTIFICATION_LISTENER_EXCEPTION: '%s: Notification listener for (%s) threw exception: %s',
            //    NO_ROLLOUT_EXISTS: '%s: There is no rollout of feature %s.',
            //    NOT_ACTIVATING_USER: '%s: Not activating user %s for experiment %s.',
            //    NOT_TRACKING_USER: '%s: Not tracking user %s.',
            case .parsedRevenueValue(let val):                          message = "Parsed revenue value \(val) from event tags."
            case .parsedNumericValue(let val):                          message = "Parsed event value \(val) from event tags."
            //    RETURNING_STORED_VARIATION: '%s: Returning previously activated variation "%s" of experiment "%s" for user "%s" from user profile.',
            //    ROLLOUT_HAS_NO_EXPERIMENTS: '%s: Rollout of feature %s has no experiments',
            //    SAVED_VARIATION: '%s: Saved variation "%s" of experiment "%s" for user "%s".',
            //    SAVED_VARIATION_NOT_FOUND: '%s: User %s was previously bucketed into variation with ID %s for experiment %s, but no matching variation was found.',
            //    SHOULD_NOT_DISPATCH_ACTIVATE: '%s: Experiment %s is in "Launched" state. Not activating user.',
            //    SKIPPING_JSON_VALIDATION: '%s: Skipping JSON schema validation.',
            //    TRACK_EVENT: '%s: Tracking event %s for user %s.',
            //    USER_ASSIGNED_TO_VARIATION_BUCKET: '%s: Assigned variation bucket %s to user %s.',
            //    USER_ASSIGNED_TO_EXPERIMENT_BUCKET: '%s: Assigned experiment bucket %s to user %s.',
            //    USER_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is in experiment %s of group %s.',
            //    USER_BUCKETED_INTO_TARGETING_RULE: '%s: User %s bucketed into targeting rule %s.',
            //    USER_IN_FEATURE_EXPERIMENT: '%s: User %s is in variation %s of experiment %s on the feature %s.',
            //    USER_IN_ROLLOUT: '%s: User %s is in rollout of feature %s.',
            //    USER_BUCKETED_INTO_EVERYONE_TARGETING_RULE: '%s: User %s bucketed into everyone targeting rule.',
            //    USER_NOT_BUCKETED_INTO_EVERYONE_TARGETING_RULE: '%s: User %s not bucketed into everyone targeting rule due to traffic allocation.',
            //    USER_NOT_BUCKETED_INTO_EXPERIMENT_IN_GROUP: '%s: User %s is not in experiment %s of group %s.',
            //    USER_NOT_BUCKETED_INTO_ANY_EXPERIMENT_IN_GROUP: '%s: User %s is not in any experiment of group %s.',
            //    USER_NOT_BUCKETED_INTO_TARGETING_RULE: '%s User %s not bucketed into targeting rule %s due to traffic allocation. Trying everyone rule.',
            //    USER_NOT_IN_FEATURE_EXPERIMENT: '%s: User %s is not in any experiment on the feature %s.',
            //    USER_NOT_IN_ROLLOUT: '%s: User %s is not in rollout of feature %s.',
            //    USER_FORCED_IN_VARIATION: '%s: User %s is forced in variation %s.',
            //    USER_MAPPED_TO_FORCED_VARIATION: '%s: Set variation %s for experiment %s and user %s in the forced variation map.',
            //    USER_DOESNT_MEET_CONDITIONS_FOR_TARGETING_RULE: '%s: User %s does not meet conditions for targeting rule %s.',
            //    USER_MEETS_CONDITIONS_FOR_TARGETING_RULE: '%s: User %s meets conditions for targeting rule %s.',
            //    USER_HAS_VARIATION: '%s: User %s is in variation %s of experiment %s.',
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

        }
        
        return message
    }
}
