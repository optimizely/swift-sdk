/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import Foundation

public typealias OptimizelyAttributes = [String: Any?]
public typealias OptimizelyEventTags = [String: Any]

open class OptimizelyClient: NSObject {
    
    // MARK: - Properties
    
    var sdkKey: String
    private var atomicConfig: AtomicProperty<ProjectConfig> = AtomicProperty<ProjectConfig>()
    var config: ProjectConfig? {
        get {
            return atomicConfig.property
        }
        set {
            atomicConfig.property = newValue
        }
    }

    public var version: String {
        return Utils.sdkVersion
    }
    
    let eventLock = DispatchQueue(label: "com.optimizely.client")

    // MARK: - Customizable Services
    
    lazy var logger = OPTLoggerFactory.getLogger()
    
    var eventProcessor: OPTEventsProcessor? {
        return HandlerRegistryService.shared.injectEventProcessor(sdkKey: self.sdkKey)
    }
    
    // deprecated
    var eventDispatcher: OPTEventDispatcher? {
        return HandlerRegistryService.shared.injectEventDispatcher(sdkKey: self.sdkKey)
    }
    
    // MARK: - Default Services
    
    var decisionService: OPTDecisionService {
        return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey)!
    }
    
    public var datafileHandler: OPTDatafileHandler {
        return HandlerRegistryService.shared.injectDatafileHandler(sdkKey: self.sdkKey)!
    }
    
    public var notificationCenter: OPTNotificationCenter? {
        return HandlerRegistryService.shared.injectNotificationCenter(sdkKey: self.sdkKey)
    }

    // MARK: - Public interfaces
    
    /// Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - eventDispatcher: custom EventDispatcher (optional)
    ///   - userProfileService: custom UserProfileService (optional)
    ///   - periodicDownloadInterval: custom interval for periodic background datafile download (optional. default = 10 * 60 secs)
    ///   - defaultLogLevel: default log level (optional. default = .info)
    public init(sdkKey: String,
                logger: OPTLogger? = nil,
                eventProcessor: OPTEventsProcessor? = nil,
                eventDispatcher: OPTEventsDispatcher? = nil,
                userProfileService: OPTUserProfileService? = nil,
                defaultLogLevel: OptimizelyLogLevel? = nil) {
        
        self.sdkKey = sdkKey
        
        super.init()
        
        let userProfileService = userProfileService ?? DefaultUserProfileService()
        let logger = logger ?? DefaultLogger()
        type(of: logger).logLevel = defaultLogLevel ?? .info
        
        let eventDispatcher = eventDispatcher ?? HTTPEventDispatcher()
        let eventProcessor = eventProcessor ?? BatchEventProcessor(eventDispatcher: eventDispatcher)

        self.registerServices(sdkKey: sdkKey,
                              logger: logger,
                              eventProcessor: eventProcessor,
                              datafileHandler: DefaultDatafileHandler(),
                              decisionService: DefaultDecisionService(userProfileService: userProfileService),
                              notificationCenter: DefaultNotificationCenter())
        
        logger.d("SDK Version: \(version)")
    }
    
    @available(*, deprecated, message: "Use init with EventProcessor + EventsDispatcher instead")
    public init(sdkKey: String,
                logger: OPTLogger? = nil,
                eventDispatcher: OPTEventDispatcher? = nil,
                userProfileService: OPTUserProfileService? = nil,
                defaultLogLevel: OptimizelyLogLevel? = nil) {
        
        self.sdkKey = sdkKey
        
        super.init()
        
        let userProfileService = userProfileService ?? DefaultUserProfileService()
        let logger = logger ?? DefaultLogger()
        type(of: logger).logLevel = defaultLogLevel ?? .info
        
        self.registerServices(sdkKey: sdkKey,
                              logger: logger,
                              eventDispatcher: eventDispatcher ?? DefaultEventDispatcher.sharedInstance,
                              datafileHandler: DefaultDatafileHandler(),
                              decisionService: DefaultDecisionService(userProfileService: userProfileService),
                              notificationCenter: DefaultNotificationCenter())
        
        logger.d("SDK Version: \(version)")
    }
    
    /// Start Optimizely SDK (Asynchronous)
    ///
    /// If an updated datafile is available in the server, it's downloaded and the SDK is configured with
    /// the updated datafile.
    ///
    /// - Parameters:
    ///   - resourceTimeout: timeout for datafile download (optional)
    ///   - completion: callback when initialization is completed
    public func start(resourceTimeout: Double? = nil, completion: ((OptimizelyResult<Data>) -> Void)? = nil) {
        fetchDatafileBackground(resourceTimeout: resourceTimeout) { result in
            switch result {
            case .failure:
                completion?(result)
            case .success(let datafile):
                do {
                    try self.configSDK(datafile: datafile)
                    
                    completion?(result)
                } catch {
                    completion?(.failure(error as! OptimizelyError))
                }
            }
        }
    }
    
    /// Start Optimizely SDK (Synchronous)
    ///
    /// - Parameters:
    ///   - datafile: This datafile will be used when cached copy is not available (fresh start).
    ///             A cached copy from previous download is used if it's available.
    ///             The datafile will be updated from the server in the background thread.
    public func start(datafile: String) throws {
        let datafileData = Data(datafile.utf8)
        try start(datafile: datafileData)
    }
    
    /// Start Optimizely SDK (Synchronous)
    ///
    /// - Parameters:
    ///   - datafile: This datafile will be used when cached copy is not available (fresh start)
    ///             A cached copy from previous download is used if it's available.
    ///             The datafile will be updated from the server in the background thread.
    ///   - doFetchDatafileBackground: This is for debugging purposes when
    ///             you don't want to download the datafile.  In practice, you should allow the
    ///             background thread to update the cache copy (optional)
    public func start(datafile: Data, doFetchDatafileBackground: Bool = true) throws {
        let cachedDatafile = self.datafileHandler.loadSavedDatafile(sdkKey: self.sdkKey)
        let selectedDatafile = cachedDatafile ?? datafile
        
        try configSDK(datafile: selectedDatafile)
        
        // continue to fetch updated datafile from the server in background and cache it for next sessions
        if doFetchDatafileBackground { fetchDatafileBackground() }
    }
    
    func configSDK(datafile: Data) throws {
        do {
            self.config = try ProjectConfig(datafile: datafile)
                        
            datafileHandler.startUpdates(sdkKey: self.sdkKey) { data in
                // new datafile came in...
                if let config = try? ProjectConfig(datafile: data) {
                    do {
                        if let users = self.config?.whitelistUsers {
                            config.whitelistUsers = users
                        }
                        
                        self.config = config
                        
                        // call reinit on the services we know we are reinitializing.
                        
                        for component in HandlerRegistryService.shared.lookupComponents(sdkKey: self.sdkKey) ?? [] {
                            HandlerRegistryService.shared.reInitializeComponent(service: component, sdkKey: self.sdkKey)
                        }
                        
                    }
                    
                    self.sendDatafileChangeNotification(data: data)
                }
            }
        } catch {
            // .datafileInvalid
            // .datafaileVersionInvalid
            // .datafaileLoadingFailed
            throw error
        }
    }
    
    func fetchDatafileBackground(resourceTimeout: Double? = nil, completion: ((OptimizelyResult<Data>) -> Void)? = nil) {
        
        datafileHandler.downloadDatafile(sdkKey: self.sdkKey, resourceTimeoutInterval: resourceTimeout) { result in
            var fetchResult: OptimizelyResult<Data>
            
            switch result {
            case .failure(let error):
                fetchResult = .failure(error)
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
                    fetchResult = .failure(.datafileLoadingFailed(self.sdkKey))
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
                         attributes: OptimizelyAttributes? = nil) throws -> String {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        guard let experiment = config.getExperiment(key: experimentKey) else {
            throw OptimizelyError.experimentKeyInvalid(experimentKey)
        }
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        
        sendImpressionEvent(experiment: experiment,
                            variation: variation,
                            userId: userId,
                            attributes: attributes)
        
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
                                attributes: OptimizelyAttributes? = nil) throws -> String {
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        return variation.key
    }
    
    func getVariation(experimentKey: String,
                      userId: String,
                      attributes: OptimizelyAttributes? = nil) throws -> Variation {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        guard let experiment = config.getExperiment(key: experimentKey) else {
            throw OptimizelyError.experimentKeyInvalid(experimentKey)
        }
        
        let variation = decisionService.getVariation(config: config,
                                                     userId: userId,
                                                     experiment: experiment,
                                                     attributes: attributes ?? OptimizelyAttributes())
        
        let decisionType: Constants.DecisionType = config.isFeatureExperiment(id: experiment.id) ? .featureTest : .abTest
        sendDecisionNotification(decisionType: decisionType,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: experiment,
                                 variation: variation)
        
        if let variation = variation {
            return variation
        } else {
            throw OptimizelyError.variationUnknown(userId, experimentKey)
        }
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
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - variationKey: The variation the user should be forced into.
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
    ///   - featureKey: The key for the feature flag.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: true if feature is enabled, false otherwise.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func isFeatureEnabled(featureKey: String,
                                 userId: String,
                                 attributes: OptimizelyAttributes? = nil) -> Bool {
        
        guard let config = self.config else {
            logger.e(.sdkNotReady)
            return false
        }
        
        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            logger.e(.featureKeyInvalid(featureKey))
            return false
        }
        
        let pair = decisionService.getVariationForFeature(config: config,
                                                          featureFlag: featureFlag,
                                                          userId: userId,
                                                          attributes: attributes ?? OptimizelyAttributes())
        
        guard let variation = pair?.variation else {
            logger.i(.variationUnknown(userId, featureKey))
            sendDecisionNotification(decisionType: .feature,
                                     userId: userId,
                                     attributes: attributes,
                                     feature: featureFlag,
                                     featureEnabled: false)
            return false
        }

        let featureEnabled = variation.featureEnabled ?? false
        if featureEnabled {
            logger.i(.featureEnabledForUser(featureKey, userId))
        } else {
            logger.i(.featureNotEnabledForUser(featureKey, userId))
        }

        let experiment = pair?.experiment
        if let eventExperiment = experiment {
            sendImpressionEvent(experiment: eventExperiment, variation: variation, userId: userId, attributes: attributes)
        }

        sendDecisionNotification(decisionType: .feature,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: experiment,
                                 variation: variation,
                                 feature: featureFlag,
                                 featureEnabled: featureEnabled)
        
        return featureEnabled
    }
    
    /// Gets boolean feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type boolean.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableBoolean(featureKey: String,
                                          variableKey: String,
                                          userId: String,
                                          attributes: OptimizelyAttributes? = nil) throws -> Bool {
        
        return try getFeatureVariable(featureKey: featureKey,
                                      variableKey: variableKey,
                                      userId: userId,
                                      attributes: attributes)
    }
    
    /// Gets double feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type double.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableDouble(featureKey: String,
                                         variableKey: String,
                                         userId: String,
                                         attributes: OptimizelyAttributes? = nil) throws -> Double {
        
        return try getFeatureVariable(featureKey: featureKey,
                                      variableKey: variableKey,
                                      userId: userId,
                                      attributes: attributes)
    }
    
    /// Gets integer feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type integer.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableInteger(featureKey: String,
                                          variableKey: String,
                                          userId: String,
                                          attributes: OptimizelyAttributes? = nil) throws -> Int {
        
        return try getFeatureVariable(featureKey: featureKey,
                                      variableKey: variableKey,
                                      userId: userId,
                                      attributes: attributes)
    }
    
    /// Gets string feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type string.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableString(featureKey: String,
                                         variableKey: String,
                                         userId: String,
                                         attributes: OptimizelyAttributes? = nil) throws -> String {

        return try getFeatureVariable(featureKey: featureKey,
                                      variableKey: variableKey,
                                      userId: userId,
                                      attributes: attributes)
    }
    
    func getFeatureVariable<T>(featureKey: String,
                               variableKey: String,
                               userId: String,
                               attributes: OptimizelyAttributes? = nil) throws -> T {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            throw OptimizelyError.featureKeyInvalid(featureKey)
        }
        
        guard let variable = featureFlag.getVariable(key: variableKey) else {
            throw OptimizelyError.variableKeyInvalid(variableKey, featureKey)
        }
        
        var featureValue = variable.defaultValue ?? ""
        
        let decision = self.decisionService.getVariationForFeature(config: config,
                                                                   featureFlag: featureFlag,
                                                                   userId: userId,
                                                                   attributes: attributes ?? OptimizelyAttributes())
        if let decision = decision {
            if let featureVariable = decision.variation?.variables?.filter({$0.id == variable.id}).first {
                if let featureEnabled = decision.variation?.featureEnabled, featureEnabled {
                    featureValue = featureVariable.value
                    
                    logger.i(.userReceivedVariableValue(userId, featureKey, variableKey, featureValue))
                } else {
                    logger.i(.featureNotEnabledReturnDefaultVariableValue(userId, featureKey, variableKey))
                }
            } else {
                logger.i(.variableNotUsedReturnDefaultVariableValue(variableKey))
            }
        } else {
            logger.i(.userReceivedDefaultVariableValue(userId, featureKey, variableKey))
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
            variable.type == typeName else {
            throw OptimizelyError.variableValueInvalid(variableKey)
        }
        
        // Decision Notification
        
        let experiment = decision?.experiment
        let variation = decision?.variation
        let featureEnabled = variation?.featureEnabled ?? false
        
        sendDecisionNotification(decisionType: .featureVariable,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: experiment,
                                 variation: variation,
                                 feature: featureFlag,
                                 featureEnabled: featureEnabled,
                                 variableKey: variableKey,
                                 variableType: typeName,
                                 variableValue: value)

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
                                   attributes: OptimizelyAttributes? = nil) -> [String] {
        
        var enabledFeatures = [String]()
        
        guard let config = self.config else {
            logger.e(.sdkNotReady)
            return enabledFeatures
        }
        
        enabledFeatures = config.getFeatureFlags().filter {
            isFeatureEnabled(featureKey: $0.key, userId: userId, attributes: attributes)
        }.map { $0.key }
        
        return enabledFeatures
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
                      attributes: OptimizelyAttributes? = nil,
                      eventTags: OptimizelyEventTags? = nil) throws {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        if config.getEvent(key: eventKey) == nil {
            throw OptimizelyError.eventKeyInvalid(eventKey)
        }
        
        sendConversionEvent(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: eventTags)
    }
    
}

