//
//  OptimizelyManager.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/19/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public typealias OptimizelyAttributes = [String: Any?]
public typealias OptimizelyEventTags = [String: Any]

open class OptimizelyManager: NSObject {

    // MARK: - Properties
    
    var sdkKey: String
    var config:ProjectConfig?
    
    // MARK: - Customizable Services

    var logger: OPTLogger {
        get {
            return HandlerRegistryService.shared.injectLogger()!
        }
    }
    var eventDispatcher: OPTEventDispatcher {
        get {
            return HandlerRegistryService.shared.injectEventDispatcher(sdkKey: self.sdkKey)!
        }
    }
    let periodicDownloadInterval: Int

    // MARK: - Default Services

    var decisionService: OPTDecisionService {
        get {
            return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey)!
        }
    }
    var datafileHandler: OPTDatafileHandler {
        get {
            return HandlerRegistryService.shared.injectDatafileHandler(sdkKey: self.sdkKey)!
        }
    }
    public var notificationCenter: OPTNotificationCenter {
        get {
            return HandlerRegistryService.shared.injectNotificationCenter(sdkKey: self.sdkKey)!
        }
    }
    
    private let reInitLock = Dispatch.DispatchSemaphore(value: 1)
    
    // MARK: - Public interfaces
    
    /// Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - eventDispatcher: custom EventDispatcher
    ///   - ...
    public init(sdkKey: String,
                logger:OPTLogger? = nil,
                eventDispatcher:OPTEventDispatcher? = nil,
                userProfileService:OPTUserProfileService? = nil,
                periodicDownloadInterval:Int? = nil) {
        
        self.sdkKey = sdkKey
        self.periodicDownloadInterval = periodicDownloadInterval ?? (10 * 60)
        
        super.init()

        let userProfileService = userProfileService ?? DefaultUserProfileService()
        self.registerServices(sdkKey: sdkKey,
                              logger: logger ?? DefaultLogger(),
                              eventDispatcher: eventDispatcher ?? DefaultEventDispatcher.sharedInstance,
                              datafileHandler: DefaultDatafileHandler(),
                              decisionService: DefaultDecisionService(userProfileService: userProfileService),
                              notificationCenter: DefaultNotificationCenter())

    }
    
    /// Initialize Optimizely Manager (Asynchronous)
    ///
    /// - Parameters:
    ///   - completion: callback when initialization is completed
    public func initializeSDK(completion: ((OptimizelyResult<Data>) -> Void)?=nil) {
        fetchDatafileBackground { result in
            switch result {
            case .failure:
                completion?(result)
            case .success(let datafile):
                do {
                    try self.configSDK(datafile: datafile)
                    
                    completion?(result)
                } catch let error as OptimizelyError {
                    completion?(.failure(error))
                } catch {
                    print("Invalid error types: \(error)")
                    completion?(.failure(OptimizelyError.datafileDownloadFailed("Unknown")))
                }
            }
        }
    }
    
    /// Initialize Optimizely Manager (Synchronous)
    ///
    /// - Parameters:
    ///   - datafile: when given, this datafile will be used when cached copy is not available (fresh start)
    ///                       a cached copy from previous download is used if it's available
    ///                       the datafile will be updated from the server in the background thread
    public func initializeSDK(datafile: String) throws {
        guard let datafileData = datafile.data(using: .utf8) else {
            throw OptimizelyError.dataFileInvalid
        }
        
        try initializeSDK(datafile: datafileData)
    }
    
    /// Initialize Optimizely Manager (Synchronous)
    ///
    /// - Parameters:
    ///   - datafile: when given, this datafile will be used when cached copy is not available (fresh start)
    ///                       a cached copy from previous download is used if it's available
    ///                       the datafile will be updated from the server in the background thread
    ///   - doFetchDatafileBackground: default to true.  This is really here for debugging purposes when
    ///                       you don't want to download the datafile.  In practice, you should allow the
    ///                       background thread to update the cache copy.
    public func initializeSDK(datafile: Data, doFetchDatafileBackground:Bool = true) throws {
        let cachedDatafile = self.datafileHandler.loadSavedDatafile(sdkKey: self.sdkKey)

        let selectedDatafile = cachedDatafile ?? datafile
        
        try configSDK(datafile: selectedDatafile)
        
        // continue to fetch updated datafile from the server in background and cache it for next sessions
        if doFetchDatafileBackground { fetchDatafileBackground() }
    }
    
    func configSDK(datafile: Data) throws {
        do {
            self.config = try ProjectConfig(datafile: datafile)
            
            // this isn't really necessary because the try would throw if there is a problem.  But, we want to avoid using bang so we do another let binding.
            guard let config = self.config else { throw OptimizelyError.dataFileInvalid }
            
            if periodicDownloadInterval > 0 {
                datafileHandler.stopPeriodicUpdates(sdkKey: self.sdkKey)
                datafileHandler.startPeriodicUpdates(sdkKey: self.sdkKey, updateInterval: periodicDownloadInterval) { data in
                    // new datafile came in...
                    self.reInitLock.wait(); defer { self.reInitLock.signal() }
                    if let config = try? ProjectConfig(datafile: data) {
                        var featureToggleNotifications:[String:FeatureFlagToggle] = self.getFeatureFlagChanges(newConfig:config)
                        
                        do {
                            self.config = config
                            
                            // call reinit on the services we know we are reinitializing.
                            
                            for component in HandlerRegistryService.shared.lookupComponents(sdkKey: self.sdkKey) ?? [] {
                                guard let component = component else { continue }
                                HandlerRegistryService.shared.reInitializeComponent(service: component, sdkKey: self.sdkKey)
                            }

                        }
                        
                        self.notificationCenter.sendNotifications(type:
                            NotificationType.DatafileChange.rawValue, args: [data])
                        
                        for notify in featureToggleNotifications.keys {
                            self.notificationCenter.sendNotifications(type: NotificationType.FeatureFlagRolloutToggle.rawValue, args: [notify, featureToggleNotifications[notify]])
                        }
                    }
                }
                
            }
        } catch let error as OptimizelyError {
            // .datafileInvalid
            // .datafaileVersionInvalid
            // .datafaileLoadingFailed
            throw error
        } catch {  // DecodingError, etc.
            throw OptimizelyError.dataFileInvalid
        }
     }
    
    func getFeatureFlagChanges(newConfig:ProjectConfig) -> [String:FeatureFlagToggle] {
        var featureToggleNotifications:[String:FeatureFlagToggle] =
        [String:FeatureFlagToggle]()
        
        if let config = self.config, let featureFlags = config.project?.featureFlags {
            for feature in featureFlags {
                if let experiment = config.getRollout(id: feature.rolloutId)?.experiments.filter(
                        {$0.layerId == feature.rolloutId}).first,
                    let newExperiment = newConfig.getRollout(id: feature.rolloutId)?.experiments.filter(
                        {$0.layerId == feature.rolloutId}).first,
                    experiment.status != newExperiment.status {
                    // call rollout change with status changed.
                    featureToggleNotifications[feature.key] = newExperiment.status == .running ? FeatureFlagToggle.on : FeatureFlagToggle.off
                }
            }
        }
        
        return featureToggleNotifications
    }
    
    func fetchDatafileBackground(completion: ((OptimizelyResult<Data>) -> Void)?=nil) {
        
        // TODO: fix downloadDatafile to throw OptimizelyError
        //       those errors propagated instead of handling here
        
        datafileHandler.downloadDatafile(sdkKey: self.sdkKey){ result in
            var fetchResult: OptimizelyResult<Data>

            switch result {
            case .failure:
                fetchResult = .failure(.generic)
            case .success(let datafile):
                // we got a new datafile.
                if let datafile = datafile {
                    fetchResult = .success(datafile)
                }
                // we got a success but no datafile 304. So, load the saved datafile.
                else if let data = self.datafileHandler.loadSavedDatafile(sdkKey: self.sdkKey) {
                    fetchResult = .success(data)
                }
                // if that fails, we have a problem.
                else {
                    fetchResult = .failure(.generic)
                }

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
    /// - Throws: `OptimizelyError` if error is detected
    public func activate(experimentKey: String,
                         userId: String,
                         attributes: OptimizelyAttributes?=nil) throws -> String {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotConfigured }

        // TODO: fix config to throw common errors (.experimentUnknown, .experimentKeyInvalid, ...)
        guard let experiment = config.getExperiment(key: experimentKey) else {
            throw OptimizelyError.experimentUnknown
        }
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        
        // TODO: fix to throw errors
        guard let body = BatchEventBuilder.createImpressionEvent(config: config,
                                                                 decisionService: decisionService,
                                                                 experiment: experiment,
                                                                 varionation: variation,
                                                                 userId: userId,
                                                                 attributes: attributes) else
        {
            throw OptimizelyError.eventUnknown    // TODO: pass errors
        }
        
        let event = EventForDispatch(body: body)
        // because we are batching events, we cannot guarantee that the completion handler will be
        // called.  So, for now, we are queuing and calling onActivate.  Maybe we should mention that
        // onActivate only means the event has been queued and not necessarily sent.
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure:
                break
            case .success( _):
                break
            }
        }

        self.notificationCenter.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any, "body":event.body as Any]])

        return variation.key
    }
    
    /// Get variation for experiment and user ID with user attributes.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: The variation key the user was bucketed into
    /// - Throws: `OptimizelyError` if error is detected
    public func getVariationKey(experimentKey: String,
                                userId: String,
                                attributes: OptimizelyAttributes?=nil) throws -> String {
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        return variation.key
    }
    
    func getVariation(experimentKey: String,
                      userId: String,
                      attributes: OptimizelyAttributes?=nil) throws -> Variation {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotConfigured }
        
        
        guard let experiment = config.getExperiment(key: experimentKey) else {
            throw OptimizelyError.experimentUnknown
        }
        
        // fix DecisionService to throw error
        guard let variation = decisionService.getVariation(config: config, userId: userId, experiment: experiment, attributes: attributes ?? OptimizelyAttributes()) else {
            throw OptimizelyError.variationUnknown
        }
        
        return variation
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
    public func getForcedVariation(experimentKey:String, userId:String) -> String? {
        guard let config = self.config else { return nil }

        let variaion = config.getForcedVariation(experimentKey: experimentKey, userId: userId)
        return variaion?.key
    }
        

    /// Set forced variation for experiment and user ID to variationKey.
    ///
    /// - Parameters:
    ///   - experimentKey The key for the experiment.
    ///   - userId The user ID to be used for bucketing.
    ///   - variationKey The variation the user should be forced into.
    ///                  This value can be nil, in which case, the forced variation is cleared.
    /// - Returns: true if forced variation set successfully
    public func setForcedVariation(experimentKey:String,
                                   userId:String,
                                   variationKey:String?) -> Bool {
        
        guard let config = self.config else { return false }

        return config.setForcedVariation(experimentKey: experimentKey,
                                         userId: userId,
                                         variationKey: variationKey)
    }
    
    /// Determine whether a feature is enabled.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: true if feature is enabled, false otherwise.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func isFeatureEnabled(featureKey: String,
                                 userId: String,
                                 attributes: OptimizelyAttributes?=nil) throws -> Bool {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotConfigured }

        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            return false
        }
        
        // fix DecisionService to throw error
        let pair = decisionService.getVariationForFeature(config: config, featureFlag: featureFlag, userId: userId, attributes: attributes ?? OptimizelyAttributes())
        
        guard let variation = pair?.variation else {
            throw OptimizelyError.variationUnknown
        }
        
        let featureEnabled = variation.featureEnabled ?? false
    
        // we came from an experiment if experiment is not nil
        if let experiment = pair?.experiment {
        // TODO: fix to throw errors
            guard let body = BatchEventBuilder.createImpressionEvent(config: config,
                                                                 decisionService: decisionService,
                                                                 experiment: experiment,
                                                                 varionation: variation,
                                                                 userId: userId,
                                                                 attributes: attributes) else
            {
                // TODO: pass error
                throw OptimizelyError.eventUnknown
            }

            let event = EventForDispatch(body: body)
            
            // because we are batching events, we cannot guarantee that the completion handler will be
            // called.  So, for now, we are queuing and calling onActivate.  Maybe we should mention that
            // onActivate only means the event has been queued and not necessarily sent.
            eventDispatcher.dispatchEvent(event: event) { result in
                switch result {
                case .failure:
                    break
                case .success(_):
                    break
                }
            }
            self.notificationCenter.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any, "body":event.body as Any]])
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableBoolean(featureKey: String,
                                          variableKey: String,
                                          userId: String,
                                          attributes: OptimizelyAttributes?=nil) throws -> Bool {
        
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableDouble(featureKey: String,
                                         variableKey: String,
                                         userId: String,
                                         attributes: OptimizelyAttributes?=nil) throws -> Double {
        
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableInteger(featureKey: String,
                                          variableKey: String,
                                          userId: String,
                                          attributes: OptimizelyAttributes?=nil) throws -> Int {
        
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableString(featureKey: String,
                                         variableKey: String,
                                         userId: String,
                                         attributes: OptimizelyAttributes?=nil) throws -> String {
        
        return try getFeatureVariable(featureKey: featureKey,
                                      variableKey: variableKey,
                                      userId: userId,
                                      attributes: attributes)
    }
    
    func getFeatureVariable<T>(featureKey: String,
                               variableKey: String,
                               userId: String,
                               attributes: OptimizelyAttributes?=nil) throws -> T {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotConfigured }

        // fix config to throw errors
        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            throw OptimizelyError.featureUnknown
        }
        
        guard let variable = featureFlag.getVariable(key: variableKey) else {
            throw OptimizelyError.variableUnknown
        }
        
        // TODO: [Jae] optional? fallback to empty string is OK?
        var defaultValue = variable.defaultValue ?? ""
        
        var _attributes = OptimizelyAttributes()
        if attributes != nil {
            _attributes = attributes!
        }
        if let decision = self.decisionService.getVariationForFeature(config: config, featureFlag: featureFlag, userId: userId, attributes: _attributes) {
            if let featureVariableUsage = decision.variation?.getVariable(id: variable.id) {
                defaultValue = featureVariableUsage.value
            }
        }

        var typeName: String?
        var valueParsed: T?
        
        switch T.self {
        case is String.Type:
            typeName = "string"
            valueParsed = defaultValue as? T
        case is Int.Type:
            typeName = "integer"
            valueParsed = Int(defaultValue) as? T
        case is Double.Type:
            typeName = "double"
            valueParsed = Double(defaultValue) as? T
        case is Bool.Type:
            typeName = "boolean"
            valueParsed = Bool(defaultValue) as? T
        default:
            break
        }
        
        guard let value = valueParsed,
            variable.type == typeName else
        {
            throw OptimizelyError.variableValueInvalid(variableKey)
        }
        
        return value
    }
    
    
    /// Get array of features that are enabled for the user.
    ///
    /// - Parameters:
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: Array of feature keys that are enabled for the user.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getEnabledFeatures(userId: String,
                                   attributes: OptimizelyAttributes?=nil) throws -> Array<String> {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotConfigured }

        guard let featureFlags = config.project?.featureFlags else {
            return [String]()
        }
        
        let enabledFeatures = featureFlags.filter{
            do {
                return try isFeatureEnabled(featureKey: $0.key, userId: userId, attributes: attributes)
            } catch {
                return false
            }
        }
        
        return enabledFeatures.map{$0.key}
    }
    
    /// Track an event
    ///
    /// - Parameters:
    ///   - eventKey: The event name
    ///   - userId: The user ID associated with the event to track
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
    /// - Throws: `OptimizelyError` if event parameter is not valid
    public func track(eventKey: String,
                      userId: String,
                      attributes: OptimizelyAttributes?=nil,
                      eventTags: OptimizelyEventTags?=nil) throws {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotConfigured }
        
        guard let _ = config.getEvent(key: eventKey) else {
            throw OptimizelyError.eventUnknown
        }
        
        // TODO: fix to throw errors
        guard let body = BatchEventBuilder.createConversionEvent(config: config,
                                                                 decisionService: decisionService,
                                                                 eventKey:eventKey,
                                                                 userId:userId,
                                                                 attributes:attributes,
                                                                 eventTags:eventTags) else
        {
            throw OptimizelyError.eventUnknown    // TODO: pass errors
        }
        
        let event = EventForDispatch(body: body)
        // because we are batching events, we cannot guarantee that the completion handler will be
        // called.  So, for now, we are queuing and calling onTrack.  Maybe we should mention that
        // onTrack only means the event has been queued and not necessarily sent.
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure:
                break
            case .success( _):
                    break
            }
        }
        self.notificationCenter.sendNotifications(type: NotificationType.Track.rawValue, args: [eventKey, userId, attributes, eventTags, ["url":event.url as Any, "body":event.body as Any]])

    }
    
}

