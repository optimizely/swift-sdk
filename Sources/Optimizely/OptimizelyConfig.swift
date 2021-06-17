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
    var experimentRules: [OptimizelyExperiment] { get }
    var deliveryRules: [OptimizelyExperiment] { get }
    var variablesMap: [String: OptimizelyVariable] { get }
    
    @available(*, deprecated, message: "Use experimentRules and deliveryRules")
    var experimentsMap: [String: OptimizelyExperiment] { get }
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
        self.events = project.events

        // merge [typedAudiences, audiences] in ProjectConfig to a single audiences array.
        // typedAudiences has a higher priority.
        var audiences = project.typedAudiences ?? []
        project.audiences.forEach { oldAudience in
            if audiences.filter({ newAudience in newAudience.id == oldAudience.id }).isEmpty {
                guard oldAudience.id != "$opt_dummy_audience" else { return }
                audiences.append(oldAudience)
            }
        }
        self.audiences = audiences
        
        // update experiment data:
        // - copy feature's variable data to variables in all variations
        // - serialize experiment audiences to a string
        
        // prepare an audience [id: name] mapping for audicens serialization
        let audiencesMap = Dictionary(uniqueKeysWithValues: audiences.map { ($0.id, $0.name) })

        let updatedExperiments = projectConfig.allExperiments.map { experiment -> Experiment in
            let feature = project.featureFlags.filter({ $0.experimentIds.contains(experiment.id) }).first
            return updateExperiment(experiment: experiment, feature: feature, audiencesMap: audiencesMap)
        }
        
        let updatedRollouts = projectConfig.project.rollouts.map { rollout -> Rollout in
            let feature = project.featureFlags.filter({ $0.rolloutId == rollout.id }).first
            
            var rollout = rollout
            rollout.experiments = rollout.experiments.map { experiment in
                return updateExperiment(experiment: experiment, feature: feature, audiencesMap: audiencesMap)
            }
            return rollout
        }
        
        self.experimentsMap = makeExperimentsMap(project: project, experiments: updatedExperiments)
        self.featuresMap = makeFeaturesMap(project: project, experiments: updatedExperiments, rollouts: updatedRollouts)
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
    
    func makeFeaturesMap(project: Project, experiments: [Experiment], rollouts: [Rollout]) -> [String: FeatureFlag] {
        var map = [String: FeatureFlag]()
        project.featureFlags.forEach {
            var feature = $0
            
            let experiments = feature.experimentIds.compactMap { expId in
                return experiments.filter { $0.id == expId }.first
            }
            
            let rollout = rollouts.filter { $0.id == feature.rolloutId }.first
            
            feature.experimentsMap = {
                var map = [String: Experiment]()
                experiments.forEach {
                    map[$0.key] = $0
                }
                return map
            }()
                
            feature.variablesMap = {
                var map = [String: Variable]()
                feature.variables.forEach { featureVariable in
                    map[featureVariable.key] = Variable(id: featureVariable.id,
                                                        value: featureVariable.defaultValue ?? "",
                                                        key: featureVariable.key,
                                                        type: featureVariable.type)
                }
                return map
            }()
            
            feature.experimentRules = experiments
            feature.deliveryRules = rollout?.experiments ?? []
                        
            map[feature.key] = feature
        }
        return map
    }
    
    func updateExperiment(experiment: Experiment, feature: FeatureFlag?, audiencesMap: [String: String]) -> Experiment {
        var experiment = experiment
        
        experiment.serializeAudiences(with: audiencesMap)
        
        let variations: [Variation] = experiment.variations.map {
            var variation = $0
            
            guard let feature = feature else { return variation }

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
                        
            variation.variablesMap = {
                var map = [String: Variable]()
                variables.forEach({
                    // filter out invalid variables (from invalid datafiles)
                    if !($0.key.isEmpty) {
                        map[$0.key] = $0
                    }
                })
                return map
            }()

            return variation
        }
                
        experiment.variationsMap = {
            var map = [String: Variation]()
            variations.forEach {
                map[$0.key] = $0
            }
            return map
        }()

        return experiment
    }
    
    func findFeatureVariable(id: String, features: [FeatureFlag]) -> FeatureVariable? {
        for feature in features {
            return feature.variables.filter { $0.id == id }.first
        }
        return nil
    }
    
}