// MARK: - Send Events

extension OptimizelyClient {
    
    func sendImpressionEvent(experiment: Experiment,
                             variation: Variation,
                             userId: String,
                             attributes: OptimizelyAttributes? = nil) {
        
        // non-blocking (event data serialization takes time)
        eventLock.async {
            guard let config = self.config else { return }
            
            let userEvent = ImpressionEvent(userContext: UserContext(config: config, userId: userId, attributes: attributes),
                                                  layerId: experiment.layerId,
                                                  experimentKey: experiment.key,
                                                  experimentId: experiment.id,
                                                  variationKey: variation.key,
                                                  variationId: variation.id)
            
            self.sendEventToDispatcher(event: userEvent) { result in
                if case .success(let body) = result {
                    // send notification in sync mode (functionally same as async here since it's already in background thread),
                    // but this will make testing simpler (timing control)
                    
                    self.sendActivateNotification(experiment: experiment,
                                                  variation: variation,
                                                  userId: userId,
                                                  attributes: attributes,
                                                  event: EventForDispatch(body: body),
                                                  async: false)
                }
            }
        }
        
    }
    
    func sendConversionEvent(eventKey: String,
                             userId: String,
                             attributes: OptimizelyAttributes? = nil,
                             eventTags: OptimizelyEventTags? = nil) {
        
        // non-blocking (event data serialization takes time)
        eventLock.async {
            guard let config = self.config else { return }
            
            guard let userEvent = ConversionEvent(userContext: UserContext(config: config, userId: userId, attributes: attributes),
                                            eventKey: eventKey,
                                            tags: eventTags) else {
                                                self.logger.e(OptimizelyError.eventBuildFailure(eventKey))
                                                return
            }
                            
            self.sendEventToDispatcher(event: userEvent) { result in
                if case .success(let body) = result {
                    // send notification in sync mode (functionally same as async here since it's already in background thread),
                    // but this will make testing simpler (timing control)
                    
                    self.sendTrackNotification(eventKey: eventKey,
                                               userId: userId,
                                               attributes: attributes,
                                               eventTags: eventTags,
                                               event: EventForDispatch(body: body),
                                               async: false)
                }
            }
        }
    }
    
