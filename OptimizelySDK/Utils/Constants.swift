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
    
    struct DecisionTypeKeys {
        static let abTest = "ab-test"
        static let feature  = "feature"
        static let featureVariable  = "feature-variable"
        static let featureTest = "feature-test"
    }
    
    struct DecisionInfoKeys {
        static let feature = "featureKey"
        static let featureEnabled = "featureEnabled"
        static let sourceInfo = "sourceInfo"
        static let source = "source"
        static let variable = "variableKey"
        static let variableType = "variableType"
        static let variableValue = "variableValue"
    }
    
    struct ExperimentDecisionInfoKeys {
        static let experiment = "experimentKey"
        static let variation = "variationKey"
    }
    
    struct DecisionSource {
        static let featureTest = "feature-test"
        static let rollout = "rollout"
    }

}
