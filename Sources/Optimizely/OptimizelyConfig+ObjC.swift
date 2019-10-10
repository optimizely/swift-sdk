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


/// Objective-C interface for OptimizelyConfig

@objc(OptimizelyConfig)
public protocol ObjcOptimizelyConfig {
    var experimentsMap: [String: ObjcOptimizelyExperiment] { get }
    var featureFlagsMap: [String: ObjcOptimizelyFeatureFlag] { get }
}

@objc(OptimizelyExperiment)
public protocol ObjcOptimizelyExperiment {
    var id: String { get }
    var key: String { get }
    var variationsMap: [String: ObjcOptimizelyVariation] { get }
}

@objc(OptimizelyFeatureFlag)
public protocol ObjcOptimizelyFeatureFlag {
    var id: String { get }
    var key: String { get }
    var experimentsMap: [String: ObjcOptimizelyExperiment] { get }
    var variablesMap: [String: ObjcOptimizelyVariable] { get }
}

@objc(OptimizelyVariation)
public protocol ObjcOptimizelyVariation {
    var id: String { get }
    var key: String { get }
    var variablesMap: [String: ObjcOptimizelyVariable] { get }
}

@objc(OptimizelyVariable)
public protocol ObjcOptimizelyVariable {
    var id: String { get }
    var key: String { get }
    var type: String { get }
    var value: String { get }
}

// MARK: - Implementations for Objective-C support

class ObjcOptimizelyConfigImp: NSObject, ObjcOptimizelyConfig {
    public var experimentsMap: [String: ObjcOptimizelyExperiment]
    public var featureFlagsMap: [String: ObjcOptimizelyFeatureFlag]

    public init(_ optimizelyConfig: OptimizelyConfig) {
        self.experimentsMap = optimizelyConfig.experimentsMap.mapValues { ObjcExperiment($0) }
        self.featureFlagsMap = optimizelyConfig.featureFlagsMap.mapValues { ObjcFeatureFlag($0) }
    }
}

class ObjcExperiment: NSObject, ObjcOptimizelyExperiment {
    public let id: String
    public let key: String
    public let variationsMap: [String: ObjcOptimizelyVariation]
    
    init(_ experiment: OptimizelyExperiment) {
        self.id = experiment.id
        self.key = experiment.key
        self.variationsMap = experiment.variationsMap.mapValues { ObjcVariation($0) }
    }
}

class ObjcFeatureFlag: NSObject, ObjcOptimizelyFeatureFlag {
    public let id: String
    public let key: String
    public let experimentsMap: [String: ObjcOptimizelyExperiment]
    public let variablesMap: [String: ObjcOptimizelyVariable]
    
    init(_ featureFlag: OptimizelyFeatureFlag) {
        self.id = featureFlag.id
        self.key = featureFlag.key
        self.experimentsMap = featureFlag.experimentsMap.mapValues { ObjcExperiment($0) }
        self.variablesMap = featureFlag.variablesMap.mapValues { ObjcVariable($0) }
    }
}

class ObjcVariation: NSObject, ObjcOptimizelyVariation {
    public let id: String
    public let key: String
    public let variablesMap: [String: ObjcOptimizelyVariable]
    
    init(_ variation: OptimizelyVariation) {
        self.id = variation.id
        self.key = variation.key
        self.variablesMap = variation.variablesMap.mapValues { ObjcVariable($0) }
    }
}

class ObjcVariable: NSObject, ObjcOptimizelyVariable {
    public let id: String
    public let key: String
    public let type: String
    public let value: String
    
    init(_ variable: OptimizelyVariable) {
        self.id = variable.id
        self.key = variable.key
        self.type = variable.type
        self.value = variable.value
    }
    
    override public var description: String {
        return "('id': \(id), 'key': \(key), 'type': \(type), 'value': \(value)')"
    }
}
