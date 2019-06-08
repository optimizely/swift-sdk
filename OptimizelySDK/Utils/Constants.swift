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

struct Constants {
    struct Attributes {
        static let OptimizelyBucketIdAttribute = "$opt_bucketing_id"
        static let OptimizelyBotFilteringAttribute = "$opt_bot_filtering"
        static let OptimizelyUserAgent = "$opt_user_agent"
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
