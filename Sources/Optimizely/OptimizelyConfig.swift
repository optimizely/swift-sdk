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

public struct OptimizelyConfig {
    public var experimentsMap = [String: Experiment]()
    public var featureFlagsMap = [String: FeatureFlag]()
    
    var project: Project!
    
    init(projectConfig: ProjectConfig) {
        guard let project = projectConfig.project else {
            return
        }
        
        self.project = project
        
        self.experimentsMap = projectConfig.experimentKeyMap
        
        var featuresMap = [String: FeatureFlag]()
        project.featureFlags.forEach {
            var feature = $0
            
            var experimientsMap = [String: Experiment]()
            feature.experimentIds.forEach { expId in
                if let experiment = projectConfig.getExperiment(id: expId) {
                    experimientsMap[experiment.key] = experiment
                }
            }
            feature.experimentsMap = experimientsMap
            
            featuresMap[feature.key] = feature
        }
        self.featureFlagsMap = featuresMap
        
        syncAllVariableData()
    }
    
    /// Find a FeatureVariable for a given id
    ///
    /// - Parameter id: FeatureVariable id
    /// - Returns: matching FeatureVariable
    func findFeatureVariable(id: String) -> FeatureVariable? {
        for feature in project.featureFlags {
            for variable in feature.variables where variable.id == id {
                return variable
            }
        }
        return nil
    }
    
    /// Copy {key, type} from FeatureVariable to variation variable data
    ///
    /// - Parameter experiment: experiment
    /// - Returns: return experiment copy with new varition/variable data
    func updateVariableData(experiment: Experiment) -> Experiment {
        let variations: [Variation] = experiment.variations.map {
            var variation = $0
            if let vars = variation.variables {
                variation.variables = vars.map {
                    var variable = $0
                    if let featureVariable = findFeatureVariable(id: variable.id) {
                        variable.key = featureVariable.key
                        variable.type = featureVariable.type
                    }
                    return variable
                }
            }
            return variation
        }
        
        var experiment = experiment
        experiment.variations = variations
        return experiment
    }
    
    /// Modify project data for convenience
    /// - copy FeatureVariable fields to variation variable data for all experiments
    mutating func syncAllVariableData() {
        experimentsMap = experimentsMap.mapValues {
            return updateVariableData(experiment: $0)
        }
        
        featureFlagsMap = featureFlagsMap.mapValues {
            var feature = $0
            feature.experimentsMap = feature.experimentsMap.mapValues {
                return updateVariableData(experiment: $0)
            }
            return feature
        }
    }

}
