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
@objc public protocol OPTLogger {

    /// The log level the Logger is initialized with.
    static var logLevel: OptimizelyLogLevel { get set }

    /**
     * Initialize a new Optimizely Logger instance.
     */
    init()

    /**
     Log a message at a certain level.
     - Parameter level: The priority level of the log.
     - Parameter message: The message to log.
     */
    func log(level: OptimizelyLogLevel, message: String)
    
}

extension OPTLogger {
    
    // MARK: - Utils
    
    func log(level: OptimizelyLogLevel, message: String?) {
        guard let message = message else { return }
        log(level: level, message: message)
    }

    func e(_ message: String) { log(level: .error, message: message) }
    func w(_ message: String) { log(level: .warning, message: message) }
    func i(_ message: String) { log(level: .info, message: message) }
    func d(_ message: String) { log(level: .debug, message: message) }

    // MARK: - Utils for LogMessage
    
    func e(_ message: LogMessage) { log(level: .error, message: message.description) }
    func w(_ message: LogMessage) { log(level: .warning, message: message.description) }
    func i(_ message: LogMessage) { log(level: .info, message: message.description) }
    func d(_ message: LogMessage) { log(level: .debug, message: message.description) }
    
    // MARK: - Utils for OptimizelyError log
    
    func e(_ error: OptimizelyError?) { log(level: .error, message: error?.reason) }
    func w(_ error: OptimizelyError?) { log(level: .warning, message: error?.reason) }
    func i(_ error: OptimizelyError?) { log(level: .info, message: error?.reason) }
    func d(_ error: OptimizelyError?) { log(level: .debug, message: error?.reason) }
    
}