    func sendEventToDispatcher(event: UserEvent, completionHandler: DispatchCompletionHandler?) {
        // deprecated
        if let eventDispatcher = self.eventDispatcher {
            if let body = try? JSONEncoder().encode(event.batchEvent) {
                let dataEvent = EventForDispatch(body: body)
                eventDispatcher.dispatchEvent(event: dataEvent, completionHandler: completionHandler)
            }
            return
        }
        
        // The event is queued in the dispatcher, batched, and sent out later.
        
        // make sure that eventDispatcher is not-nil (still registered when async dispatchEvent is called)
        eventProcessor?.process(event: event, completionHandler: completionHandler)
    }
    
}

// MARK: - Notifications

extension OptimizelyClient {
    
    func sendActivateNotification(experiment: Experiment,
                                  variation: Variation,
                                  userId: String,
                                  attributes: OptimizelyAttributes?,
                                  event: EventForDispatch,
                                  async: Bool = true) {
        
        self.sendNotification(type: .activate,
                              args: [experiment,
                                     userId,
                                     attributes,
                                     variation,
                                     ["url": event.url as Any, "body": event.body as Any]],
                              async: async)
    }
    
    func sendTrackNotification(eventKey: String,
                               userId: String,
                               attributes: OptimizelyAttributes?,
                               eventTags: OptimizelyEventTags?,
                               event: EventForDispatch,
                               async: Bool = true) {
        self.sendNotification(type: .track,
                              args: [eventKey,
                                     userId,
                                     attributes,
                                     eventTags,
                                     ["url": event.url as Any, "body": event.body as Any]],
                              async: async)
    }
    
