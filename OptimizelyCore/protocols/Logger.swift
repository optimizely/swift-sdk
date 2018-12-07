//
//  Logger.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

/**
 * These are the various Optimizely Log Levels.
 * Normally, when messages are logged with priority levels greater than the filter level, they will be suppressed.
 */

enum OptimizelyLogLevel : Int {
    
    /// If the filter level is set to OptimizelyLogLevelOff, all log messages will be suppressed.
    case OptimizelyLogLevelOff = 0
    /// Any error that is causing a crash of the application.
    case OptimizelyLogLevelCritical = 1
    /// Any error that is not causing a crash of the application: unknown experiment referenced.
    case OptimizelyLogLevelError = 2
    /// Anything that can potentially cause problems: method will be deprecated.
    case OptimizelyLogLevelWarning = 3
    /// Useful information: Lifecycle events, successfully activated experiment, parsed datafile.
    case OptimizelyLogLevelInfo = 4
    /// Information diagnostically helpful: sending events, assigning buckets.
    case OptimizelyLogLevelDebug = 5
    /// Used for the most granular logging: method flows, variable values.
    case OptimizelyLogLevelVerbose = 6
    /// If the filter level is set to OptimizelyLogLevelAll, no log messages will be suppressed.
    case OptimizelyLogLevelAll = 7
}

/**
 * Any logger must implement these following methods.
 */
protocol Logger {

    /// The log level the Logger is initialized with.
    static var logLevel:OptimizelyLogLevel { get set }

    /**
     * Initialize a new Optimizely Logger instance.
     */
    static func createInstance(logLevel:OptimizelyLogLevel) -> Logger?

    /**
     Log a message at a certain level.
     @param message The message to log.
     @param level The priority level of the log.
     */
    func log(level: OptimizelyLogLevel, message: String)

}

extension Logger {
    static var logLevelNames:[String] {
        get {
            return ["OFF", "CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG", "VERBOSE", "ALL"]
        }
    }
}
