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

public enum OptimizelyError: Error {
    case generic

    // MARK: - SDK
    
    case sdkNotReady
    
    // MARK: - Experiment
    
    case experimentKeyInvalid(_ key: String)
    case experimentIdInvalid(_ id: String)
    case experimentHasNoTrafficAllocation(_ key: String)
    case featureKeyInvalid(_ key: String)
    case variationKeyInvalid(_ expKey: String, _ varKey: String)
    case variationIdInvalid(_ expKey: String, _ varKey: String)
    case variationUnknown(_ userId: String, _ key: String)
    case variableKeyInvalid(_ varKey: String, _ feature: String)
    case variableValueInvalid(_ key: String)
    case eventKeyInvalid(_ key: String)
    case eventBuildFailure(_ key: String)
    case eventTagsFormatInvalid
    case attributesKeyInvalid(_ key: String)
    case attributeValueInvalid(_ key: String)
    case attributeFormatInvalid
    case groupIdInvalid(_ id: String)
    case groupHasNoTrafficAllocation(_ key: String)
    case rolloutIdInvalid(_ id: String, _ feature: String)
    
    // MARK: - Audience Evaluation
    
    case conditionNoMatchingAudience(_ id: String)
    case conditionInvalidFormat(_ hint: String)
    case conditionCannotBeEvaluated(_ hint: String)
    case evaluateAttributeInvalidType(_ hint: String)
    case evaluateAttributeValueOutOfRange(_ hint: String)
    case evaluateAttributeInvalidFormat(_ hint: String)
    case userAttributeInvalidType(_ hint: String)
    case userAttributeInvalidMatch(_ hint: String)
    case userAttributeInvalidFormat(_ hint: String)

    // MARK: - Bucketing
    
    case userIdInvalid
    case bucketingIdInvalid(_ id: UInt64)
    case userProfileInvalid

    // MARK: - Datafile Errors
    
    case datafileDownloadFailed(_ hint: String)
    case dataFileInvalid
    case dataFileVersionInvalid(_ version: String)
    case datafileSavingFailed(_ hint: String)
    case datafileLoadingFailed(_ hint: String)

    // MARK: - EventDispatcher Errors
    
    case eventDispatchFailed(_ reason: String)
}

// MARK: - CustomStringConvertible

extension OptimizelyError: CustomStringConvertible {
    public var description: String {
        return "[Optimizely][Error] " + self.reason
    }
        
    public var localizedDescription: String {
        return description
    }

    var reason: String {
        var message: String
        
        switch self {
        case .generic:                                      message = "Unknown reason"
        case .sdkNotReady:                                  message = "Optimizely SDK not configured properly yet"
        case .experimentKeyInvalid(let key):                message = "Experiment key (\(key)) is not in datafile. It is either invalid, paused, or archived."
        case .experimentIdInvalid(let id):                  message = "Experiment ID (\(id)) is not in datafile."
        case .experimentHasNoTrafficAllocation(let key):    message = "No traffic allocation rules are defined for experiement (\(key))."
        case .featureKeyInvalid(let key):                   message = "Feature key (\(key)) is not in datafile."
        case .variationKeyInvalid(let expKey, let varKey):  message = "No variation key (\(varKey)) defined in datafile for experiment (\(expKey))."
        case .variationIdInvalid(let expKey, let varId):    message = "No variation ID (\(varId)) defined in datafile for experiment (\(expKey))."
        case .variationUnknown(let userId, let key):        message = "User (\(userId)) does not meet conditions to be in experiment/feature (\(key))."
        case .variableKeyInvalid(let varKey, let feature):  message = "Variable with key (\(varKey)) associated with feature with key (\(feature)) is not in datafile."
        case .variableValueInvalid(let key):                message = "Variable value for key (\(key)) is invalid or wrong type"
        case .eventKeyInvalid(let key):                     message = "Event key (\(key)) is not in datafile."
        case .eventBuildFailure(let key):                   message = "Failed to create a dispatch event (\(key))"
        case .eventTagsFormatInvalid:                       message = "Provided event tags are in an invalid format."
        case .attributesKeyInvalid(let key):                message = "Attribute key (\(key)) is not in datafile."
        case .attributeValueInvalid(let key):               message = "Attribute value for (\(key)) is invalid."
        case .attributeFormatInvalid:                       message = "Provided attributes are in an invalid format."
        case .groupIdInvalid(let id):                       message = "Group ID (\(id)) is not in datafile."
        case .groupHasNoTrafficAllocation(let id):          message = "No traffic allocation rules are defined for group (\(id))"
        case .rolloutIdInvalid(let id, let feature):        message = "Invalid rollout ID (\(id)) attached to feature (\(feature))"
            
        case .conditionNoMatchingAudience(let id):          message = "Audience (\(id)) is not in datafile."
        case .conditionInvalidFormat(let hint):             message = "Condition has an invalid format (\(hint))"
        case .conditionCannotBeEvaluated(let hint):         message = "Condition cannot be evaluated (\(hint))"
        case .evaluateAttributeInvalidType(let hint):       message = "Evaluation attribute has an invalid value (\(hint))"
        case .evaluateAttributeValueOutOfRange(let hint):   message = "Evaluation attribute has a value out of range (\(hint))"
        case .evaluateAttributeInvalidFormat(let hint):     message = "Evaluation attribute has an invalid format (\(hint))"
        case .userAttributeInvalidType(let hint):           message = "UserAttribute has an invalid attribute type (\(hint))"
        case .userAttributeInvalidMatch(let hint):          message = "UserAttribute has an invalid match type (\(hint))"
        case .userAttributeInvalidFormat(let hint):         message = "UserAttribute has an invalid format (\(hint))"

        case .userIdInvalid:                                message = "Provided user ID is in an invalid format."
        case .bucketingIdInvalid (let id):                  message = "Invalid bucketing ID (\(id))"
        case .userProfileInvalid:                           message = "Provided user profile object is invalid."
            
        case .datafileDownloadFailed(let hint):             message = "Datafile download failed (\(hint))"
        case .dataFileInvalid:                              message = "Provided datafile is in an invalid format."
        case .dataFileVersionInvalid (let version):         message = "Provided datafile version (\(version)) is not supported."
        case .datafileSavingFailed(let hint):               message = "Datafile save failed (\(hint))"
        case .datafileLoadingFailed(let hint):              message = "Datafile load failed (\(hint))"
            
        case .eventDispatchFailed(let hint):                message = "Event dispatch failed (\(hint))"
        }
        
        return message
    }
}

// MARK: - LocalizedError (ObjC NSError)

extension OptimizelyError: LocalizedError {
    public var errorDescription: String? {
        return self.reason
    }
}
