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

protocol OPTDecisionService {
    /**
     Gets a variation based on the following rules (evaluated in sequential order):
     
     1. Experiments not running will return a nil variation.
     2. If the user is whitelisted for a particular variation,
     then that variation will be returned.
     3. If a valid variation for a given experiments is found in the user
     profile service, then that variation will be returned.
     4. If the user falls through #1-3, than the user will be bucketed
     if the user fulfills these criteria:
     a. Does the user pass audience targeting?
     b. Is the experiment that the user bucketed into NOT mutually excluded?
     c. Does traffic allocation exclude the user?
     
     - Parameter userId: The ID of the user.
     - Parameter experiment: The experiment in which to bucket the user.
     - Returns: The variation assigned to the specified user ID for an experiment.
     */
    func getVariation(config: ProjectConfig, userId: String, experiment: Experiment, attributes: OptimizelyAttributes) -> Variation?
    
    /**
     Get a variation the user is bucketed into for the given FeatureFlag
     - Parameter featureFlag: The feature flag the user wants to access.
     - Parameter userId: The ID of the user.
     - Parameter attributes: User attributes
     - Returns: The variation assigned to the specified user ID for a feature flag.
     */
    func getVariationForFeature(config: ProjectConfig, featureFlag: FeatureFlag, userId: String, attributes: OptimizelyAttributes) -> (experiment: Experiment?, variation: Variation?)?
    
}
