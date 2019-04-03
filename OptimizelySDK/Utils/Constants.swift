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
        static let experiment = "experiment"
        static let variation = "variation"
    }
    
    struct DecisionTypeKeys {
        static let featureVariable  = "feature_variable"
        static let isFeatureEnabled  = "feature"
        static let experiment = "experiment"
    }
    
    struct DecisionInfoKeys {
        static let feature = "featureKey"
        static let featureEnabled = "featureEnabled"
        static let sourceExperiment = "sourceExperimentKey"
        static let sourceVariation = "sourceVariationKey"
        static let source = "source"
        static let variable = "variableKey"
        static let variableType = "variableType"
        static let variableValue = "variableValue"
    }
    
    struct DecisionSource {
        static let Experiment = "EXPERIMENT"
        static let Rollout = "ROLLOUT"
    }
}
