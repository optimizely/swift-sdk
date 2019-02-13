//
//  OptimizelyLogLevel.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 1/17/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

@objc public enum OptimizelyLogLevel : Int {
    
    /// If the filter level is set to OptimizelyLogLevelOff, all log messages will be suppressed.
    case off = 0
    /// Any error that is causing a crash of the application.
    case critical = 1
    /// Any error that is not causing a crash of the application: unknown experiment referenced.
    case error = 2
    /// Anything that can potentially cause problems: method will be deprecated.
    case warning = 3
    /// Useful information: Lifecycle events, successfully activated experiment, parsed datafile.
    case info = 4
    /// Information diagnostically helpful: sending events, assigning buckets.
    case debug = 5
    /// Used for the most granular logging: method flows, variable values.
    case verbose = 6
    /// If the filter level is set to OptimizelyLogLevelAll, no log messages will be suppressed.
    case all = 7
    
    // NOTE: this property is not converted for ObjC APIs (separate map should be defined for ObjC-client customization)
    public var name: String {
        switch self {
        case .off:          return "OFF"
        case .critical:     return "CRITICAL"
        case .error:        return "ERROR"
        case .warning:      return "WARNING"
        case .info:         return "INFO"
        case .debug:        return "DEBUG"
        case .verbose:      return "VERBOSE"
        case .all:          return "ALL"
        }
    }
}
