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

/// A data model of public project configuration

public protocol OptimizelyConfig {
    var experimentsMap: [String: OptimizelyExperiment] { get }
    var featureFlagsMap: [String: OptimizelyFeatureFlag] { get }
}

public protocol OptimizelyExperiment {
    var id: String { get }
    var key: String { get }
    var variationsMap: [String: OptimizelyVariation] { get }
}

public protocol OptimizelyFeatureFlag {
    var id: String { get }
    var key: String { get }
    var experimentsMap: [String: OptimizelyExperiment] { get }
    var variablesMap: [String: OptimizelyVariable] { get }
}

public protocol OptimizelyVariation {
    var id: String { get }
    var key: String { get }
    var variablesMap: [String: OptimizelyVariable] { get }
}

public protocol OptimizelyVariable {
    var id: String { get }
    var key: String { get }
    var type: String { get }
    var value: String { get }
}

// MARK: - OptimizelyConfig Implementation

struct OptimizelyConfigImp: OptimizelyConfig {
    var experimentsMap: [String: OptimizelyExperiment] = [:]
    var featureFlagsMap: [String: OptimizelyFeatureFlag] = [:]
    
    init(projectConfig: ProjectConfig) {
        guard let project = projectConfig.project else { return }

        // copy feature's variable data to variables in all variations
        let updatedExperiments = projectConfig.allExperiments.map {
            return updateVariableData(experiment: $0, features: project.featureFlags)
        }
        
        self.experimentsMap = makeExperimentsMap(project: project, experiments: updatedExperiments)
        self.featureFlagsMap = makeFeatureFlagsMap(project: project, experiments: updatedExperiments)
    }
}

// MARK: - Utils

extension OptimizelyConfigImp {
    
    func makeExperimentsMap(project: Project, experiments: [Experiment]) -> [String: Experiment] {
        var map = [String: Experiment]()
        experiments.forEach {
            map[$0.key] = $0
        }
        return map
    }
    
    func makeFeatureFlagsMap(project: Project, experiments: [Experiment]) -> [String: FeatureFlag] {
        var map = [String: FeatureFlag]()
        project.featureFlags.forEach {
            var feature = $0
            
            // create [experiment] from [experiment-id]
            
            feature.experiments = feature.experimentIds.compactMap { expId in
                return experiments.filter { $0.id == expId }.first
            }
            
            map[feature.key] = feature
        }
        return map
    }
    
    func updateVariableData(experiment: Experiment, features: [FeatureFlag]) -> Experiment {
        let variations: [Variation] = experiment.variations.map {
            var variation = $0
            
            // Copy {key, type} from FeatureVariable to variation variable data

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


