//
//  OPTManager.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/19/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation


open class OPTManager: NSObject {
    
    // MARK: - Properties
    
    var sdkKey: String
    var config:OPTProjectConfig!
    
    // MARK: - Customizable
    
    let logger: OPTLogger
    let bucketer: OPTBucketer
    let decisionService: OPTDecisionService
    let eventDispatcher: OPTEventDispatcher
    let datafileHandler: OPTDatafileHandler
    let userProfileService: OPTUserProfileService
    let notificationCenter: OPTNotificationCenter
    let periodicDownloadInterval: Int
    
    // MARK: - Public interfaces
    
    /// Initialize Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - bucketer: custom Bucketer
    ///   - ...
    public init(sdkKey: String,
                logger:OPTLogger? = nil,
                bucketer:OPTBucketer? = nil,
                decisionService:OPTDecisionService? = nil,
                eventDispatcher:OPTEventDispatcher? = nil,
                datafileHandler:OPTDatafileHandler? = nil,
                userProfileService:OPTUserProfileService? = nil,
                notificationCenter:OPTNotificationCenter? = nil,
                periodicDownloadInterval:Int? = nil) {
        
        self.sdkKey = sdkKey
        
        // default services (can be customized by clients
        self.logger = logger ?? DefaultLogger(level: .error)
        self.eventDispatcher = eventDispatcher ?? DefaultEventDispatcher()
        self.datafileHandler = datafileHandler ?? DefaultDatafileHandler()
        self.userProfileService = userProfileService ?? DefaultUserProfileService()
        self.notificationCenter = notificationCenter ?? DefaultNotificationCenter()
        self.bucketer = bucketer ?? DefaultBucketer()
        self.decisionService = decisionService ?? DefaultDecisionService()
        self.periodicDownloadInterval = periodicDownloadInterval ?? (5 * 60)
    }
    
    /// Initialize Optimizely Manager
    ///
    /// - Parameters:
    ///   - datafile: when given, this datafile will be used when cached copy is not available (fresh start)
    ///                       a cached copy from previous download is used if it's available
    ///                       the datafile will be updated from the server in the background thread
    ///   - completion: callback when initialization is completed
    public func initializeSDK(completion: ((OPTResult<Data>) -> Void)?=nil) {
        
        fetchDatafileBackground() { result in
            switch result {
            case .failure:
                completion?(result)
            case .success(let datafile):
                do {
                    try self.configSDK(datafile: datafile)
                    completion?(result)
                } catch {
                    
                    // TODO: refine error-type
                    completion?(.failure(.configInvalid))
                }
            }
        }
    }
    
    // MARK: synchronous initialization
    
    @objc public func initializeSDK(datafile: String) throws {
        guard let datafileData = datafile.data(using: .utf8) else {
            throw OPTError.dataFileInvalid
        }
        
        try initializeSDK(datafile: datafileData)
    }
    
    public func initializeSDK(datafile: Data) throws {
        
        // TODO: get the cached copy
        let cachedDatafile: Data? = self.datafileHandler.isDatafileSaved(sdkKey: self.sdkKey) ? self.datafileHandler.loadSavedDatafile(sdkKey: self.sdkKey) : nil

        let selectedDatafile = cachedDatafile ?? datafile
        
        do {
            try configSDK(datafile: selectedDatafile)
        } catch {
            
            // TODO:  refine error-type
            throw OPTError.dataFileInvalid
        }
        
        fetchDatafileBackground()
    }
    
    func configSDK(datafile: String) throws {
        guard let datafileData = datafile.data(using: .utf8) else {
            throw OPTError.dataFileInvalid
        }
        
        try configSDK(datafile: datafileData)
    }
    
    func configSDK(datafile: Data) throws {
        do {
            self.config = try JSONDecoder().decode(OPTProjectConfig.self, from: datafile)
            
            bucketer.initialize(config: self.config)
            decisionService.initialize(config: self.config,
                                       bucketer: self.bucketer,
                                       userProfileService: self.userProfileService)
        } catch is DecodingError {
            throw OPTError.dataFileInvalid
        } catch is OPTError {
            // TODO: refine error-type
            throw OPTError.dataFileInvalid
        }
     }
    
