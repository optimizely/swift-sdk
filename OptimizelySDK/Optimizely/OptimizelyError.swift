//
//  OptimizelyError.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/18/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public enum OptimizelyError: Error {
    case generic
    case sdkNotConfigured
    
    // MARK: - Experiment
    
    case experimentKeyInvalid(_ key: String)
    case experimentUnknown
    case experimentNotParticipated
    case experimentHasNoTrafficAllocation(_ key: String)
    case featureKeyInvalid(_ key: String)
    case featureUnknown
    case variationKeyInvalid(_ key: String)
    case variationUnknown
    case variableKeyInvalid(_ key: String)
    case variableUnknown
    case variableValueInvalid(_ key: String)
    case eventKeyInvalid(_ key: String)
    case eventUnknown
    case attributesKeyInvalid(_ key: String)
    case attributeValueInvalid
    case attributeFormatInvalid
    case groupKeyInvalid(_ key: String)
    case groupUnknown
    case groupHasNoTrafficAllocation(_ key: String)
    case rolloutKeyInvalid(_ key: String)
    case rolloutUnknown
    
    case trafficAllocationNotInRange
    case trafficAllocationUnknown
    case eventNotAssociatedToExperiment(_ key: String)

    // MARK: - Audience Conditions
    
    case conditionNoMatchingAudience(_ hint: String)
    case conditionInvalidValueType(_ hint: String)
    case conditionInvalidFormat(_ hint: String)
    case conditionCannotBeEvaluated(_ hint: String)
    case conditionInvalidAttributeType(_ hint: String)
    case conditionInvalidAttributeMatch(_ hint: String)

    // MARK: - Bucketing
    
    case userIdInvalid
    case bucketingIdInvalid(_ id: UInt64)
    case userProfileInvalid

    // MARK: - Datafile Errors
    
    case datafileDownloadFailed(_ reason: String)
    case dataFileInvalid
    case dataFileVersionInvalid(_ version: String)
    case datafileSavingFailed(_ sdkKey: String)
    case datafileLoadingFailed(_ sdkKey: String)

    // MARK: - EventDispatcher Errors
    
    case eventDispatchFailed(_ reason: String)
    
    // MARK: - Notifications
    
    case notificationCallbackInvalid
}

extension OptimizelyError: CustomStringConvertible {
    public var description: String {
        var message: String = "[Optimizely][Error]"
        
        switch self {
        case .generic:                                  message += "Unknown reason"
            
        case .sdkNotConfigured:                         message += " (sdkNotConfigured) "
            
        case .experimentKeyInvalid(_):                  message += " (experimentKeyInvalid(_)) "
        case .experimentUnknown:                        message += " (experimentUnknown) "
        case .experimentNotParticipated:                message += " (experimentNotParticipated) "
        case .experimentHasNoTrafficAllocation(_):      message += " (experimentHasNoTrafficAllocation(_)) "
        case .featureKeyInvalid(_):                     message += " (featureKeyInvalid(_)) "
        case .featureUnknown:                           message += " (featureUnknown) "
        case .variationKeyInvalid(_):                   message += " (variationKeyInvalid(_)) "
        case .variationUnknown:                         message += " (variationUnknown) "
        case .variableKeyInvalid(_):                    message += " (variableKeyInvalid(_)) "
        case .variableUnknown:                          message += " (variableUnknown) "
        case .variableValueInvalid(_):                  message += " (variableValueInvalid(_)) "
        case .eventKeyInvalid(_):                       message += " (eventKeyInvalid(_)) "
        case .eventUnknown:                             message += " (eventUnknown) "
        case .attributesKeyInvalid(_):                  message += " (attributesKeyInvalid(_)) "
        case .attributeValueInvalid:                    message += " (attributeValueInvalid) "
        case .attributeFormatInvalid:                   message += "Attributes provided in invalid format."
        case .groupKeyInvalid(_):                       message += " (groupKeyInvalid(_)) "
        case .groupUnknown:                             message += " (groupUnknown) "
        case .groupHasNoTrafficAllocation(_):           message += " (groupHasNoTrafficAllocation(_)) "
        case .rolloutKeyInvalid(_):                     message += " (rolloutKeyInvalid(_)) "
        case .rolloutUnknown:                           message += " (rolloutUnknown) "
            
        case .trafficAllocationNotInRange:              message += "Traffic allocation %ld is not in range."
        case .trafficAllocationUnknown:  message += " (trafficAllocationUnknown) "
        case .eventNotAssociatedToExperiment(_):  message += " (eventNotAssociatedToExperiment(_)) "
            
        case .conditionNoMatchingAudience(_):  message += " (conditionNoMatchingAudience(_)) "
        case .conditionInvalidValueType(_):  message += " (conditionInvalidValueType(_)) "
        case .conditionInvalidFormat(_):  message += " (conditionInvalidFormat(_)) "
        case .conditionCannotBeEvaluated(_):  message += " (conditionCannotBeEvaluated(_)) "
        case .conditionInvalidAttributeType(_):  message += " (conditionInvalidAttributeType(_)) "
        case .conditionInvalidAttributeMatch(_):  message += " (conditionInvalidAttributeMatch(_)) "
            
        case .userIdInvalid:  message += " (userIdInvalid) "
        case .bucketingIdInvalid (let id):              message += "Invalid bucketing ID: \(id)"
        case .userProfileInvalid:                       message += "Provided user profile object is invalid."

        case .datafileDownloadFailed(_):  message += " (datafileDownloadFailed(_)) "
        case .dataFileInvalid:                          message += "Provided 'datafile' is in an invalid format."
        case .dataFileVersionInvalid (let version):     message += "Provided 'datafile' version \(version) is not supported."
        case .datafileSavingFailed(_):  message += " (datafileSavingFailed(_)) "
        case .datafileLoadingFailed(_):  message += " (datafileLoadingFailed(_)) "
            
        case .eventDispatchFailed(_):  message += " (eventDispatchFailed(_)) "
            
            
        case .notificationCallbackInvalid:  message += " (notificationCallbackInvalid) "

        }
        
        return message
    }
    
    public var localizedDescription: String {
        return description
    }
}
