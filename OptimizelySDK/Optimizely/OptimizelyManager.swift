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
    var config: ProjectConfig?
    
    // MARK: - Customizable Services
    
    var logger: OPTLogger {
        return HandlerRegistryService.shared.injectLogger()!
    }
    var eventDispatcher: OPTEventDispatcher {
        return HandlerRegistryService.shared.injectEventDispatcher(sdkKey: self.sdkKey)!
    }
    let periodicDownloadInterval: Int
    
    // MARK: - Default Services
    
    // TODO: [Tom] can we remove decisionService from RegsitryService?
    
    var decisionService: OPTDecisionService {
        return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey)!
    }
    var datafileHandler: OPTDatafileHandler {
        return HandlerRegistryService.shared.injectDatafileHandler(sdkKey: self.sdkKey)!
    }
    
    public var notificationCenter: OPTNotificationCenter {
        return HandlerRegistryService.shared.injectNotificationCenter(sdkKey: self.sdkKey)!
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
                logger: OPTLogger? = nil,
                eventDispatcher: OPTEventDispatcher? = nil,
                userProfileService: OPTUserProfileService? = nil,
                periodicDownloadInterval: Int? = nil) {
        
        self.sdkKey = sdkKey
        self.periodicDownloadInterval = periodicDownloadInterval ?? 10 * 60
        
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
    public func initializeSDK(datafile: Data, doFetchDatafileBackground: Bool = true) throws {
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
        
        var args: Array<Any?> = (self.notificationCenter as! DefaultNotificationCenter).getArgumentsForDecisionListener(notificationType: Constants.DecisionTypeKeys.experiment, userId: userId, attributes: attributes)

        var decisionInfo = [String:Any]()
        decisionInfo[Constants.NotificationKeys.experiment] = nil
        decisionInfo[Constants.NotificationKeys.variation] = nil
        
        // fix DecisionService to throw error
        guard let variation = decisionService.getVariation(config: config, userId: userId, experiment: experiment, attributes: attributes ?? OptimizelyAttributes()) else {
            args.append(decisionInfo)
            self.notificationCenter.sendNotifications(type: NotificationType.Decision.rawValue, args: args)
            throw OptimizelyError.variationUnknown
        }
        
        decisionInfo[Constants.NotificationKeys.experiment] = experimentKey
        decisionInfo[Constants.NotificationKeys.variation] = variation.key
        args.append(decisionInfo)
        self.notificationCenter.sendNotifications(type: NotificationType.Decision.rawValue, args: args)
        
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
    public func getForcedVariation(experimentKey: String, userId: String) -> String? {
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
    public func setForcedVariation(experimentKey: String,
                                   userId: String,
                                   variationKey: String?) -> Bool {
        
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
        
        var args: Array<Any?> = (self.notificationCenter as! DefaultNotificationCenter).getArgumentsForDecisionListener(notificationType: Constants.DecisionTypeKeys.isFeatureEnabled, userId: userId, attributes: attributes)
        
        var decisionInfo = [String:Any]()
        decisionInfo[Constants.DecisionInfoKeys.feature] = featureKey
        decisionInfo[Constants.DecisionInfoKeys.source] = Constants.DecisionSource.Rollout
        decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = false
        
        guard let variation = pair?.variation else {
            args.append(decisionInfo)
            self.notificationCenter.sendNotifications(type: NotificationType.Decision.rawValue, args: args)
            throw OptimizelyError.variationUnknown
        }
        
        let featureEnabled = variation.featureEnabled ?? false
    
        if (featureEnabled) {
            logger.log(level: .info, message: LogMessage.featureEnabledForUser(featureKey, userId).description)
        } else {
            logger.log(level: .info, message: LogMessage.featureNotEnabledForUser(featureKey, userId).description)
        }

        // we came from an experiment if experiment is not nil
        if let experiment = pair?.experiment {
            
            decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] = experiment.key
            decisionInfo[Constants.DecisionInfoKeys.sourceVariation] = variation.key
            
            // TODO: fix to throw errors
            guard let body = BatchEventBuilder.createImpressionEvent(config: config,
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
        
        decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = featureEnabled
        decisionInfo[Constants.DecisionInfoKeys.source] = (pair?.experiment != nil ? Constants.DecisionSource.Experiment : Constants.DecisionSource.Rollout)
        args.append(decisionInfo)
        self.notificationCenter.sendNotifications(type: NotificationType.Decision.rawValue, args: args)
        
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
        
        var decisionInfo = [String:Any]()
        decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] = nil
        decisionInfo[Constants.DecisionInfoKeys.sourceVariation] = nil
        
        // TODO: [Jae] optional? fallback to empty string is OK?
        var featureValue = variable.defaultValue ?? ""
        
        var _attributes = OptimizelyAttributes()
        if let attributes = attributes {
            _attributes = attributes
        }
        let decision = self.decisionService.getVariationForFeature(config: config, featureFlag: featureFlag, userId: userId, attributes: _attributes)
        if let decision = decision {
            if let experiment = decision.experiment {
                decisionInfo[Constants.DecisionInfoKeys.sourceExperiment] = experiment.key
                decisionInfo[Constants.DecisionInfoKeys.sourceVariation] = decision.variation?.key
            }
            if let featureVariable = decision.variation?.variables?.filter({$0.id == variable.id}).first {
                if let featureEnabled = decision.variation?.featureEnabled, featureEnabled {
                    featureValue = featureVariable.value
                } else {
                    // add standard log message here
                }
            }
        }
        
        var typeName: String?
        var valueParsed: T?
        
        switch T.self {
        case is String.Type:
            typeName = "string"
            valueParsed = featureValue as? T
        case is Int.Type:
            typeName = "integer"
            valueParsed = Int(featureValue) as? T
        case is Double.Type:
            typeName = "double"
            valueParsed = Double(featureValue) as? T
        case is Bool.Type:
            typeName = "boolean"
            valueParsed = Bool(featureValue) as? T
        default:
            break
        }
        
        guard let value = valueParsed,
            variable.type == typeName else
        {
            throw OptimizelyError.variableValueInvalid(variableKey)
        }
        
        var args: Array<Any?> = (self.notificationCenter as! DefaultNotificationCenter).getArgumentsForDecisionListener(notificationType: Constants.DecisionTypeKeys.featureVariable, userId: userId, attributes: _attributes)
        
        decisionInfo[Constants.DecisionInfoKeys.feature] = featureKey
        decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = decision?.variation?.featureEnabled ?? false
        decisionInfo[Constants.DecisionInfoKeys.variable] = variableKey
        decisionInfo[Constants.DecisionInfoKeys.variableType] = typeName
        decisionInfo[Constants.DecisionInfoKeys.variableValue] = value
        decisionInfo[Constants.DecisionInfoKeys.source] = (decision?.experiment != nil ? Constants.DecisionSource.Experiment : Constants.DecisionSource.Rollout)
        args.append(decisionInfo)
    
        self.notificationCenter.sendNotifications(type: NotificationType.Decision.rawValue, args: args)
        
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
                                   attributes: OptimizelyAttributes?=nil) throws -> [String] {
        
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

extension OptimizelyManager {
    @available(swift, obsoleted: 1.0)
    @objc public convenience init(sdkKey: String) {
        self.init(sdkKey: sdkKey,
                  logger: nil,
                  eventDispatcher: nil,
                  userProfileService: nil,
                  periodicDownloadInterval: nil as NSNumber?)
    }
    
    @objc public convenience init(sdkKey: String,
                                  logger: OPTLogger?,
                                  eventDispatcher: _ObjcOPTEventDispatcher?,
                                  userProfileService: OPTUserProfileService?,
                                  periodicDownloadInterval: NSNumber?) {
        self.init(sdkKey: sdkKey,
                  logger: logger,
                  eventDispatcher: SwiftEventDispatcher(eventDispatcher),
                  userProfileService: userProfileService,
                  periodicDownloadInterval: periodicDownloadInterval?.intValue)
        
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initializeSDKWithCompletion:)
    public func _objcInitializeSDK(completion: ((Data?, NSError?) -> Void)?) {
        initializeSDK { result in
            switch result {
            case .failure(let error):
                completion?(nil, self.convertErrorForObjc(error))
            case .success(let data):
                completion?(data, nil)
            }
        }
    }

    @available(swift, obsoleted: 1.0)
    @objc(notificationCenter) public var objc_notificationCenter: _ObjcOPTNotificationCenter {
        class ObjcCenter : _ObjcOPTNotificationCenter {
            var notifications:OPTNotificationCenter
            
            init(notificationCenter:OPTNotificationCenter) {
                notifications = notificationCenter
            }
            
            internal func convertAttribues(attributes:OptimizelyAttributes?) -> [String:Any]? {
                return attributes?.mapValues({ (val) -> Any in
                    if let val = val {
                        return val
                    }
                    else {
                        return NSNull()
                    }
                })
            }
            
            internal func returnVal(num:Int?) -> NSNumber? {
                if let num = num {
                    return NSNumber(value: num)
                }
                
                return nil
            }
            
            func addActivateNotificationListener(activateListener: @escaping ([String : Any], String, [String : Any]?, [String : Any], Dictionary<String, Any>) -> Void) -> NSNumber? {
                
                let num = notifications.addActivateNotificationListener { (experiment, userId, attributes, variation, event) in
                    
                    activateListener(experiment, userId, self.convertAttribues(attributes: attributes), variation, event)
                }
                
                return returnVal(num: num)
            }
            
            func addTrackNotificationListener(trackListener: @escaping (String, String, [String : Any]?, Dictionary<String, Any>?, Dictionary<String, Any>) -> Void) -> NSNumber? {
                let num = notifications.addTrackNotificationListener { (eventKey, userId, attributes, eventTags, event) in
                    
                    trackListener(eventKey, userId, self.convertAttribues(attributes: attributes), eventTags, event)
                }
                
                return returnVal(num: num)
            }
            
            func addDecisionNotificationListener(decisionListener: @escaping (String, String, [String : Any]?, Dictionary<String, Any>) -> Void) -> NSNumber? {
                
                let num = notifications.addDecisionNotificationListener { (type, userId, attributes, decisionInfo) in
                    decisionListener(type, userId, self.convertAttribues(attributes: attributes), decisionInfo)
                }
                return returnVal(num: num)
            }
            
            func addDatafileChangeNotificationListener(datafileListener: @escaping (Data) -> Void) -> NSNumber? {
                let num = notifications.addDatafileChangeNotificationListener { (data) in
                    datafileListener(data)
                }
                
                return returnVal(num: num)
            }
            
            func removeNotificationListener(notificationId: Int) {
                notifications.removeNotificationListener(notificationId: notificationId)
            }
            
            func clearNotificationListeners(type: NotificationType) {
                notifications.clearNotificationListeners(type: type)
            }
            
            func clearAllNotificationListeners() {
                notifications.clearAllNotificationListeners()
            }
            
            
        }
        
        return ObjcCenter(notificationCenter: self.notificationCenter)
    }
    

    @available(swift, obsoleted: 1.0)
    @objc(initializeSDKWithDatafile:error:)
    public func _objcInitializeSDKWith(datafile:String) throws {
        try self.initializeSDK(datafile: datafile)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initializeSDKWithDatafile:doFetchDatafileBackground:error:)
    public func _objcInitializeSDK(datafile: Data, doFetchDatafileBackground: Bool = true) throws {
        try self.initializeSDK(datafile: datafile, doFetchDatafileBackground: doFetchDatafileBackground)
    }

    @available(swift, obsoleted: 1.0)
    @objc(activateWithExperimentKey:userId:attributes:error:)
    public func _objcActivate(experimentKey: String,
                              userId: String,
                              attributes: [String:Any]?) throws -> String {
        return try self.activate(experimentKey: experimentKey, userId: userId, attributes: attributes as OptimizelyAttributes?)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getVariationKeyWithExperimentKey:userId:attributes:error:)
    public func _objcGetVariationKey(experimentKey: String,
                                     userId: String,
                                     attributes: [String:Any]?) throws -> String {
        return try getVariationKey(experimentKey: experimentKey,
                                   userId: userId,
                                   attributes: attributes)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getForcedVariationWithExperimentKey:userId:)
    public func _objcGetForcedVariation(experimentKey: String, userId: String) -> String? {
        return getForcedVariation(experimentKey: experimentKey,
                                  userId: userId)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(setForcedVariationWithExperimentKey:userId:variationKey:)
    public func _objcSetForcedVariation(experimentKey: String,
                                        userId: String,
                                        variationKey: String?) -> Bool {
        return setForcedVariation(experimentKey: experimentKey,
                                  userId: userId,
                                  variationKey: variationKey)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(isFeatureEnabledWithFeatureKey:userId:attributes:error:)
    public func _objcIsFeatureEnabled(featureKey: String,
                                      userId: String,
                                      attributes: [String:Any]?) throws -> NSNumber {
        let enabled = try self.isFeatureEnabled(featureKey: featureKey,
                                                userId: userId,
                                                attributes: attributes)
        return NSNumber(booleanLiteral: enabled)
    }
    

    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableBooleanWithFeatureKey:variableKey:userId:attributes:error:)
    public func _objcGetFeatureVariableBoolean(featureKey: String,
                                               variableKey: String,
                                               userId: String,
                                               attributes: [String: Any]?) throws -> NSNumber {
        let value = try self.getFeatureVariableBoolean(featureKey: featureKey,
                                                       variableKey: variableKey,
                                                       userId: userId,
                                                       attributes: attributes)
        return NSNumber(booleanLiteral: value)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableDoubleWithFeatureKey:variableKey:userId:attributes:error:)
    public func _objcGetFeatureVariableDouble(featureKey: String,
                                              variableKey: String,
                                              userId: String,
                                              attributes: [String: Any]?) throws -> NSNumber {
        let value = try self.getFeatureVariableDouble(featureKey: featureKey,
                                                      variableKey: variableKey,
                                                      userId: userId,
                                                      attributes: attributes)
        return NSNumber(value: value)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableIntegerWithFeatureKey:variableKey:userId:attributes:error:)
    public func _objcGetFeatureVariableInteger(featureKey: String,
                                               variableKey: String,
                                               userId: String,
                                               attributes: [String: Any]?) throws -> NSNumber {
        let value = try self.getFeatureVariableInteger(featureKey: featureKey,
                                                       variableKey: variableKey,
                                                       userId: userId,
                                                       attributes: attributes)
        return NSNumber(integerLiteral: value)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableStringWithFeatureKey:variableKey:userId:attributes:error:)
    public func _objcGetFeatureVariableString(featureKey: String,
                                              variableKey: String,
                                              userId: String,
                                              attributes: [String: Any]?) throws -> String {
        return try self.getFeatureVariableString(featureKey: featureKey,
                                                 variableKey: variableKey,
                                                 userId: userId,
                                                 attributes: attributes)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getEnabledFeaturesWithUserId:attributes:error:)
    public func _objcGetEnabledFeatures(userId: String,
                                        attributes: [String: Any]?) throws -> [String] {
        return try self.getEnabledFeatures(userId:userId, attributes: attributes)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(trackWithEventKey:userId:attributes:eventTags:error:)
    public func _objcTrack(eventKey:String,
                           userId: String,
                           attributes: [String:Any]?,
                           eventTags: [String:Any]?) throws {
        try self.track(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: eventTags)
    }
    
}

// MARK: - ObjC Conversions

extension OptimizelyManager {
    
    // MARK: - OPTEventDispatcher protocol wrapper

    class SwiftEventDispatcher: OPTEventDispatcher {
        let objcEventDispatcher: _ObjcOPTEventDispatcher
        
        init?(_ objcEventDispatcher: _ObjcOPTEventDispatcher?) {
            guard let objcDispatcher = objcEventDispatcher else { return nil }
            
            self.objcEventDispatcher = objcDispatcher
        }
        
        func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
            var objcHandler: ((Data?, NSError?) -> Void)? = nil
            
            if let completionHandler = completionHandler {
                objcHandler = { (data, error) in
                    var result: Result<Data, OptimizelyError>
                    
                    if let error = error {
                        result = .failure(.eventDispatchFailed(error.localizedDescription))
                    } else {
                        result = .success(data ?? Data())
                    }
                    
                    completionHandler(result)
                }
            }
            
            objcEventDispatcher.dispatchEvent(event: event, completionHandler: objcHandler)
        }
        
        func flushEvents() {
            objcEventDispatcher.flushEvents()
        }
    }
    
    // MAKR: - ObjC Errors
    
    func convertErrorForObjc(_ error: Error) -> NSError {
        var errorInObjc: NSError
        
        // TODO: [Jae] add more details for error types
        
        switch error {
        default:
            errorInObjc = NSError(domain: "com.optimizely.OptimizelySwiftSDK",
                                  code: 1000,
                                  userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }
        
        return errorInObjc
    }
}

// MARK: - ObjC protocols
@objc(OPTEventDispatcher) public protocol _ObjcOPTEventDispatcher {
    func dispatchEvent(event:EventForDispatch, completionHandler:((Data?, NSError?) -> Void)?)
    
    /// Attempts to flush the event queue if there are any events to process.
    func flushEvents()
}
