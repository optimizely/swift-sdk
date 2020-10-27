//
/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

struct DecisionInfo {
    
    /// The decision type.
    let decisionType: Constants.DecisionType
    
    /// The experiment that the decision variation belongs to.
    var experiment: Experiment?
    
    /// The variation selected by the decision.
    var variation: Variation?
    
    // The source of the decision
    var source: String?
    
    /// The flag for which the decision has been made.
    var feature: FeatureFlag?
    
    /// The boolean value indicating the flag is enabled or not.
    var featureEnabled: Bool?
    
    /// The key of the requested flag variable.
    var variableKey: String?
    
    /// The type of the requested flag variable.
    var variableType: String?
    
    /// The value of the requested flag variable.
    var variableValue: Any?
    
    /// The map of all the requested flag variable values.
    var variableValues: [String: Any]?
    
    /// The ruleKey for the decision (for .flag type only).
    var ruleKey: String?
    
    /// The array of decision reason messages (for .flag type only).
    var reasons: [String]?
    
    /// The boolean value indicating an decision event has been sent for the decision (for .flag type only).
    var decisionEventDispatched: Bool
    
    init(decisionType: Constants.DecisionType,
         experiment: Experiment? = nil,
         variation: Variation? = nil,
         source: String? = nil,
         feature: FeatureFlag? = nil,
         featureEnabled: Bool? = nil,
         variableKey: String? = nil,
         variableType: String? = nil,
         variableValue: Any? = nil,
         variableValues: [String: Any]? = nil,
         ruleKey: String? = nil,
         reasons: [String]? = nil,
         decisionEventDispatched: Bool = false) {
        
        self.decisionType = decisionType
        self.experiment = experiment
        self.variation = variation
        self.source = source
        self.feature = feature
        self.featureEnabled = featureEnabled
        self.variableKey = variableKey
        self.variableType = variableType
        self.variableValue = variableValue
        self.variableValues = variableValues
        self.ruleKey = ruleKey
        self.reasons = reasons
        self.decisionEventDispatched = decisionEventDispatched
    }
    
    var toMap: [String: Any] {
        var decisionInfo = [String: Any]()
        
        switch decisionType {
        case .featureTest, .abTest:
            guard let experiment = experiment else { return decisionInfo }
            
            decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
            decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation?.key ?? NSNull()
            
        case .feature, .featureVariable, .allFeatureVariables:
            guard let feature = feature, let featureEnabled = featureEnabled else { return decisionInfo }
            
            decisionInfo[Constants.DecisionInfoKeys.feature] = feature.key
            decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = featureEnabled
            
            let decisionSource: Constants.DecisionSource = experiment != nil ? .featureTest : .rollout
            decisionInfo[Constants.DecisionInfoKeys.source] = source ?? decisionSource.rawValue
            
            var sourceInfo = [String: Any]()
            if let experiment = experiment, let variation = variation {
                sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
                sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation.key
            }
            decisionInfo[Constants.DecisionInfoKeys.sourceInfo] = sourceInfo
            
            // featureVariable
            
            if decisionType == .featureVariable {
                guard let variableKey = variableKey, let variableType = variableType, let variableValue = variableValue else {
                    return decisionInfo
                }
                
                decisionInfo[Constants.DecisionInfoKeys.variable] = variableKey
                decisionInfo[Constants.DecisionInfoKeys.variableType] = variableType
                decisionInfo[Constants.DecisionInfoKeys.variableValue] = variableValue
            } else if  decisionType == .allFeatureVariables {
                guard let variableValues = variableValues else {
                    return decisionInfo
                }
                decisionInfo[Constants.DecisionInfoKeys.variableValues] = variableValues
            }
            
        // Decide-APIs
            
        case .flag:
            guard let flagKey = feature?.key, let enabled = featureEnabled else { return decisionInfo }
            
            decisionInfo[Constants.DecisionInfoKeys.flagKey] = flagKey
            decisionInfo[Constants.DecisionInfoKeys.enabled] = enabled
            decisionInfo[Constants.DecisionInfoKeys.variables] = variableValues
            decisionInfo[Constants.DecisionInfoKeys.variationKey] = variation?.key
            decisionInfo[Constants.DecisionInfoKeys.ruleKey] = ruleKey
            decisionInfo[Constants.DecisionInfoKeys.reasons] = reasons
            decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] = decisionEventDispatched
        }
        
        return decisionInfo
    }

}
