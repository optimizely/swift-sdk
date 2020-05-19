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

#if os(iOS) && (DEBUG || OPT_DBG)

import Foundation

extension OptimizelyClient {

    public func setUserContext(userId: String, attributes: OptimizelyAttributes?) {
        UserContextManager.setUserContext(userId: userId, attributes: attributes)
    }
    
    public func activate(experimentKey: String) throws -> String {
        guard let uc = UserContextManager.getUserContext() else { throw OptimizelyError.userIdInvalid }
        return try activate(experimentKey: experimentKey, userId: uc.userId, attributes: uc.attributes)
    }
        
    public func getVariationKey(experimentKey: String) throws -> String {
        guard let uc = UserContextManager.getUserContext() else { throw OptimizelyError.userIdInvalid }
        return try getVariationKey(experimentKey: experimentKey, userId: uc.userId, attributes: uc.attributes)
    }
    
    public func getForcedVariation(experimentKey: String) -> String? {
        guard let uc = UserContextManager.getUserContext() else { return nil }
        return getForcedVariation(experimentKey: experimentKey, userId: uc.userId)
    }
    
    public func setForcedVariation(experimentKey: String, variationKey: String?) -> Bool {
        guard let uc = UserContextManager.getUserContext() else { return false }
        return setForcedVariation(experimentKey: experimentKey, userId: uc.userId, variationKey: variationKey)
    }
    
    public func isFeatureEnabled(featureKey: String) -> Bool {
        guard let uc = UserContextManager.getUserContext() else { return false }
        return isFeatureEnabled(featureKey: featureKey, userId: uc.userId, attributes: uc.attributes)
    }
    
    public func getFeatureVariableBoolean(featureKey: String, variableKey: String) throws -> Bool {
        return try getFeatureVariable(featureKey: featureKey, variableKey: variableKey)
    }
    
    public func getFeatureVariableDouble(featureKey: String, variableKey: String) throws -> Double {
        return try getFeatureVariable(featureKey: featureKey, variableKey: variableKey)
    }
    
    public func getFeatureVariableInteger(featureKey: String, variableKey: String) throws -> Int {
        return try getFeatureVariable(featureKey: featureKey, variableKey: variableKey)
    }
    
    public func getFeatureVariableString(featureKey: String, variableKey: String) throws -> String {
        return try getFeatureVariable(featureKey: featureKey, variableKey: variableKey)
    }
    
    func getFeatureVariable<T>(featureKey: String, variableKey: String) throws -> T {
        guard let uc = UserContextManager.getUserContext() else { throw OptimizelyError.userIdInvalid }
        return try getFeatureVariable(featureKey: featureKey, variableKey: variableKey, userId: uc.userId, attributes: uc.attributes)
    }
    
    public func getEnabledFeatures() -> [String] {
        guard let uc = UserContextManager.getUserContext() else { return [] }
        return getEnabledFeatures(userId: uc.userId, attributes: uc.attributes)
    }
    
    public func track(eventKey: String, eventTags: OptimizelyEventTags? = nil) throws {
        guard let uc = UserContextManager.getUserContext() else { throw OptimizelyError.userIdInvalid }
        try track(eventKey: eventKey, userId: uc.userId, attributes: uc.attributes, eventTags: eventTags)
    }

}

#endif