    func sendDecisionNotification(decisionType: Constants.DecisionType,
                                  userId: String,
                                  attributes: OptimizelyAttributes?,
                                  experiment: Experiment? = nil,
                                  variation: Variation? = nil,
                                  feature: FeatureFlag? = nil,
                                  featureEnabled: Bool? = nil,
                                  variableKey: String? = nil,
                                  variableType: String? = nil,
                                  variableValue: Any? = nil,
                                  async: Bool = true) {
        self.sendNotification(type: .decision,
                              args: [decisionType.rawValue,
                                     userId,
                                     attributes ?? OptimizelyAttributes(),
                                     self.makeDecisionInfo(decisionType: decisionType,
                                                           experiment: experiment,
                                                           variation: variation,
                                                           feature: feature,
                                                           featureEnabled: featureEnabled,
                                                           variableKey: variableKey,
                                                           variableType: variableType,
                                                           variableValue: variableValue)],
                              async: async)
    }
    
    func sendDatafileChangeNotification(data: Data, async: Bool = true) {
        self.sendNotification(type: .datafileChange, args: [data], async: async)
    }
    
    func makeDecisionInfo(decisionType: Constants.DecisionType,
                          experiment: Experiment? = nil,
                          variation: Variation? = nil,
                          feature: FeatureFlag? = nil,
                          featureEnabled: Bool? = nil,
                          variableKey: String? = nil,
                          variableType: String? = nil,
                          variableValue: Any? = nil) -> [String: Any] {
        
        var decisionInfo = [String: Any]()
        
        switch decisionType {
        case .featureTest, .abTest:
            guard let experiment = experiment else { return decisionInfo }
            
            decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
            decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation?.key ?? NSNull()
            
        case .feature, .featureVariable:
            guard let feature = feature, let featureEnabled = featureEnabled else { return decisionInfo }
            
            decisionInfo[Constants.DecisionInfoKeys.feature] = feature.key
            decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = featureEnabled
            
            let decisionSource: Constants.DecisionSource = experiment != nil ? .featureTest : .rollout
            decisionInfo[Constants.DecisionInfoKeys.source] = decisionSource.rawValue
            
            var sourceInfo = [String: Any]()
            if let experiment = experiment, let variation = variation {
                sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
                sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation.key
            }
            decisionInfo[Constants.DecisionInfoKeys.sourceInfo] = sourceInfo
            
            // featureVariable
            
            if decisionType == .featureVariable {
                guard let variableKey = variableKey, let variableType = variableType, let variableValue = variableValue else {
                        return decisionInfo
                }
                
                decisionInfo[Constants.DecisionInfoKeys.variable] = variableKey
                decisionInfo[Constants.DecisionInfoKeys.variableType] = variableType
                decisionInfo[Constants.DecisionInfoKeys.variableValue] = variableValue
            }
        }

        return decisionInfo
    }
    
    func sendNotification(type: NotificationType, args: [Any?], async: Bool = true) {
        let notify = {
            // make sure that notificationCenter is not-nil (still registered when async notification is called)
            self.notificationCenter?.sendNotifications(type: type.rawValue, args: args)
        }
        
        if async {
            eventLock.async {
                notify()
            }
        } else {
            notify()
        }
    }

}

// MARK: - For test support

extension OptimizelyClient {
    
    public func close() {
        datafileHandler.stopUpdates(sdkKey: sdkKey)
        eventLock.sync {}
        
        // deprecated
        if let eventDispatcher = self.eventDispatcher {
            eventDispatcher.close()
            return
        }
        
        eventProcessor?.close()
    }
    
}
