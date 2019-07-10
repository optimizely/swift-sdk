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
    
    // MARK: - Customizable Services
    
    lazy var logger = OPTLoggerFactory.getLogger()
    
    var eventDispatcher: OPTEventDispatcher {
        return HandlerRegistryService.shared.injectEventDispatcher(sdkKey: self.sdkKey)!
    }
    
    // MARK: - Default Services
    
    var decisionService: OPTDecisionService {
        return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey)!
    }
    
    public var datafileHandler: OPTDatafileHandler {
        return HandlerRegistryService.shared.injectDatafileHandler(sdkKey: self.sdkKey)!
    }
    
    public var notificationCenter: OPTNotificationCenter {
        return HandlerRegistryService.shared.injectNotificationCenter(sdkKey: self.sdkKey)!
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
    public func start(resourceTimeout: Double? = nil, completion: ((OptimizelyResult<Data>) -> Void)?=nil) {
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
                    
                    self.notificationCenter.sendNotifications(type:
                        NotificationType.datafileChange.rawValue, args: [data])
                    
                }
            }
        } catch {
            // .datafileInvalid
            // .datafaileVersionInvalid
            // .datafaileLoadingFailed
            throw error
        }
    }
    
    func fetchDatafileBackground(resourceTimeout: Double? = nil, completion: ((OptimizelyResult<Data>) -> Void)?=nil) {
        
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
                         attributes: OptimizelyAttributes?=nil) throws -> String {
        
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
                                attributes: OptimizelyAttributes?=nil) throws -> String {
        
        let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        return variation.key
    }
    
    func getVariation(experimentKey: String,
                      userId: String,
                      attributes: OptimizelyAttributes?=nil) throws -> Variation {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        guard let experiment = config.getExperiment(key: experimentKey) else {
            throw OptimizelyError.experimentKeyInvalid(experimentKey)
        }
        
        let decisionType = config.isFeatureExperiment(id: experiment.id) ? Constants.DecisionTypeKeys.featureTest : Constants.DecisionTypeKeys.abTest
        var args: [Any?] = (self.notificationCenter as! DefaultNotificationCenter).getArgumentsForDecisionListener(notificationType: decisionType, userId: userId, attributes: attributes)

        var decisionInfo = [String: Any]()
        var sourceInfo = [String: Any]()
        sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
        sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] = NSNull()
        
        // fix DecisionService to throw error
        guard let variation = decisionService.getVariation(config: config, userId: userId, experiment: experiment, attributes: attributes ?? OptimizelyAttributes()) else {
            decisionInfo = sourceInfo
            args.append(decisionInfo)
            self.notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: args)
            throw OptimizelyError.variationUnknown(userId, experimentKey)
        }
        
        sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation.key
        decisionInfo = sourceInfo
        
        args.append(decisionInfo)
        self.notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: args)
        
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
                                 attributes: OptimizelyAttributes?=nil) -> Bool {
        
        guard let config = self.config else {
            logger.e(.sdkNotReady)
            return false
        }
        
        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            logger.e(.featureKeyInvalid(featureKey))
            return false
        }
        
        // fix DecisionService to throw error
        let pair = decisionService.getVariationForFeature(config: config, featureFlag: featureFlag, userId: userId, attributes: attributes ?? OptimizelyAttributes())
        
        var args: [Any?] = (self.notificationCenter as! DefaultNotificationCenter).getArgumentsForDecisionListener(notificationType: Constants.DecisionTypeKeys.feature, userId: userId, attributes: attributes)
        
        var decisionInfo = [String: Any]()
        decisionInfo[Constants.DecisionInfoKeys.feature] = featureKey
        decisionInfo[Constants.DecisionInfoKeys.source] = Constants.DecisionSource.rollout
        decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = false
        decisionInfo[Constants.DecisionInfoKeys.sourceInfo] = [:]
        
        guard let variation = pair?.variation else {
            args.append(decisionInfo)
            self.notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: args)
            logger.i(.variationUnknown(userId, featureKey))
            return false
        }
        
        let featureEnabled = variation.featureEnabled ?? false
    
        if featureEnabled {
            logger.i(.featureEnabledForUser(featureKey, userId))
        } else {
            logger.i(.featureNotEnabledForUser(featureKey, userId))
        }

        // we came from an experiment if experiment is not nil
        if let experiment = pair?.experiment {
            
            var sourceInfo = [String: Any]()
            sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
            sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation.key
            decisionInfo[Constants.DecisionInfoKeys.sourceInfo] = sourceInfo

            sendImpressionEvent(experiment: experiment, variation: variation, userId: userId, attributes: attributes)
        }
        
        decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = featureEnabled
        decisionInfo[Constants.DecisionInfoKeys.source] = (pair?.experiment != nil ? Constants.DecisionSource.featureTest : Constants.DecisionSource.rollout)
        args.append(decisionInfo)
        self.notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: args)
        
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
                                          attributes: OptimizelyAttributes?=nil) throws -> Bool {
        
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
                                         attributes: OptimizelyAttributes?=nil) throws -> Double {
        
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
                                          attributes: OptimizelyAttributes?=nil) throws -> Int {
        
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
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        // fix config to throw errors
        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            throw OptimizelyError.featureKeyInvalid(featureKey)
        }
        
        guard let variable = featureFlag.getVariable(key: variableKey) else {
            throw OptimizelyError.variableKeyInvalid(variableKey, featureKey)
        }
        
        var decisionInfo = [String: Any]()
        decisionInfo[Constants.DecisionInfoKeys.sourceInfo] = [:]
        
        var featureValue = variable.defaultValue ?? ""
        
        var finalAttributes = OptimizelyAttributes()
        if let attributes = attributes {
            finalAttributes = attributes
        }
        let decision = self.decisionService.getVariationForFeature(config: config, featureFlag: featureFlag, userId: userId, attributes: finalAttributes)
        if let decision = decision {
            if let experiment = decision.experiment {
                var sourceInfo = [String: Any]()
                sourceInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
                sourceInfo[Constants.ExperimentDecisionInfoKeys.variation] = decision.variation?.key
                decisionInfo[Constants.DecisionInfoKeys.sourceInfo] = sourceInfo
            }
            
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
        
        var args: [Any?] = (self.notificationCenter as! DefaultNotificationCenter).getArgumentsForDecisionListener(notificationType: Constants.DecisionTypeKeys.featureVariable, userId: userId, attributes: finalAttributes)
        
        decisionInfo[Constants.DecisionInfoKeys.feature] = featureKey
        decisionInfo[Constants.DecisionInfoKeys.featureEnabled] = decision?.variation?.featureEnabled ?? false
        decisionInfo[Constants.DecisionInfoKeys.variable] = variableKey
        decisionInfo[Constants.DecisionInfoKeys.variableType] = typeName
        decisionInfo[Constants.DecisionInfoKeys.variableValue] = value
        decisionInfo[Constants.DecisionInfoKeys.source] = (decision?.experiment != nil ? Constants.DecisionSource.featureTest : Constants.DecisionSource.rollout)
        args.append(decisionInfo)
    
        self.notificationCenter.sendNotifications(type: NotificationType.decision.rawValue, args: args)
        
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
                                   attributes: OptimizelyAttributes?=nil) -> [String] {
        
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
                      attributes: OptimizelyAttributes?=nil,
                      eventTags: OptimizelyEventTags?=nil) throws {
        
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        
        if config.getEvent(key: eventKey) == nil {
            throw OptimizelyError.eventKeyInvalid(eventKey)
        }
        
        sendConversionEvent(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: eventTags)
    }
    
}

