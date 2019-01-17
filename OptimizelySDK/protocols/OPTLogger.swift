//
//  Logger.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

/**
 * These are the various Optimizely Log Levels.
 * Normally, when messages are logged with priority levels greater than the filter level, they will be suppressed.
 */

public enum OptimizelyLogLevel : Int {
    
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
}

/**
 * Any logger must implement these following methods.
 */
public protocol OPTLogger {

    /// The log level the Logger is initialized with.
    static var logLevel:OptimizelyLogLevel { get set }

    /// required init for logger
    init(level:OptimizelyLogLevel)
    /**
     Log a message at a certain level.
     - Parameter level: The priority level of the log.
     - Parameter message: The message to log.
     */
    func log(level: OptimizelyLogLevel, message: String)

}

extension OPTLogger {
    static public var logLevelNames:[String] {
        get {
            return ["OFF", "CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "VERBOSE", "ALL"]
        }
    }
}
