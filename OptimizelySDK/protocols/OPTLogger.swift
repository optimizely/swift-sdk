//
//  Logger.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation


/**
 * Any logger must implement these following methods.
 */
public protocol OPTLogger {

    /// The log level the Logger is initialized with.
    static var logLevel: OPTLogLevel { get set }

    /**
     * Initialize a new Optimizely Logger instance.
     */
    static func createInstance(logLevel:OPTLogLevel) -> OPTLogger?

    /**
     Log a message at a certain level.
     - Parameter level: The priority level of the log.
     - Parameter message: The message to log.
     */
    func log(level: OPTLogLevel, message: String)

}

