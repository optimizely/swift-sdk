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

/// Objective-C interface for OptimizelyConfig

@objc(OptimizelyConfig)
public protocol ObjcOptimizelyConfig {
    var environmentKey: String { get }
    var revision: String { get }
    var sdkKey: String { get }
    var experimentsMap: [String: ObjcOptimizelyExperiment] { get }
    var featuresMap: [String: ObjcOptimizelyFeature] { get }
    var attributes: [ObjcOptimizelyAttribute] { get }
    var audiences: [ObjcOptimizelyAudience] { get }
    var events: [ObjcOptimizelyEvent] { get }
}

@objc(OptimizelyExperiment)
public protocol ObjcOptimizelyExperiment {
    var id: String { get }
    var key: String { get }
    var audiences: String { get }
    var variationsMap: [String: ObjcOptimizelyVariation] { get }
}

@objc(OptimizelyFeature)
public protocol ObjcOptimizelyFeature {
    var id: String { get }
    var key: String { get }
    var experimentRules: [ObjcOptimizelyExperiment] { get }
    var deliveryRules: [ObjcOptimizelyExperiment] { get }
    var variablesMap: [String: ObjcOptimizelyVariable] { get }
    
    @available(*, deprecated, message: "Use experimentRules and deliveryRules")
    var experimentsMap: [String: ObjcOptimizelyExperiment] { get }
}

@objc(OptimizelyVariation)
public protocol ObjcOptimizelyVariation {
    var id: String { get }
    var key: String { get }
    var featureEnabled: Bool { get }
    var variablesMap: [String: ObjcOptimizelyVariable] { get }
}

@objc(OptimizelyVariable)
public protocol ObjcOptimizelyVariable {
    var id: String { get }
    var key: String { get }
    var type: String { get }
    var value: String { get }
}

@objc(OptimizelyAttribute)
public protocol ObjcOptimizelyAttribute {
    var id: String { get }
    var key: String { get }
}

@objc(OptimizelyAudience)
public protocol ObjcOptimizelyAudience {
    var id: String { get }
    var name: String { get }
    var conditions: String { get }
}

@objc(OptimizelyEvent)
public protocol ObjcOptimizelyEvent {
    var id: String { get }
    var key: String { get }
    var experimentIds: [String] { get }
}

// MARK: - Implementations for Objective-C support

class ObjcOptimizelyConfigImp: NSObject, ObjcOptimizelyConfig {
    public var environmentKey: String
    public var revision: String
    public var sdkKey: String
    public var experimentsMap: [String: ObjcOptimizelyExperiment]
    public var featuresMap: [String: ObjcOptimizelyFeature]
    public var attributes: [ObjcOptimizelyAttribute] = []
    public var audiences: [ObjcOptimizelyAudience] = []
    public var events: [ObjcOptimizelyEvent] = []

    public init(_ optimizelyConfig: OptimizelyConfig) {
        self.environmentKey = optimizelyConfig.environmentKey
        self.revision = optimizelyConfig.revision
        self.sdkKey = optimizelyConfig.sdkKey
        self.experimentsMap = optimizelyConfig.experimentsMap.mapValues { ObjcExperiment($0) }
        self.featuresMap = optimizelyConfig.featuresMap.mapValues { ObjcFeature($0) }
        self.attributes = optimizelyConfig.attributes.map { ObjcAttribute($0) }
        self.audiences = optimizelyConfig.audiences.map { ObjcAudience($0) }
        self.events = optimizelyConfig.events.map { ObjcEvent($0) }
    }
}

class ObjcExperiment: NSObject, ObjcOptimizelyExperiment {
    public let id: String
    public let key: String
    public let audiences: String
    public let variationsMap: [String: ObjcOptimizelyVariation]
    
    init(_ experiment: OptimizelyExperiment) {
        self.id = experiment.id
        self.key = experiment.key
        self.audiences = experiment.audiences
        self.variationsMap = experiment.variationsMap.mapValues { ObjcVariation($0) }
    }
}

class ObjcFeature: NSObject, ObjcOptimizelyFeature {
    public let id: String
    public let key: String
    public let experimentRules: [ObjcOptimizelyExperiment]
    public let deliveryRules: [ObjcOptimizelyExperiment]
    public let experimentsMap: [String: ObjcOptimizelyExperiment]
    public let variablesMap: [String: ObjcOptimizelyVariable]

    init(_ feature: OptimizelyFeature) {
        self.id = feature.id
        self.key = feature.key
        self.experimentRules = feature.experimentRules.map { ObjcExperiment($0) }
        self.deliveryRules = feature.deliveryRules.map { ObjcExperiment($0) }
        
        let expKeyValuePair = feature.experimentRules.map { ($0.key, ObjcExperiment($0)) }
        self.experimentsMap = Dictionary(uniqueKeysWithValues: expKeyValuePair)

        self.variablesMap = feature.variablesMap.mapValues { ObjcVariable($0) }
    }
}

class ObjcVariation: NSObject, ObjcOptimizelyVariation {
    public let id: String
    public let key: String
    public let featureEnabled: Bool
    public let variablesMap: [String: ObjcOptimizelyVariable]
    
    init(_ variation: OptimizelyVariation) {
        self.id = variation.id
        self.key = variation.key
        self.featureEnabled = variation.featureEnabled ?? false
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

class ObjcAttribute: NSObject, ObjcOptimizelyAttribute {
    public let id: String
    public let key: String
    
    init(_ attribute: OptimizelyAttribute) {
        self.id = attribute.id
        self.key = attribute.key
    }
}

class ObjcAudience: NSObject, ObjcOptimizelyAudience {
    public let id: String
    public let name: String
    public let conditions: String

    init(_ audience: OptimizelyAudience) {
        self.id = audience.id
        self.name = audience.name
        self.conditions = audience.conditions
    }
}

class ObjcEvent: NSObject, ObjcOptimizelyEvent {
    public let id: String
    public let key: String
    public let experimentIds: [String]

    init(_ event: OptimizelyEvent) {
        self.id = event.id
        self.key = event.key
        self.experimentIds = event.experimentIds
    }
}
