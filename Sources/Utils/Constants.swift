//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

struct Constants {
    struct Attributes {
        static let reservedBucketIdAttribute = "$opt_bucketing_id"
        static let reservedBotFilteringAttribute = "$opt_bot_filtering"
        static let reservedUserAgent = "$opt_user_agent"
        static let reservedUserIdKey = "fs_user_id"
    }
    
    enum EvaluationLogType: String {
        case experiment = "experiment"
        case rolloutRule = "rule"
    }
    
    enum VariableValueType: String {
        case string
        case integer
        case double
        case boolean
        case json
    }
    
    enum DecisionType: String {
        case abTest = "ab-test"
        case feature  = "feature"
        case featureVariable  = "feature-variable"
        case allFeatureVariables = "all-feature-variables"
        case featureTest = "feature-test"
        // Decide-APIs
        case flag = "flag"
    }
        
    enum DecisionSource: String {
        case experiment = "experiment"
        case featureTest = "feature-test"
        case rollout = "rollout"
    }
    
    struct DecisionInfoKeys {
        static let feature = "featureKey"
        static let featureEnabled = "featureEnabled"
        static let sourceInfo = "sourceInfo"
        static let source = "source"
        static let variable = "variableKey"
        static let variableType = "variableType"
        static let variableValue = "variableValue"
        static let variableValues = "variableValues"
        
        // Decide-API
        
        /// The flag key for which the decision has been made for.
        static let flagKey = "flagKey"
        /// The boolean value indicating if the flag is enabled or not.
        static let enabled = "enabled"
        /// The collection of variables assocaited with the decision.
        static let variables = "variables"
        /// The variation key of the decision. This value will be nil when decision making fails.
        static let variationKey = "variationKey"
        /// The rule key of the decision.
        static let ruleKey = "ruleKey"
        /// An array of error/info/debug messages describing why the decision has been made.
        static let reasons = "reasons"
        /// The boolean value indicating an decision event has been sent for the decision.
        static let decisionEventDispatched = "decisionEventDispatched"
    }
    
    struct ExperimentDecisionInfoKeys {
        static let experiment = "experimentKey"
        static let variation = "variationKey"
    }
    
}
