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

/** A data model of public project configuration
 
 ```
 public struct OptimizelyConfig {
    public let experimentsMap: [String: Experiment]
    public let featuresMap: [String: FeatureFlag]
 }
 
 public struct Experiment {
    let id: String
    let key: String
    let variationsMap: [String: Variation]
 }
 
 public struct Feature {
    let id: String
    let key: String
    let experimentsMap: [String: Experiment]
    let variablesMap: [String: Variable]
 }
 
 public struct Variation {
    let id: String
    let key: String
    let variablesMap: [String: Variable]
 }
 
 public struct Variable {
    let id: String
    let key: String
    let type: String
    let value: String
 }
 ```
 */

public struct OptimizelyConfig {
    public var experimentsMap: [String: Experiment] = [:]
    public var featureFlagsMap: [String: FeatureFlag] = [:]
    
    init(projectConfig: ProjectConfig) {
        guard let project = projectConfig.project else {
            return
        }
        
        // map [experiment] to [key: experiment]
        
        self.experimentsMap = projectConfig.experimentKeyMap.mapValues {
            // copy feature's variable data to variables in variations
            return updateVariableData(experiment: $0, features: project.featureFlags)
        }
        
        // map [feature] to [key: feature]
        
        var map = [String: FeatureFlag]()
        project.featureFlags.forEach {
            var feature = $0
            
            // create [experiment] from [experiment-id]
            
            feature.experiments = feature.experimentIds.compactMap { expId in
                let experimentsWithUpdatedVariables = self.experimentsMap.values
                return experimentsWithUpdatedVariables.filter { $0.id == expId }.first
            }
            
            map[feature.key] = feature
        }
        self.featureFlagsMap = map
    }
}

extension OptimizelyConfig {
    
    /// Copy {key, type} from FeatureVariable to variation variable data
    ///
    /// - Parameters:
    ///   - experiment: a given experiment
    ///   - features: all features for the current project
    /// - Returns: return an experiment copy with new variables data
    func updateVariableData(experiment: Experiment, features: [FeatureFlag]) -> Experiment {
        let variations: [Variation] = experiment.variations.map {
            var variation = $0
            
            variation.variables = variation.variables?.map {
                var variable = $0
                if let featureVariable = findFeatureVariable(id: variable.id, features: features) {
                    variable.key = featureVariable.key
                    variable.type = featureVariable.type
                }
                return variable
            }
            
            return variation
        }
        
        var experiment = experiment
        experiment.variations = variations
        return experiment
    }
    
    func findFeatureVariable(id: String, features: [FeatureFlag]) -> FeatureVariable? {
        for feature in features {
            return feature.variables.filter { $0.id == id }.first
        }
        return nil
    }
    
}
