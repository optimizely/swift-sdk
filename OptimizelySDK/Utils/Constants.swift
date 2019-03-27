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
        static let OptimizelyDecisionTypeExperiment = "experiment"
    }
    struct DecisionSource {
        static let Experiment = "EXPERIMENT"
        static let Rollout = "ROLLOUT"
    }
}
