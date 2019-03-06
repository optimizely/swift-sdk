//
//  OptimizelyManager.swift
//  OptimizelySDK
//
//  Created by Jae Kim on 12/19/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation


open class OptimizelyManager: NSObject {
    
    // MARK: - Properties
    
    var sdkKey: String
    var config:ProjectConfig!
    
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
    var userProfileService: OPTUserProfileService {
        get {
            return HandlerRegistryService.shared.injectUserProfileService(sdkKey: self.sdkKey)!
        }
    }
    let periodicDownloadInterval: Int

    // MARK: - Default Services

    var bucketer: OPTBucketer {
        get {
            return HandlerRegistryService.shared.injectBucketer(sdkKey: self.sdkKey)!
        }
    }
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

        self.registerServices(sdkKey: sdkKey,
                              logger: logger ?? DefaultLogger(),
                              eventDispatcher: eventDispatcher ?? DefaultEventDispatcher(),
                              userProfileService: userProfileService ?? DefaultUserProfileService(),
                              datafileHandler: DefaultDatafileHandler(),
                              bucketer: DefaultBucketer(),
                              decisionService: DefaultDecisionService(),
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
    
    public func initializeSDK(datafile: Data) throws {
        let cachedDatafile = self.datafileHandler.loadSavedDatafile(sdkKey: self.sdkKey)

        let selectedDatafile = cachedDatafile ?? datafile
        
        try configSDK(datafile: selectedDatafile)
        
        // continue to fetch updated datafile from the server in background and cache it for next sessions
        fetchDatafileBackground()
    }
    
    func configSDK(datafile: Data) throws {
        do {
            self.config = try ProjectConfig(datafile: datafile)
            
            // TODO: fix these to throw errors
            bucketer.initialize(config: self.config)
            decisionService.initialize(config: self.config,
                                       bucketer: self.bucketer,
                                       userProfileService: self.userProfileService)
            if periodicDownloadInterval > 0 {
                datafileHandler.stopPeriodicUpdates(sdkKey: self.sdkKey)
                datafileHandler.startPeriodicUpdates(sdkKey: self.sdkKey, updateInterval: periodicDownloadInterval) { data in
                    // new datafile came in...
                    self.reInitLock.wait(); defer { self.reInitLock.signal() }
                    if let config = try? ProjectConfig(datafile: data) {
                        var featureToggleNotifications:[String:FeatureFlagToggle] = self.getFeatureFlagChanges(newConfig:config)
                        
                        self.config = config
                        
                        // call reinit on the services we know we are reinitializing.
                        HandlerRegistryService.shared.reInitializeComponent(
                            service:OPTBucketer.self,
                            sdkKey: self.sdkKey)
                         HandlerRegistryService.shared.reInitializeComponent(
                            service: OPTDecisionService.self,
                            sdkKey: self.sdkKey)
                        
                        // now reinitialize with the new config.
                        self.bucketer.initialize(config: self.config)
                        self.decisionService.initialize(config: self.config,
                                                   bucketer: self.bucketer,
                                                   userProfileService: self.userProfileService)


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
        
        if let featureFlags = self.config?.project?.featureFlags {
            for feature in featureFlags {
                if let experiment = self.config.project.rollouts.filter(
                    {$0.id == feature.rolloutId }).first?.experiments.filter(
                        {$0.layerId == feature.rolloutId}).first,
                    let newExperiment = newConfig.project.rollouts.filter(
                    {$0.id == feature.rolloutId }).first?.experiments.filter(
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
    public func activate(experimentKey:String,
                         userId:String,
                         attributes:Dictionary<String, Any>?=nil) throws -> String {
        
        // TODO: fix config to throw common errors (.experimentUnknown, .experimentKeyInvalid, ...)
        guard let experiment = config.project.experiments.filter({$0.key == experimentKey}).first else {
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
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure:
                break
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
    /// - Throws: `OptimizelyError` if error is detected
    public func getVariationKey(experimentKey:String,
                                userId:String,
                                attributes:Dictionary<String, Any>?=nil) throws -> String {
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        return variation.key
    }
    
    func getVariation(experimentKey:String,
                      userId:String,
                      attributes:Dictionary<String, Any>?=nil) throws -> Variation {
        
        guard let experiment = config.project.experiments.filter({$0.key == experimentKey}).first else {
            throw OptimizelyError.experimentUnknown
        }

        // fix DecisionService to throw error
        guard let variation = decisionService.getVariation(userId: userId, experiment: experiment, attributes: attributes ?? [:]) else {
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
    /// - Throws: `OptimizelyError` if error is detected
    public func getForcedVariation(experimentKey:String, userId:String) throws -> String? {
        guard let experiment = config.project.experiments.filter({$0.key == experimentKey}).first else {
            throw OptimizelyError.experimentUnknown
        }
        
        guard let dict = config.whitelistUsers[userId],
            let variationKey = dict[experimentKey] else
        {
            return nil
        }
        
        guard let variation = experiment.variations.filter({$0.key == variationKey}).first else {
            throw OptimizelyError.variationUnknown
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func setForcedVariation(experimentKey:String,
                                   userId:String,
                                   variationKey:String?) throws {
        
        guard let _ = config.project.experiments.filter({$0.key == experimentKey}).first else {
            throw OptimizelyError.experimentUnknown
        }
        
        guard var variationKey = variationKey else {
            config.whitelistUsers[userId]?.removeValue(forKey: experimentKey)
            return
        }
        
        // TODO: common function to trim all keys
        variationKey = variationKey.trimmingCharacters(in: NSCharacterSet.whitespaces)
        
        guard !variationKey.isEmpty else {
            throw OptimizelyError.variationKeyInvalid(variationKey)
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func isFeatureEnabled(featureKey: String,
                                 userId: String,
                                 attributes: Dictionary<String,Any>?=nil) throws -> Bool {
        guard let featureFlag = config.project.featureFlags.filter({$0.key == featureKey}).first  else {
            return false
        }
        
        // fix DecisionService to throw error
        let pair = decisionService.getVariationForFeature(featureFlag: featureFlag, userId: userId, attributes: attributes ?? [:])
        
        guard let variation = pair?.variation else {
            throw OptimizelyError.variationUnknown
        }
        
        guard let featureEnabled = variation.featureEnabled else {
            // TODO: do we need to handle this error?
            throw OptimizelyError.featureUnknown
        }
    
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
            
            eventDispatcher.dispatchEvent(event: event) { result in
                switch result {
                case .failure:
                    break
                case .success(_):
                    self.notificationCenter.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any, "body":event.body as Any]])
                }
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
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
    /// - Throws: `OptimizelyError` if feature parameter is not valid
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
        
        // fix config to throw errors
        guard let featureFlag = config.project.featureFlags.filter({$0.key == featureKey}).first else {
            throw OptimizelyError.featureUnknown
        }
        
        guard let variable = featureFlag.variables.filter({$0.key == variableKey}).first else {
            throw OptimizelyError.variableUnknown
        }
        
        // TODO: [Jae] optional? fallback to empty string is OK?
        let defaultValueString = variable.defaultValue ?? ""

        var typeName: String?
        var valueParsed: T?
        
        switch T.self {
        case is String.Type:
            typeName = "string"
            valueParsed = defaultValueString as? T
        case is Int.Type:
            typeName = "integer"
            valueParsed = Int(defaultValueString) as? T
        case is Double.Type:
            typeName = "double"
            valueParsed = Double(defaultValueString) as? T
        case is Bool.Type:
            typeName = "boolean"
            valueParsed = Bool(defaultValueString) as? T
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
    public func getEnabledFeatures(userId:String,
                                   attributes:Dictionary<String,Any>?=nil) throws -> Array<String> {
        guard let featureFlags = config?.project?.featureFlags else {
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
    public func track(eventKey:String,
                      userId:String,
                      // right now we are still passing in attributes.  But, there is a jira ticket open to use easy event tracking in which case passing in attributes to track will be removed.
        attributes:Dictionary<String,Any>?=nil,
        eventTags:Dictionary<String,Any>?=nil) throws {
        
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
        eventDispatcher.dispatchEvent(event: event) { result in
            switch result {
            case .failure:
                break
            case .success( _):
                
                // TODO: clean up notification
                print("fix notification")
                // self.notificationCenter?.sendNotifications(type: NotificationType.Track.rawValue, args: [eventKey, userId, attributes, eventTags, ["url":eventForDispatch.url as Any, "body":eventForDispatch.body as Any]])
            }
        }
        
    }
    
}

extension HandlerRegistryService {
    func injectLogger(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTLogger? {
        return injectComponent(service: OPTLogger.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTLogger?
    }

    func injectNotificationCenter(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTNotificationCenter? {
        return injectComponent(service: OPTNotificationCenter.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTNotificationCenter?
    }
    func injectDecisionService(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTDecisionService? {
        return injectComponent(service: OPTDecisionService.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTDecisionService?
    }
    func injectBucketer(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTBucketer? {
        return injectComponent(service: OPTBucketer.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTBucketer?
    }
    
    func injectEventDispatcher(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTEventDispatcher? {
        return injectComponent(service: OPTEventDispatcher.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTEventDispatcher?
    }
    
    func injectDatafileHandler(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTDatafileHandler? {
        return injectComponent(service: OPTDatafileHandler.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTDatafileHandler?
    }
    
    func injectUserProfileService(sdkKey:String? = nil, isReintialize:Bool=false) -> OPTUserProfileService? {
        return injectComponent(service: OPTUserProfileService.self, sdkKey: sdkKey, isReintialize: isReintialize) as! OPTUserProfileService?
    }

}
extension OptimizelyManager {
    func registerServices(sdkKey:String,
                          logger:OPTLogger,
                          eventDispatcher:OPTEventDispatcher,
                          userProfileService:OPTUserProfileService,
                          datafileHandler:OPTDatafileHandler,
                          bucketer:OPTBucketer,
                          decisionService:OPTDecisionService,
                          notificationCenter:OPTNotificationCenter) {
        // bind it as a non-singleton.  so, we will create an instance anytime injected.
        // we don't associate the logger with a sdkKey at this time because not all components are sdkKey specific.
        let binder:Binder = Binder<OPTLogger>(service: OPTLogger.self).to(factory: type(of:logger).init)
        //Register my logger service.
        HandlerRegistryService.shared.registerBinding(binder: binder)

        // this is bound a reusable singleton. so, if we re-initalize, we will keep this.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTNotificationCenter>(service: OPTNotificationCenter.self).singetlon().reInitializeStrategy(strategy: .reUse).using(instance:notificationCenter).sdkKey(key: sdkKey))

        // this is a singleton but it has a reIntializeStrategy of reCreate.  So, we create a new
        // instance on re-initialize.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTBucketer>(service: OPTBucketer.self).singetlon().using(instance:bucketer).sdkKey(key: sdkKey))

        // the decision service is also a singleton that will reCreate on re-initalize
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTDecisionService>(service: OPTDecisionService.self).singetlon().using(instance:decisionService).sdkKey(key: sdkKey))
        
        // An event dispatcher.  We rely on the factory to create and mantain. Again, recreate on re-initalize.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTEventDispatcher>(service: OPTEventDispatcher.self).singetlon().reInitializeStrategy(strategy: .reUse).using(instance: eventDispatcher).sdkKey(key: sdkKey))
        
        // This is a singleton and might be a good candidate for reuse.  The handler supports mulitple
        // sdk keys without having to be created for every key.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).singetlon().reInitializeStrategy(strategy: .reUse).to(factory: type(of:datafileHandler).init).using(instance: datafileHandler).sdkKey(key: sdkKey))

        // the user profile service is also a singleton using eh passed in version.
        HandlerRegistryService.shared.registerBinding(binder:Binder<OPTUserProfileService>(service: OPTUserProfileService.self).singetlon().reInitializeStrategy(strategy:.reUse).using(instance:userProfileService).to(factory: type(of:userProfileService).init).sdkKey(key: sdkKey))

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
    
    func convertErrorForObjc(_ error: Error) -> NSError {
        var errorInObjc: NSError
        
        switch error {
            
        default:
            errorInObjc = NSError(domain: "com.optimizely.OptimizelySwiftSDK", code: 1000, userInfo: nil)
        }
        
        return errorInObjc
    }
}
