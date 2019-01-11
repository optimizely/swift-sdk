//
//  OPTError.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/18/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public enum OPTError: Error {
    case generic
    case dataFileInvalid
    case dataFileVersionInvalid(String)
    case eventDispatcherInvalid
    case loggerInvalid
    case errorHandlerInvalid
    case experimentUnknown(String)
    case eventUnknown(String)
    case userProfileInvalid
    case eventNoExperimentAssociation(String)
    case attributeFormatInvalid
    case groupInvalid
    case variationUnknown(String)
    case eventTypeUnknown
    case trafficAllocationNotInRange
    case bucketingIdInvalid(UInt64)
    case trafficAllocationUnknown(UInt32)
    case configInvalid
    case httpRequestRetryFailure(String)
    case projectConfigInvalidAudienceCondition
}

extension OPTError: CustomStringConvertible {
    public var description: String {
        var message: String = "[Optimizely]"
        
        switch self {
        case .generic:                                  message += "Unknown reason"
        case .dataFileInvalid:                          message += "Provided 'datafile' is in an invalid format."
        case .dataFileVersionInvalid (let value):       message += "Provided 'datafile' version \(value) is not supported."
        case .eventDispatcherInvalid:                   message += "Provided 'event dispatcher' is in an invalid format."
        case .loggerInvalid:                            message += "Provided 'logger' is in an invalid format."
        case .errorHandlerInvalid:                      message += "Provided 'error handler' is in an invalid format."
        case .experimentUnknown (let expId):            message += "Experiment \(expId) is not in the datafile."
        case .eventUnknown (let eventKey):              message += "Event \(eventKey) is not in the datafile."
        case .userProfileInvalid:                       message += "Provided user profile object is invalid."
        case .eventNoExperimentAssociation (let eventKey):  message += "Event \(eventKey) is not associated with any running experiments."
        case .attributeFormatInvalid:                   message += "Attributes provided in invalid format."
        case .groupInvalid:                             message += "Provided group is not in datafile."
        case .variationUnknown (let variationId):       message += "Provided variation \(variationId) is not in datafile."
        case .eventTypeUnknown:                         message += "Provided event type is not in datafile."
        case .trafficAllocationNotInRange:              message += "Traffic allocation %ld is not in range."
        case .bucketingIdInvalid (let bucketId):        message += "Invalid bucketing ID: \(bucketId)"
        case .trafficAllocationUnknown (let bucketRange): message += "Traffic allocation \(bucketRange) is not in range."
        case .configInvalid:                            message += "Project config is nil or invalid."
        case .httpRequestRetryFailure (let reason):     message += "The max backoff retry has been exceeded. POST failed with error: \(reason)"
        case .projectConfigInvalidAudienceCondition:    message += "Invalid audience condition."
        }
        
        return message
    }
}