    func fetchDatafileBackground(completion: ((OPTResult<Data>) -> Void)?=nil) {
        datafileHandler.downloadDatafile(sdkKey: self.sdkKey){ result in
            var fetchResult: OPTResult<Data>

            switch result {
            case .failure(let err):
                self.logger.log(level: .error, message: err.description)
                // TODO: refine error-type
                fetchResult = .failure(.generic)
            case .success(let datafile):
                fetchResult = .success(datafile)
            }
            
            completion?(fetchResult)
        }
    }

        
    /**
     * Use the activate method to start an experiment.
     *
     * The activate call will conditionally activate an experiment for a user based on the provided experiment key and a randomized hash of the provided user ID.
     * If the user satisfies audience conditions for the experiment and the experiment is valid and running, the function returns the variation the user is bucketed into.
     * Otherwise, activate returns nil. Make sure that your code adequately deals with the case when the experiment is not activated (e.g. execute the default variation).
     */
    
    /// Try to activate an experiment based on the experiment key and user ID with user attributes.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: The variation key the user was bucketed into
    /// - Throws: `OPTError` if error is detected
    @objc public func activate(experimentKey:String,
                         userId:String,
                         attributes:Dictionary<String, Any>?=nil) throws -> String {
        
        guard let experiment = config.experiments.filter({$0.key == experimentKey}).first else {
            // TODO: refine error type
            throw OPTError.experimentUnknown(experimentKey)
        }
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        
        // TODO: fix for error handling
        guard let body = BatchEventBuilder.createImpressionEvent(config: config,
                                                                 decisionService: decisionService,
                                                                 experiment: experiment,
                                                                 varionation: variation,
                                                                 userId: userId,
                                                                 attributes: attributes) else
        {
            // TODO: refine error type
            throw OPTError.eventUnknown(experimentKey)
        }
        
        let event = EventForDispatch(body: body)
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure(let error):
                self.logger.log(level: .error, message: "Failed to dispatch event " + error.localizedDescription)
            case .success( _):
                self.notificationCenter.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any, "body":event.body as Any]])
            }
        }
        
        return variation.key
    }
    
    /// Get variation for experiment and user ID with user attributes.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: The variation key the user was bucketed into
    /// - Throws: `OPTError` if error is detected
    public func getVariationKey(experimentKey:String,
                                userId:String,
                                attributes:Dictionary<String, Any>?=nil) throws -> String {
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        return variation.key
    }
    
    func getVariation(experimentKey:String,
                      userId:String,
                      attributes:Dictionary<String, Any>?=nil) throws -> OPTVariation {
        
        if let experiment = config?.experiments.filter({$0.key == experimentKey}).first,
            let variation = decisionService.getVariation(userId: userId, experiment: experiment, attributes: attributes ?? [:]) {
            return variation
        }
        
        // TODO: refine errors
        
        throw OPTError.attributeFormatInvalid
    }

    
    /**
     * Use the setForcedVariation method to force an experimentKey-userId
     * pair into a specific variation for QA purposes.
     * The forced bucketing feature allows customers to force users into
     * variations in real time for QA purposes without requiring datafile
     * downloads from the network. Methods activate and track are called
     * as usual after the variation is set, but the user will be bucketed
     * into the forced variation overriding any variation which would be
     * computed via the network datafile.
     */
    
    /// Get forced variation for experiment and user ID.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    /// - Returns: forced variation key if it exists, otherwise return nil.
    /// - Throws: `OPTError` if error is detected
    public func getForcedVariation(experimentKey:String, userId:String) throws -> String? {
        guard let experiment = config.experiments.filter({$0.key == experimentKey}).first else {
            // TODO: refine error-type
            throw OPTError.experimentUnknown(experimentKey)
        }
        
        guard let dict = config.whitelistUsers[userId],
            let variationKey = dict[experimentKey] else
        {
            return nil
        }
        
        guard let variation = experiment.variations.filter({$0.key == variationKey}).first else {
            // TODO: refine error-type
            throw OPTError.variationUnknown(variationKey)
        }
        
        return variation.key
    }
        

    /// Set forced variation for experiment and user ID to variationKey.
    ///
    /// - Parameters:
    ///   - experimentKey The key for the experiment.
    ///   - userId The user ID to be used for bucketing.
    ///   - variationKey The variation the user should be forced into.
    ///                  This value can be nil, in which case, the forced variation is cleared.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func setForcedVariation(experimentKey:String,
                                   userId:String,
                                   variationKey:String?) throws {
        
        guard let _ = config.experiments.filter({$0.key == experimentKey}).first else {
            // TODO: refine error-type
            throw OPTError.experimentUnknown(experimentKey)
        }
        
        guard var variationKey = variationKey else
        {
            config.whitelistUsers[userId]?.removeValue(forKey: experimentKey)
            return
        }
        
        variationKey = variationKey.trimmingCharacters(in: NSCharacterSet.whitespaces)
        
        guard !variationKey.isEmpty else {
            // TODO: refine error-type
            throw OPTError.variationUnknown(variationKey)
        }

        var whitelist = config.whitelistUsers[userId] ?? [:]
        whitelist[experimentKey] = variationKey
        config.whitelistUsers[userId] = whitelist
    }
    
    /// Determine whether a feature is enabled.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: true if feature is enabled, false otherwise.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func isFeatureEnabled(featureKey: String,
                                 userId: String,
                                 attributes: Dictionary<String,Any>?=nil) throws -> Bool {
        guard let featureFlag = config.featureFlags?.filter({$0.key == featureKey}).first  else {
            
            // TODO: is this error?
            return false
        }
        
        guard let pair = decisionService.getVariationForFeature(featureFlag: featureFlag, userId: userId, attributes: attributes ?? [:]),
            let experiment = pair.experiment,
            let variation = pair.variation else
        {
            // TODO: refine error-type
            throw OPTError.variationUnknown(featureKey)
        }
        
        guard let featureEnabled = variation.featureEnabled else {
            // TODO: refine error-type (what does nil-featureEnabled mean?)
            throw OPTError.generic
        }
    
        // TODO: fix for error handling
        guard let body = BatchEventBuilder.createImpressionEvent(config: config,
                                                                 decisionService: decisionService,
                                                                 experiment: experiment,
                                                                 varionation: variation,
                                                                 userId: userId,
                                                                 attributes: attributes) else
        {
            // TODO: refine error type
            throw OPTError.eventUnknown(experiment.key)
        }

        let event = EventForDispatch(body: body)
        
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure(let error):
                self.logger.log(level: .error, message: "Failed to dispatch event " + error.localizedDescription)
            case .success(_):
                self.notificationCenter.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any, "body":event.body as Any]])
            }
        }
        
        return featureEnabled
    }
    
    /// Gets boolean feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - variableKey The key for the variable.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: feature variable value of type boolean.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func getFeatureVariableBoolean(featureKey:String,
                                          variableKey:String,
                                          userId:String,
                                          attributes:Dictionary<String, Any>?=nil) throws -> Bool {
        
        return try getFeatureVariable(featureKey: featureKey,
                                                variableKey: variableKey,
                                                userId: userId,
                                                attributes: attributes)
    }
    
    /// Gets double feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - variableKey The key for the variable.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: feature variable value of type double.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func getFeatureVariableDouble(featureKey:String,
                                         variableKey:String,
                                         userId:String,
                                         attributes:Dictionary<String, Any>?=nil) throws -> Double {
        
        return try getFeatureVariable(featureKey: featureKey,
                                                variableKey: variableKey,
                                                userId: userId,
                                                attributes: attributes)
    }
    
    /// Gets integer feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - variableKey The key for the variable.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: feature variable value of type integer.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func getFeatureVariableInteger(featureKey:String,
                                          variableKey:String,
                                          userId:String,
                                          attributes:Dictionary<String, Any>?=nil) throws -> Int {
        
        return try getFeatureVariable(featureKey: featureKey,
                                                   variableKey: variableKey,
                                                   userId: userId,
                                                   attributes: attributes)
    }
    
    /// Gets string feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - variableKey The key for the variable.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: feature variable value of type string.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func getFeatureVariableString(featureKey: String,
                                         variableKey: String,
                                         userId: String,
                                         attributes: Dictionary<String, Any>?=nil) throws -> String {
        
        return try getFeatureVariable(featureKey: featureKey,
                                                           variableKey: variableKey,
                                                           userId: userId,
                                                           attributes: attributes)
    }
    
    func getFeatureVariable<T>(featureKey: String,
                            variableKey: String,
                            userId: String,
                            attributes: Dictionary<String, Any>?=nil) throws -> T {
        
        guard let featureFlag = config.featureFlags?.filter({$0.key == featureKey}).first else {
            // TODO: refine error-type
            throw OPTError.generic
        }
        
        guard let variable = featureFlag.variables?.filter({$0.key == variableKey}).first else {
            // TODO: refine error-type
            throw OPTError.generic
        }
        
        guard let defaultValueString = variable.defaultValue else {
            // TODO: refine error-type
            throw OPTError.generic
        }

        var typeName: String
        var value: T
        
        switch T.self {
        case is String.Type:
            typeName = "string"
            value = defaultValueString as! T
        case is Int.Type:
            typeName = "integer"
            value = Int(defaultValueString) as! T
        case is Double.Type:
            typeName = "double"
            value = Double(defaultValueString) as! T
        case is Bool.Type:
            typeName = "boolean"
            value = Bool(defaultValueString) as! T
        default:
            // TODO: refine error-type
            throw OPTError.generic
        }
        
        guard variable.type == typeName else {
            // TODO: refine error-type
            throw OPTError.generic
        }
        
        return value
    }

    
    /// Get array of features that are enabled for the user.
    ///
    /// - Parameters:
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: Array of feature keys that are enabled for the user.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func getEnabledFeatures(userId:String,
                                   attributes:Dictionary<String,Any>?=nil) throws -> Array<String> {

        guard let featureFlags = config.featureFlags else {
            // TODO: refine error type
            throw OPTError.generic
        }
        
        let enabledFeatures = try featureFlags.filter{
            try isFeatureEnabled(featureKey: $0.key, userId: userId, attributes: attributes)
        }
        
        return enabledFeatures.map{$0.key}
    }
    
    /// Track an event
    ///
    /// - Parameters:
    ///   - eventKey: The event name
    ///   - userId: The user ID associated with the event to track
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
    /// - Throws: `OPTError` if event parameter is not valid
    @objc public func track(eventKey:String,
                      userId:String,
                      attributes:Dictionary<String,Any>?=nil,
                      eventTags:Dictionary<String,Any>?=nil) throws {
        
        // TODO: fix for error handling
        guard let body = BatchEventBuilder.createConversionEvent(config: config,
                                                                 decisionService: decisionService,
                                                                 eventKey:eventKey,
                                                                 userId:userId,
                                                                 attributes:attributes,
                                                                 eventTags:eventTags) else
        {
            // TODO: refine error type
            throw OPTError.eventUnknown(eventKey)
        }
        
        let event = EventForDispatch(body: body)
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure(let error):
                self.logger.log(level: .error, message: "Failed to dispatch event " + error.localizedDescription)
            case .success( _):
                
                // TODO: clean up notification
                print("fix notification")
               // self.notificationCenter?.sendNotifications(type: NotificationType.Track.rawValue, args: [eventKey, userId, attributes, eventTags, ["url":eventForDispatch.url as Any, "body":eventForDispatch.body as Any]])
            }
        }
        
    }
    
}

