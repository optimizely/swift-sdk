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
import Optimizely

class SamplesForAPI {

    static func run(optimizely: OptimizelyClient) {

        let attributes: [String: Any] = [
            "device": "iPhone",
            "lifetime": 24738388,
            "is_logged_in": true
            ]
        let tags: [String: Any] = [
            "category": "shoes",
            "count": 2
            ]

        // MARK: - activate

        do {
            let variationKey = try optimizely.activate(experimentKey: "my_experiment_key",
                                                       userId: "user_123",
                                                       attributes: attributes)
            print("[activate] \(variationKey)")
        } catch {
            print(error)
        }

        // MARK: - getVariationKey

        do {
            let variationKey = try optimizely.getVariationKey(experimentKey: "my_experiment_key",
                                                              userId: "user_123",
                                                              attributes: attributes)
            print("[getVariationKey] \(variationKey)")
        } catch {
            print(error)
        }

        // MARK: - getForcedVariation

        if let variationKey = optimizely.getForcedVariation(experimentKey: "my_experiment_key", userId: "user_123") {
            print("[getForcedVariation] \(variationKey)")
        }

        // MARK: - setForcedVariation

        if optimizely.setForcedVariation(experimentKey: "my_experiment_key",
                                         userId: "user_123",
                                         variationKey: "some_variation_key") {
            print("[setForcedVariation]")
        }

        // MARK: - isFeatureEnabled

        let enabled = optimizely.isFeatureEnabled(featureKey: "my_feature_key",
                                                          userId: "user_123",
                                                          attributes: attributes)
        print("[isFeatureEnabled] \(enabled)")

        // MARK: - getFeatureVariable

        do {
            let featureVariableValue = try optimizely.getFeatureVariableDouble(featureKey: "my_feature_key",
                                                                               variableKey: "double_variable_key",
                                                                               userId: "user_123",
                                                                               attributes: attributes)
            print("[getFeatureVariableDouble] \(featureVariableValue)")
        } catch {
            print(error)
        }

        // MARK: - getEnabledFeatures

        let enabledFeatures = optimizely.getEnabledFeatures(userId: "user_123", attributes: attributes)
        print("[getEnabledFeatures] \(enabledFeatures)")

        // MARK: - track

        do {
            try optimizely.track(eventKey: "my_purchase_event_key", userId: "user_123", attributes: attributes, eventTags: tags)
            print("[track]")
        } catch {
            print(error)
        }
        
        // MARK: - OptimizelyConfig
        
        let optConfig = try! optimizely.getOptimizelyConfig()
        
        let experiments = optConfig.experimentsMap.values
        let experimentKeys = optConfig.experimentsMap.keys
        print("[OptimizelyConfig] all experiment keys = \(experimentKeys)")

        let features = optConfig.featureFlagsMap.values
        let featureKeys = optConfig.featureFlagsMap.keys
        print("[OptimizelyConfig] all feature keys = \(featureKeys)")

        // enumerate all experiments (variations, and associated variables)
        
        experimentKeys.forEach { expKey in
            print("[OptimizelyConfig] experimentKey = \(expKey)")
            
            let variationsMap = optConfig.experimentsMap[expKey]!.variationsMap
            let variationKeys = variationsMap.keys
            
            variationKeys.forEach { varKey in
                print("[OptimizelyConfig]   - variationKey = \(varKey)")
                
                let variablesMap = variationsMap[varKey]!.variablesMap
                let variableKeys = variablesMap.keys
                
                variableKeys.forEach { variableKey in
                    let variable = variablesMap[variableKey]!
                    
                    print("[OptimizelyConfig]       -- variable: \(variableKey), \(variable)")
                }
            }
        }
        
        // enumerate all features (experiments, variations, and assocated variables)
        
        featureKeys.forEach { featKey in
            print("[OptimizelyConfig] featureKey = \(featKey)")
            
            // enumerate feature experiments

            let experimentsMap = optConfig.featureFlagsMap[featKey]!.experimentsMap
            let experimentKeys = experimentsMap.keys
            
            experimentKeys.forEach { expKey in
                print("[OptimizelyConfig]   - experimentKey = \(expKey)")
                
                let variationsMap = experimentsMap[expKey]!.variationsMap
                let variationKeys = variationsMap.keys
                
                variationKeys.forEach { varKey in
                    print("[OptimizelyConfig]       -- variationKey = \(varKey)")
                    
                    let variablesMap = variationsMap[varKey]!.variablesMap
                    let variableKeys = variablesMap.keys
                    
                    variableKeys.forEach { variableKey in
                        let variable = variablesMap[variableKey]!
                        
                        print("[OptimizelyConfig]           --- variable: \(variableKey), \(variable)")
                    }
                }
            }
            
            // enumerate all feature-variables

            let variablesMap = optConfig.featureFlagsMap[featKey]!.variablesMap
            let variableKeys = variablesMap.keys
            
            variableKeys.forEach { variableKey in
                let variable = variablesMap[variableKey]!
                
                print("[OptimizelyConfig]       -- variable: \(variableKey), \(variable)")
            }
        }

    }

}
