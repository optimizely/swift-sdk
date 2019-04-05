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
    case conditionNoAttributeValue(_ hint: String)

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
        return "[Optimizely][Error] " + self.reason
    }
        
    public var localizedDescription: String {
        return description
    }

    var reason: String {
        var message: String
        
        switch self {
        case .generic:                                      message = "Unknown reason"
            
        case .sdkNotConfigured:                             message = "(sdkNotConfigured) "
            
        case .experimentKeyInvalid(let hint):               message = "(experimentKeyInvalid(\(hint))) "
        case .experimentUnknown:                            message = "(experimentUnknown) "
        case .experimentNotParticipated:                    message = "(experimentNotParticipated) "
        case .experimentHasNoTrafficAllocation(let hint):   message = "(experimentHasNoTrafficAllocation(\(hint))) "
        case .featureKeyInvalid(let hint):                  message = "(featureKeyInvalid(\(hint))) "
        case .featureUnknown:                               message = "(featureUnknown) "
        case .variationKeyInvalid(let hint):                message = "(variationKeyInvalid(\(hint))) "
        case .variationUnknown:                             message = "(variationUnknown) "
        case .variableKeyInvalid(let hint):                 message = "(variableKeyInvalid(\(hint))) "
        case .variableUnknown:                              message = "(variableUnknown) "
        case .variableValueInvalid(let hint):               message = "(variableValueInvalid(\(hint))) "
        case .eventKeyInvalid(let hint):                    message = "(eventKeyInvalid(\(hint))) "
        case .eventUnknown:                                 message = "(eventUnknown) "
        case .attributesKeyInvalid(let hint):               message = "(attributesKeyInvalid(\(hint))) "
        case .attributeValueInvalid:                        message = "(attributeValueInvalid) "
        case .attributeFormatInvalid:                       message = "Attributes provided in invalid format."
        case .groupKeyInvalid(let hint):                    message = "(groupKeyInvalid(\(hint))) "
        case .groupUnknown:                                 message = "(groupUnknown) "
        case .groupHasNoTrafficAllocation(let hint):        message = "(groupHasNoTrafficAllocation(\(hint))) "
        case .rolloutKeyInvalid(let hint):                  message = "(rolloutKeyInvalid(\(hint))) "
        case .rolloutUnknown:                               message = "(rolloutUnknown) "
            
        case .trafficAllocationNotInRange:                  message = "Traffic allocation %ld is not in range."
        case .trafficAllocationUnknown:                     message = "(trafficAllocationUnknown) "
        case .eventNotAssociatedToExperiment(let hint):     message = "(eventNotAssociatedToExperiment(\(hint))) "
            
        case .conditionNoMatchingAudience(let hint):        message = "(conditionNoMatchingAudience(\(hint))) "
        case .conditionInvalidValueType(let hint):          message = "(conditionInvalidValueType(\(hint))) "
        case .conditionInvalidFormat(let hint):             message = "(conditionInvalidFormat(\(hint))) "
        case .conditionCannotBeEvaluated(let hint):         message = "(conditionCannotBeEvaluated(\(hint))) "
        case .conditionInvalidAttributeType(let hint):      message = "(conditionInvalidAttributeType(\(hint))) "
        case .conditionInvalidAttributeMatch(let hint):     message = "(conditionInvalidAttributeMatch(\(hint))) "
        case .conditionNoAttributeValue(let hint):          message = "(conditionNoAttributeValue(\(hint))) "
            
        case .userIdInvalid:                                message = "(userIdInvalid) "
        case .bucketingIdInvalid (let hint):                message = "Invalid bucketing ID: \(hint)"
        case .userProfileInvalid:                           message = "Provided user profile object is invalid."
            
        case .datafileDownloadFailed(let hint):             message = "(datafileDownloadFailed(\(hint))) "
        case .dataFileInvalid:                              message = "Provided 'datafile' is in an invalid format."
        case .dataFileVersionInvalid (let version):         message = "Provided 'datafile' version \(version) is not supported."
        case .datafileSavingFailed(let hint):               message = "(datafileSavingFailed(\(hint))) "
        case .datafileLoadingFailed(let hint):              message = "(datafileLoadingFailed(\(hint))) "
            
        case .eventDispatchFailed(let hint):                message = "(eventDispatchFailed(\(hint)) "
            
            
        case .notificationCallbackInvalid:                  message = "(notificationCallbackInvalid) "
        }
        
        return message
    }
}