// MARK: Objective-C Wrappers

extension OPTManager {
    
    @objc public convenience init(sdkKey: String) {
        self.init(sdkKey: sdkKey,
                  logger: nil,
                  bucketer: nil,
                  decisionService: nil,
                  eventDispatcher: nil,
                  datafileHandler: nil,
                  userProfileService: nil,
                  notificationCenter: nil,
                  periodicDownloadInterval: nil)
    }
    
    // TODO: review this for Objective-C clients support (@objc)
    
//    @objc public convenience init(sdkKey: String,
//                                  logger:OPTLogger?,
//                                  bucketer:OPTBucketer?,
//                                  decisionService:OPTDecisionService?,
//                                  eventDispatcher:OPTEventDispatcher?,
//                                  datafileHandler:OPTDatafileHandler?,
//                                  userProfileService:OPTUserProfileService?,
//                                  notificationCenter:OPTNotificationCenter?,
//                                  periodicDownloadInterval:Int? = nil) {

    
    @objc public func initializeSDK(completion: ((NSError?, Data?) -> Void)?) {
        initializeSDK { result in
            switch result {
            case .failure(let error):
                
                completion?(self.convertErrorForObjc(error), nil)
            case .success(let data):
                completion?(nil, data)
            }
            
        }
    }
    
    func convertErrorForObjc(_ error: Error) -> NSError {
        var errorInObjc: NSError
        
        switch error {
        
        default:
            errorInObjc = NSError(domain: "com.optimizely.OptimizelySwiftSDK", code: 1000, userInfo: nil)
        }
        
        return errorInObjc
    }
}
