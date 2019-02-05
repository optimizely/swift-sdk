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
    
    // MARK: - Experiment
    
    case experimentKeyInvalid(_ key: String)
    case experimentUnknown
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
    case attributeFormatInvalid
    case groupKeyInvalid(_ key: String)
    case groupUnknown
    case groupHasNoTrafficAllocation(_ key: String)
    case rolloutKeyInvalid(_ key: String)
    case rolloutUnknown

    case trafficAllocationNotInRange
    case trafficAllocationUnknown
    case eventNotAssociatedToExperiment(_ key: String)

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
        var message: String = "[Optimizely]"
        
        switch self {
        case .generic:                                  message += "Unknown reason"
        case .dataFileInvalid:                          message += "Provided 'datafile' is in an invalid format."
        case .dataFileVersionInvalid (let version):     message += "Provided 'datafile' version \(version) is not supported."
        case .userProfileInvalid:                       message += "Provided user profile object is invalid."
        case .attributeFormatInvalid:                   message += "Attributes provided in invalid format."
        case .trafficAllocationNotInRange:              message += "Traffic allocation %ld is not in range."
        case .bucketingIdInvalid (let id):              message += "Invalid bucketing ID: \(id)"
        default: message += "TO BE DEFINED"
        }
        
        return message
    }
    
    public var localizedDescription: String {
        return description
    }
}