extension OptimizelyClient {
    
    func sendImpressionEvent(experiment: Experiment,
                             variation: Variation,
                             userId: String,
                             attributes: OptimizelyAttributes?=nil) {
     
        guard let config = self.config else { return }
        
        guard let body = BatchEventBuilder.createImpressionEvent(config: config,
                                                                 experiment: experiment,
                                                                 varionation: variation,
                                                                 userId: userId,
                                                                 attributes: attributes) else {
            self.logger.e(OptimizelyError.eventBuildFailure(DispatchEvent.activateEventKey))
            return
        }
        
        let event = EventForDispatch(body: body)
        // because we are batching events, we cannot guarantee that the completion handler will be
        // called.  So, for now, we are queuing and calling onActivate.  Maybe we should mention that
        // onActivate only means the event has been queued and not necessarily sent.
        self.eventDispatcher.dispatchEvent(event: event, completionHandler: nil)
        
        self.notificationCenter.sendNotifications(type: NotificationType.activate.rawValue, args: [experiment, userId, attributes, variation, ["url": event.url as Any, "body": event.body as Any]])

    }
    
    func sendConversionEvent(eventKey: String,
                             userId: String,
                             attributes: OptimizelyAttributes?=nil,
                             eventTags: OptimizelyEventTags?=nil) {
        
        guard let config = self.config else { return }
        
        guard let body = BatchEventBuilder.createConversionEvent(config: config,
                                                                 eventKey: eventKey,
                                                                 userId: userId,
                                                                 attributes: attributes,
                                                                 eventTags: eventTags) else {
            self.logger.e(OptimizelyError.eventBuildFailure(eventKey))
            return
        }
        
        let event = EventForDispatch(body: body)
        // because we are batching events, we cannot guarantee that the completion handler will be
        // called.  So, for now, we are queuing and calling onTrack.  Maybe we should mention that
        // onTrack only means the event has been queued and not necessarily sent.
        self.eventDispatcher.dispatchEvent(event: event, completionHandler: nil)
        
        self.notificationCenter.sendNotifications(type: NotificationType.track.rawValue, args: [eventKey, userId, attributes, eventTags, ["url": event.url as Any, "body": event.body as Any]])

    }
}
