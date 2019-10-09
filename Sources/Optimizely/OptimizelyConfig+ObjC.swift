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
///
/// * {Experiment, FeatureFlag, Variation, Variable} are changed to class types
/// * Also all prepended by "Optimizely" to avoid name conflicts with possible usage of same-named objects in apps.

//@objc(OptimizelyConfig)
//@objcMembers public class ObjcOptimizelyConfig: NSObject {
//    public var experimentsMap: [String: OptimizelyExperiment]
//    public var featureFlagsMap: [String: OptimizelyFeatureFlag]
//
//    public init(_ optimizelyConfig: OptimizelyConfig) {
//        self.experimentsMap = optimizelyConfig.experimentsMap.mapValues { return OptimizelyExperiment($0) }
//        self.featureFlagsMap = optimizelyConfig.featureFlagsMap.mapValues { return OptimizelyFeatureFlag($0) }
//    }
//}
//
//@objcMembers public class OptimizelyExperiment: NSObject {
//    public let id: String
//    public let key: String
//    public let variationsMap: [String: OptimizelyVariation]
//    
//    init(_ experiment: Experiment) {
//        self.id = experiment.id
//        self.key = experiment.key
//        self.variationsMap = experiment.variationsMap.mapValues { return OptimizelyVariation($0) }
//    }
//}
//
//@objcMembers public class OptimizelyFeatureFlag: NSObject {
//    public let id: String
//    public let key: String
//    public let experimentsMap: [String: OptimizelyExperiment]
//    public let variablesMap: [String: OptimizelyVariable]
//    
//    init(_ featureFlag: FeatureFlag) {
//        self.id = featureFlag.id
//        self.key = featureFlag.key
//        self.experimentsMap = featureFlag.experimentsMap.mapValues { return OptimizelyExperiment($0) }
//        self.variablesMap = featureFlag.variablesMap.mapValues { return OptimizelyVariable($0) }
//    }
//}
//
//@objcMembers public class OptimizelyVariation: NSObject {
//    public let id: String
//    public let key: String
//    public let variablesMap: [String: OptimizelyVariable]
//    
//    init(_ variation: Variation) {
//        self.id = variation.id
//        self.key = variation.key
//        self.variablesMap = variation.variablesMap.mapValues { return OptimizelyVariable($0) }
//    }
//}
//
//@objcMembers public class OptimizelyVariable: NSObject {
//    public let id: String
//    public let key: String
//    public let type: String
//    public let value: String
//    
//    init(_ variable: Variable) {
//        self.id = variable.id
//        self.key = variable.key
//        self.type = variable.type
//        self.value = variable.value
//    }
//    
//    override public var description: String {
//        return "('id': \(id), 'key': \(key), 'type': \(type), 'value': \(value)')"
//    }
//}