// MARK: - Objective-C Wrappers (WIP)
extension OptimizelyManager {
    
    @objc public convenience init(sdkKey: String) {
        self.init(sdkKey: sdkKey,
                  logger: nil,
                  eventDispatcher: nil,
                  userProfileService: nil,
                  periodicDownloadInterval: nil)
    }
    
    // TODO: review this for Objective-C clients support (@objc)
    
    //    @objc public convenience init(sdkKey: String,
    //                                  logger:OPTLogger?,
    //                                  eventDispatcher:OPTEventDispatcher?,
    //                                  userProfileService:OPTUserProfileService?,
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
    
    @objc public func initializeSDKWith(datafile:String) throws {
        try self.initializeSDK(datafile: datafile)
    }
    
    @objc public func activate(experimentKey: String,
                         userId: String,
                         attributes: [String:Any]?) throws -> String {
        return try self.activate(experimentKey: experimentKey, userId: userId, attributes: attributes as OptimizelyAttributes?)
    }

    @objc public func activate(experimentKey: String,
                               userId: String) throws -> String {
        return try self.activate(experimentKey: experimentKey, userId: userId, attributes: nil)
    }

    
    @objc public func trackWith(eventKey:String,
                      userId: String,
                      attributes: [String:Any]?,
                      eventTags: [String:Any]?) throws {
        try self.track(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: eventTags)
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
