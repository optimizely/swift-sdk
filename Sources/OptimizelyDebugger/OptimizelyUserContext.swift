//
/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

#if DEBUG || OPT_DBG

import Foundation

@objcMembers public class OptimizelyUserContext {
    var userId: String
    
    var attributes: OptimizelyAttributes?
    
    var userProfiles: [String: String]?
    var forcedVariations: [String: String]?
    var forcedFeatures: [String: Bool]?
    
    init(userId: String, attributes: OptimizelyAttributes?) {
        self.userId = userId
        self.attributes = attributes
        self.userProfiles = [:]
        self.forcedVariations = [:]
        self.forcedFeatures = [:]
    }
    
    func addForcedVariation(experimentKey: String, variationKey: String?) {
        if let variationKey = variationKey {
            forcedVariations?.updateValue(variationKey, forKey: experimentKey)
        } else {
            forcedVariations?.removeValue(forKey: experimentKey)
        }
    }
    
    func addForcedFeatureEnabled(featureKey: String, enabled: Bool?) {
        if let enabled = enabled {
            forcedFeatures?.updateValue(enabled, forKey: featureKey)
        } else {
            forcedFeatures?.removeValue(forKey: featureKey)
        }
    }
    
    func addAttributeValue(attributeKey: String, value: Any?) {
        if let value = value {
            attributes?.updateValue(value, forKey: attributeKey)
        } else {
            attributes?.removeValue(forKey: attributeKey)
        }
    }
}

#endif
