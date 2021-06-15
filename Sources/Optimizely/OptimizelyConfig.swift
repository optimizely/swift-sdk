//
// Copyright 2020-2021, Optimizely, Inc. and contributors
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

/// A data model of public project configuration

public protocol OptimizelyConfig {
    var environmentKey: String { get }
    var revision: String { get }
    var sdkKey: String { get }
    var experimentsMap: [String: OptimizelyExperiment] { get }
    var featuresMap: [String: OptimizelyFeature] { get }
    var attributes: [OptimizelyAttribute] { get }
    var audiences: [OptimizelyAudience] { get }
    var events: [OptimizelyEvent] { get }
}

public protocol OptimizelyExperiment {
    var id: String { get }
    var key: String { get }
    var audiences: String { get }
    var variationsMap: [String: OptimizelyVariation] { get }
}

public protocol OptimizelyFeature {
    var id: String { get }
    var key: String { get }
    var experimentsMap: [String: OptimizelyExperiment] { get }
    var variablesMap: [String: OptimizelyVariable] { get }
}

public protocol OptimizelyVariation {
    var id: String { get }
    var key: String { get }
    var featureEnabled: Bool? { get }
    var variablesMap: [String: OptimizelyVariable] { get }
}

public protocol OptimizelyVariable {
    var id: String { get }
    var key: String { get }
    var type: String { get }
    var value: String { get }
}

public protocol OptimizelyAttribute {
    var id: String { get }
    var key: String { get }
}

public protocol OptimizelyAudience {
    var id: String { get }
    var name: String { get }
    var conditions: String { get }
}

public protocol OptimizelyEvent {
    var id: String { get }
    var key: String { get }
    var experimentIds: [String] { get }
}

// MARK: - OptimizelyConfig Implementation

struct OptimizelyConfigImp: OptimizelyConfig {
    var environmentKey: String = ""
    var revision: String = ""
    var sdkKey: String = ""
    var experimentsMap: [String: OptimizelyExperiment] = [:]
    var featuresMap: [String: OptimizelyFeature] = [:]
    var attributes: [OptimizelyAttribute] = []
    var audiences: [OptimizelyAudience] = []
    var events: [OptimizelyEvent] = []

    init(projectConfig: ProjectConfig) {
        guard let project = projectConfig.project else { return }
        
        self.environmentKey = project.environmentKey ?? ""
        self.sdkKey = project.sdkKey ?? ""
        self.revision = project.revision
        self.attributes = project.attributes
        self.audiences = project.audiences
        self.events = project.events

        // copy feature's variable data to variables in all variations
        let updatedExperiments = projectConfig.allExperiments.map {
            return updateVariableData(experiment: $0, features: project.featureFlags)
        }
        
        self.experimentsMap = makeExperimentsMap(project: project, experiments: updatedExperiments)
        self.featuresMap = makeFeaturesMap(project: project, experiments: updatedExperiments)
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
    
    func makeFeaturesMap(project: Project, experiments: [Experiment]) -> [String: FeatureFlag] {
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
        guard let feature = features.filter({ $0.experimentIds.contains(experiment.id) }).first else {
            return experiment
        }

        let variations: [Variation] = experiment.variations.map {
            var variation = $0
            
            // Copy {key, type} from FeatureVariable to variation variable data
            
            let variables: [Variable] = feature.variables.map { featVariable in
                // by default, returns a copy of FeatureVariable
                var updated = Variable(featureVariable: featVariable)
                
                // updated with custom value for each variation
                if let featureEnabled = variation.featureEnabled, featureEnabled {
                    if let variable = variation.variables?.filter({ $0.id == featVariable.id }).first {
                        updated.value = variable.value
                    }
                }
                
                return updated
            }
            
            variation.variables = variables
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
