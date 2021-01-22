/****************************************************************************
* Copyright 2021, Optimizely, Inc. and contributors                        *
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

/// Options controlling flag decisions.
@objc public enum OptimizelyDecideOption: Int {
    /// disable decision event tracking.
    case disableDecisionEvent
    
    /// return decisions only for flags which are enabled (decideAll only).
    case enabledFlagsOnly
    
    /// skip user profile service for decision.
    case ignoreUserProfileService
    
    /// include info and debug messages in the decision reasons.
    case includeReasons
    
    /// exclude variable values from the decision result.
    case excludeVariables
}
