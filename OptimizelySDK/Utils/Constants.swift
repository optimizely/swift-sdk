//
//  Constants.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

struct Constants {
    struct Attributes {
        static let OptimizelyBucketIdAttribute = "$opt_bucketing_id";
        static let OptimizelyBotFilteringAttribute = "$opt_bot_filtering";
        static let OptimizelyUserAgent = "$opt_user_agent";
    }
    struct NotificationKeys {
        static let OptimizelyNotificationExperiment = "experiment"
        static let OptimizelyNotificationVariation = "variation"
        static let OptimizelyNotificationUserId = "userId"
        static let OptimizelyNotificationAttributes = "attributes"
        static let OptimizelyNotificationEvent = "eventKey"
        static let OptimizelyNotificationEventTags = "eventTags"
        static let OptimizelyNotificationLogEventParams = "logEventParams"
        static let OptimizelyNotificationDecisionInfoFeature = "featureKey"
        static let OptimizelyNotificationDecisionInfoFeatureEnabled = "featureEnabled"
        static let OptimizelyNotificationDecisionInfo = "decisionInfo"
        static let OptimizelyNotificationDecisionInfoSourceExperiment = "sourceExperimentKey"
        static let OptimizelyNotificationDecisionInfoSourceVariation = "sourceVariationKey"
        static let OptimizelyNotificationDecisionInfoSource = "source"
        static let OptimizelyNotificationDecisionInfoVariable = "variableKey"
        static let OptimizelyNotificationDecisionInfoVariableType = "variableType"
        static let OptimizelyNotificationDecisionInfoVariableValue = "variableValue"
        static let OptimizelyNotificationDecisionType = "type"
        static let OptimizelyDecisionTypeFeatureVariable  = "feature_variable"
    }
    struct DecisionSource {
        static let Experiment = "EXPERIMENT"
        static let Rollout = "ROLLOUT"
    }
}
