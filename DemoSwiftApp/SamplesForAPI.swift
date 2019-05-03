//
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

extension AppDelegate {
    
    func samplesForAPI() {
        
        let attributes = ["country": "us"]
        let eventTags = ["price": "100"]

        if let variationKey = try? optimizely.activate(experimentKey: "experimentKey",
                                                      userId: "userId",
                                                      attributes: attributes) {
            print("[activate] \(variationKey)")
        }
        
        if let variationKey = try? optimizely.getVariationKey(experimentKey: "experimentKey",
                                                           userId: "userId",
                                                           attributes: attributes) {
            print("[getVariationKey] \(variationKey)")
        }
        
        if let variationKey = optimizely.getForcedVariation(experimentKey: "experimentKey", userId: "userId") {
            print("[getForcedVariation] \(variationKey)")
        }
        
        if optimizely.setForcedVariation(experimentKey: "experimentKey",
                                         userId: "userId",
                                         variationKey: "variationKey") {
            print("[setForcedVariation]")
        }
        
        do {
            let result = try optimizely.isFeatureEnabled(featureKey: "featureKey",
                                                          userId: "userId",
                                                          attributes: attributes)
            print("[isFeatureEnabled] \(result)")
        } catch {
            // error
        }
        
        if let value = try? optimizely.getFeatureVariableBoolean(featureKey: "featureKey",
                                                                 variableKey: "kBoolean",
                                                                 userId: "userId",
                                                                 attributes: attributes) {
            print("[getFeatureVariableBoolean] \(value)")
        }
        
        if let value = try? optimizely.getFeatureVariableDouble(featureKey: "featureKey",
                                                                 variableKey: "kDouble",
                                                                 userId: "userId",
                                                                 attributes: attributes) {
            print("[getFeatureVariableDouble] \(value)")
        }

        if let value = try? optimizely.getFeatureVariableInteger(featureKey: "featureKey",
                                                                 variableKey: "kInteger",
                                                                 userId: "userId",
                                                                 attributes: attributes) {
            print("[getFeatureVariableInteger] \(value)")
        }

        if let value = try? optimizely.getFeatureVariableString(featureKey: "featureKey",
                                                                 variableKey: "kString",
                                                                 userId: "userId",
                                                                 attributes: attributes) {
            print("[getFeatureVariableString] \(value)")
        }
        
        if let features = try? optimizely.getEnabledFeatures(userId: "userId", attributes: attributes) {
            print("[getEnabledFeatures] \(features)")
        }
        
        try? optimizely.track(eventKey: "eventKey", userId: "userId", attributes: attributes, eventTags: eventTags)
    }
    
    
}
