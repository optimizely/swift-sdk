/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

public struct IntializeError : Error {
    let desciption:String
    
    init(description:String) {
        self.desciption = description
    }
}

public typealias OptimizelyInitCompletionHandler = (Result<Optimizely, IntializeError>) -> Void

public protocol Optimizely {
    
    var bucketer:OPTBucketer? { get }
    var decisionService:OPTDecisionService? { get }
    var config:ProjectConfig? { get }
    var errorHandler:OPTErrorHandler? { get }
    var eventDispatcher:OPTEventDispatcher? { get }
    var datafileHandler:OPTDatafileHandler? { get }
    var logger:Logger? { get }
    var userProfileService:OPTUserProfileService? { get }
    var notificationCenter:NotificationCenter? { get }
    
/**
 * Use the activate method to start an experiment.
 *
 * The activate call will conditionally activate an experiment for a user based on the provided experiment key and a randomized hash of the provided user ID.
 * If the user satisfies audience conditions for the experiment and the experiment is valid and running, the function returns the variation the user is bucketed into.
 * Otherwise, activate returns nil. Make sure that your code adequately deals with the case when the experiment is not activated (e.g. execute the default variation).
 */

/**
 * Try to activate an experiment based on the experiment key and user ID without user attributes.
 * @param experimentKey The key for the experiment.
 * @param userId The user ID to be used for bucketing.
 * @return The variation the user was bucketed into. This value can be nil.
 */
    func activate(experimentKey:String, userId:String) -> Variation?

/**
 * Try to activate an experiment based on the experiment key and user ID with user attributes.
 * @param experimentKey The key for the experiment.
 * @param userId The user ID to be used for bucketing.
 * @param attributes A map of attribute names to current user attribute values.
 * @return The variation the user was bucketed into. This value can be nil.
 */
    func activate(experimentKey:String, userId:String, attributes:Dictionary<String, Any>?) -> Variation?
/**
 * Use the getVariation method if activate has been called and the current variation assignment
 * is needed for a given experiment and user.
 * This method bypasses redundant network requests to Optimizely.
 */

/**
 * Get variation for experiment key and user ID without user attributes.
 * @param experimentKey The key for the experiment.
 * @param userId The user ID to be used for bucketing.
 * @return The variation the user was bucketed into. This value can be nil.
 */
    func variation(experimentKey:String, userId:String) -> Variation?

/**
 * Get variation for experiment and user ID with user attributes.
 * @param experimentKey The key for the experiment.
 * @param userId The user ID to be used for bucketing.
 * @param attributes A map of attribute names to current user attribute values.
 * @return The variation the user was bucketed into. This value can be nil.
 */
    func variation(experimentKey:String, userId:String, attributes:Dictionary<String, Any>?) -> Variation?
/**
 * Use the setForcedVariation method to force an experimentKey-userId
 * pair into a specific variation for QA purposes.
 * The forced bucketing feature allows customers to force users into
 * variations in real time for QA purposes without requiring datafile
 * downloads from the network. Methods activate and track are called
 * as usual after the variation is set, but the user will be bucketed
 * into the forced variation overriding any variation which would be
 * computed via the network datafile.
 */

/**
 * Return forced variation for experiment and user ID.
 * @param experimentKey The key for the experiment.
 * @param userId The user ID to be used for bucketing.
 * @return forced variation if it exists, otherwise return nil.
 */
    func getForcedVariation(experimentKey:String, userId:String) -> Variation?

/**
 * Set forced variation for experiment and user ID to variationKey.
 * @param experimentKey The key for the experiment.
 * @param userId The user ID to be used for bucketing.
 * @param variationKey The variation the user should be forced into.
 * This value can be nil, in which case, the forced variation is cleared.
 * @return YES if there were no errors, otherwise return NO.
 */
    func setForcedVariation(experimentKey:String, userId:String, variationKey:String?) -> Bool

/**
 * Determine whether a feature is enabled.
 * Send an impression event if the user is bucketed into an experiment using the feature.
 * @param featureKey The key for the feature flag.
 * @param userId The user ID to be used for bucketing.
 * @param attributes The user's attributes.
 * @return YES if feature is enabled, false otherwise.
 */
    func isFeatureEnabled(featureKey:String, userId:String, attributes:Dictionary<String,Any>?) -> Bool

/**
 * Gets boolean feature variable value.
 * @param featureKey The key for the feature flag.
 * @param variableKey The key for the variable.
 * @param userId The user ID to be used for bucketing.
 * @param attributes The user's attributes.
 * @return BOOL feature variable value.
 */
    func getFeatureVariableBoolean(featureKey:String, variableKey:String, userId:String, attributes:Dictionary<String, Any>?) -> Bool?

/**
 * Gets double feature variable value.
 * @param featureKey The key for the feature flag.
 * @param variableKey The key for the variable.
 * @param userId The user ID to be used for bucketing.
 * @param attributes The user's attributes.
 * @return double feature variable value of type double.
 */
    func getFeatureVariableDouble(featureKey:String, variableKey:String, userId:String, attributes:Dictionary<String, Any>?) -> Double?

/**
 * Gets integer feature variable value.
 * @param featureKey The key for the feature flag.
 * @param variableKey The key for the variable.
 * @param userId The user ID to be used for bucketing.
 * @param attributes The user's attributes.
 * @return int feature variable value of type integer.
 */
    func getFeatureVariableInteger(featureKey:String, variableKey:String, userId:String, attributes:Dictionary<String, Any>?) -> Int?

/**
 * Gets string feature variable value.
 * @param featureKey The key for the feature flag.
 * @param variableKey The key for the variable.
 * @param userId The user ID to be used for bucketing.
 * @param attributes The user's attributes.
 * @return NSString feature variable value of type string.
 */
    func getFeatureVariableString(featureKey:String, variableKey:String, userId:String, attributes:Dictionary<String, Any>?) -> String?

/**
 * Get array of features that are enabled for the user.
 * @param userId The user ID to be used for bucketing.
 * @param attributes The user's attributes.
 * @return NSArray<NSString> Array of feature keys that are enabled for the user.
 */
    func getEnabledFeatures(userId:String, attributes:Dictionary<String,Any>?) -> Array<String>

/**
 * Track an event
 * @param eventKey The event name
 * @param userId The user ID associated with the event to track
 */
    func track(eventKey:String, userId:String)

/**
 * Track an event
 * @param eventKey The event name
 * @param userId The user ID associated with the event to track
 * @param attributes A map of attribute names to current user attribute values.
 */
    func track(eventKey:String, userId:String, attributes:Dictionary<String,Any>?)

/**
 * Track an event
 * @param eventKey The event name
 * @param userId The user ID associated with the event to track
 * @param eventTags A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
 */
    func track(eventKey:String, userId:String, eventTags:Dictionary<String,Any>?)

/**
 * Track an event
 * @param eventKey The event name
 * @param userId The user ID associated with the event to track
 * @param attributes A map of attribute names to current user attribute values
 * @param eventTags A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
 */
    func track(eventKey:String, userId:String, attributes:Dictionary<String,Any>?, eventTags:Dictionary<String,Any>?)
}

