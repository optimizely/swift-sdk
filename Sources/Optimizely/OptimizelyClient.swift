/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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

    private var atomicConfig = AtomicProperty<ProjectConfig>()
    var config: ProjectConfig? {
        get {
            return atomicConfig.property
        }
        set {
            atomicConfig.property = newValue
        }
    }
    
    var defaultDecideOptions: [OptimizelyDecideOption]

    public var version: String {
        return Utils.sdkVersion
    }
    
    let eventLock = DispatchQueue(label: "com.optimizely.client")
    
    private var isPeriodicPollingEnabled: Bool {
        if let handler = datafileHandler as? DefaultDatafileHandler {
            return handler.hasPeriodUpdates(sdkKey: sdkKey)
        } else {
            return false
        }
    }

    // MARK: - Customizable Services
    
    lazy var logger = OPTLoggerFactory.getLogger()
    
    var eventDispatcher: OPTEventDispatcher? {
        return HandlerRegistryService.shared.injectEventDispatcher(sdkKey: self.sdkKey)
    }
    
    // MARK: - Default Services
    
    var decisionService: OPTDecisionService {
        return HandlerRegistryService.shared.injectDecisionService(sdkKey: self.sdkKey)!
    }
    
    public var datafileHandler: OPTDatafileHandler? {
        return HandlerRegistryService.shared.injectDatafileHandler(sdkKey: self.sdkKey)
    }
    
    public var notificationCenter: OPTNotificationCenter? {
        return HandlerRegistryService.shared.injectNotificationCenter(sdkKey: self.sdkKey)
    }

    // MARK: - Public interfaces
    
    /// OptimizelyClient init
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - eventDispatcher: custom EventDispatcher (optional)
    ///   - userProfileService: custom UserProfileService (optional)
    ///   - defaultLogLevel: default log level (optional. default = .info)
    ///   - defaultDecisionOptions: default decision optiopns (optional)
    public init(sdkKey: String,
                logger: OPTLogger? = nil,
                eventDispatcher: OPTEventDispatcher? = nil,
                userProfileService: OPTUserProfileService? = nil,
                defaultLogLevel: OptimizelyLogLevel? = nil,
                defaultDecideOptions: [OptimizelyDecideOption]? = nil) {
        
        self.sdkKey = sdkKey
        self.defaultDecideOptions = defaultDecideOptions ?? []
        
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
        datafileHandler?.downloadDatafile(sdkKey: sdkKey, returnCacheIfNoChange: true, resourceTimeoutInterval: resourceTimeout) { result in
            switch result {
            case .success(let datafile):
                guard let datafile = datafile else {
                    completion?(.failure(.datafileLoadingFailed(self.sdkKey)))
                    return
                }
                
                do {
                    try self.configSDK(datafile: datafile)
                    completion?(.success(datafile))
                } catch {
                    completion?(.failure(error as! OptimizelyError))
                }
            case .failure(let error):
                completion?(.failure(error))
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
    ///   - doUpdateConfigOnNewDatafile: When a new datafile is fetched from the server in the background thread,
    ///             the SDK will be updated with the new datafile immediately if this value is set to true.
    ///             When it's set to false (default), the new datafile is cached and will be used when the SDK is started again.
    ///   - doFetchDatafileBackground: This is for debugging purposes when
    ///             you don't want to download the datafile.  In practice, you should allow the
    ///             background thread to update the cache copy (optional)
    public func start(datafile: Data,
                      doUpdateConfigOnNewDatafile: Bool = false,
                      doFetchDatafileBackground: Bool = true) throws {
        let cachedDatafile = self.sdkKey.isEmpty ? nil :datafileHandler?.loadSavedDatafile(sdkKey: self.sdkKey)
        let selectedDatafile = cachedDatafile ?? datafile
        
        try configSDK(datafile: selectedDatafile)
        
        // continue to fetch updated datafile from the server in background and cache it for next sessions
        
        if !doFetchDatafileBackground { return }
        
        datafileHandler?.downloadDatafile(sdkKey: sdkKey, returnCacheIfNoChange: false) { result in
            // override to update always if periodic datafile polling is enabled
            // this is necessary for the case that the first cache download gets the updated datafile
            guard doUpdateConfigOnNewDatafile || self.isPeriodicPollingEnabled else { return }
            
            if case .success(let data) = result, let datafile = data {
                // new datafile came in
                self.updateConfigFromBackgroundFetch(data: datafile)
            }
        }
    }
    
    func configSDK(datafile: Data) throws {
        do {
            self.config = try ProjectConfig(datafile: datafile)

            datafileHandler?.startUpdates(sdkKey: self.sdkKey) { data in
                // new datafile came in
                self.updateConfigFromBackgroundFetch(data: data)
            }
        } catch let error as OptimizelyError {
            // .datafileInvalid
            // .datafaileVersionInvalid
            // .datafaileLoadingFailed
            self.logger.e(error)
            throw error
        } catch {
            self.logger.e(error.localizedDescription)
            throw error
        }
    }
    
    func updateConfigFromBackgroundFetch(data: Data) {
        guard let config = try? ProjectConfig(datafile: data) else {
            return
        }
        
        // if a download fails for any reason, the cached datafile is returned
        // check and see if the revisions are the same and don't update if they are
        guard config.project.revision != self.config?.project.revision else {
            return
        }
        
        if let users = self.config?.whitelistUsers {
            config.whitelistUsers = users
        }
        
        self.config = config
        
        // call reinit on the services we know we are reinitializing.
        
        for component in HandlerRegistryService.shared.lookupComponents(sdkKey: self.sdkKey) ?? [] {
            HandlerRegistryService.shared.reInitializeComponent(service: component, sdkKey: self.sdkKey)
        }

        self.sendDatafileChangeNotification(data: data)
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
                                                     attributes: attributes ?? OptimizelyAttributes(),
                                                     options: nil)
        
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
                                                          attributes: attributes ?? OptimizelyAttributes(),
                                                          options: nil)
        
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
    
    /// Gets json feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type OptimizelyJSON.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getFeatureVariableJSON(featureKey: String,
                                       variableKey: String,
                                       userId: String,
                                       attributes: OptimizelyAttributes? = nil) throws -> OptimizelyJSON {
        
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
                                                                   attributes: attributes ?? OptimizelyAttributes(),
                                                                   options: nil)
        if let decision = decision {
            if let featureVariable = decision.variation?.variables?.filter({$0.id == variable.id}).first {
                if let featureEnabled = decision.variation?.featureEnabled, featureEnabled {
                    featureValue = featureVariable.value
                    logger.i(.userReceivedVariableValue(featureValue, variableKey, featureKey))
                } else {
                    logger.i(.featureNotEnabledReturnDefaultVariableValue(userId, featureKey, variableKey))
                }
            }
        } else {
            logger.i(.userReceivedDefaultVariableValue(userId, featureKey, variableKey))
        }
        
        var type: Constants.VariableValueType?
        var valueParsed: T?
        var notificationValue: Any? = featureValue
        
        switch T.self {
        case is String.Type:
            type = .string
            valueParsed = featureValue as? T
            notificationValue = valueParsed
        case is Int.Type:
            type = .integer
            valueParsed = Int(featureValue) as? T
            notificationValue = valueParsed
        case is Double.Type:
            type = .double
            valueParsed = Double(featureValue) as? T
            notificationValue = valueParsed
        case is Bool.Type:
            type = .boolean
            valueParsed = Bool(featureValue) as? T
            notificationValue = valueParsed
        case is OptimizelyJSON.Type:
            type = .json
            let jsonValue = OptimizelyJSON(payload: featureValue)
            valueParsed = jsonValue as? T
            notificationValue = jsonValue?.toMap()
        default:
            break
        }
        
        guard let value = valueParsed,
            type?.rawValue == variable.type else {
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
                                 variableType: variable.type,
                                 variableValue: notificationValue)
        
        return value
    }
    
    /// Gets all the variables for a given feature.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: all the variables for a given feature.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func getAllFeatureVariables(featureKey: String,
                                       userId: String,
                                       attributes: OptimizelyAttributes? = nil) throws -> OptimizelyJSON {
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }
        var variableMap = [String: Any]()
        var enabled = false
        
        guard let featureFlag = config.getFeatureFlag(key: featureKey) else {
            throw OptimizelyError.featureKeyInvalid(featureKey)
        }
        
        let decision = self.decisionService.getVariationForFeature(config: config,
                                                                   featureFlag: featureFlag,
                                                                   userId: userId,
                                                                   attributes: attributes ?? OptimizelyAttributes(),
                                                                   options: nil)
        if let featureEnabled = decision?.variation?.featureEnabled {
            enabled = featureEnabled
            if featureEnabled {
                logger.i(.featureEnabledForUser(featureKey, userId))
            } else {
                logger.i(.featureNotEnabledForUser(featureKey, userId))
            }
        } else {
            logger.i(.userReceivedAllDefaultVariableValues(userId, featureKey))
        }
        
        for (_, v) in featureFlag.variablesMap {
            var featureValue = v.value
            if enabled, let variable = decision?.variation?.getVariable(id: v.id) {
                featureValue = variable.value
            }
            
            var valueParsed: Any? = featureValue
            
            if let valueType = Constants.VariableValueType(rawValue: v.type) {
                switch valueType {
                case .string:
                    break
                case .integer:
                    valueParsed = Int(featureValue)
                    break
                case .double:
                    valueParsed = Double(featureValue)
                    break
                case .boolean:
                    valueParsed = Bool(featureValue)
                    break
                case .json:
                    valueParsed = OptimizelyJSON(payload: featureValue)?.toMap()
                    break
                }
            }

            if let value = valueParsed {
                variableMap[v.key] = value
            } else {
                logger.e(OptimizelyError.variableValueInvalid(v.key))
            }
        }
        
        guard let optimizelyJSON = OptimizelyJSON(map: variableMap) else {
            throw OptimizelyError.invalidJSONVariable
        }
        
        sendDecisionNotification(decisionType: .allFeatureVariables,
                                 userId: userId,
                                 attributes: attributes,
                                 experiment: decision?.experiment,
                                 variation: decision?.variation,
                                 feature: featureFlag,
                                 featureEnabled: enabled,
                                 variableValues: variableMap)
        return optimizelyJSON
    }
    
    /// Get array of features that are enabled for the user.
    ///
    /// - Parameters:
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: Array of feature keys that are enabled for the user.
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
        
    /// Read a copy of project configuration data model.
    ///
    /// This call returns a snapshot of the current project configuration.
    ///
    /// When the caller keeps a copy of the return value, note that this data can be stale when a new datafile is downloaded (it's possible only when background datafile polling is enabled).
    ///
    /// If a datafile change is notified (NotificationType.datafileChange), this method should be called again to get the updated configuration data.
    ///
    /// - Returns: a snapshot of public project configuration data model
    /// - Throws: `OptimizelyError` if SDK is not ready
    public func getOptimizelyConfig() throws -> OptimizelyConfig {
        guard let config = self.config else { throw OptimizelyError.sdkNotReady }

        return OptimizelyConfigImp(projectConfig: config)
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

            guard let body = BatchEventBuilder.createImpressionEvent(config: config,
                                                                     experiment: experiment,
                                                                     varionation: variation,
                                                                     userId: userId,
                                                                     attributes: attributes) else {
                                                                        self.logger.e(OptimizelyError.eventBuildFailure(DispatchEvent.activateEventKey))
                                                                        return
            }
            
            let event = EventForDispatch(body: body)
            self.sendEventToDispatcher(event: event, completionHandler: nil)
            
            // send notification in sync mode (functionally same as async here since it's already in background thread),
            // but this will make testing simpler (timing control)

            self.sendActivateNotification(experiment: experiment,
                                          variation: variation,
                                          userId: userId,
                                          attributes: attributes,
                                          event: event,
                                          async: false)
        }

    }
    
    func sendConversionEvent(eventKey: String,
                             userId: String,
                             attributes: OptimizelyAttributes? = nil,
                             eventTags: OptimizelyEventTags? = nil) {
        
        // non-blocking (event data serialization takes time)
        eventLock.async {
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
            self.sendEventToDispatcher(event: event, completionHandler: nil)
            
            // send notification in sync mode (functionally same as async here since it's already in background thread),
            // but this will make testing simpler (timing control)

            self.sendTrackNotification(eventKey: eventKey,
                                       userId: userId,
                                       attributes: attributes,
                                       eventTags: eventTags,
                                       event: event,
                                       async: false)
        }
    }
    
    func sendEventToDispatcher(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
        // The event is queued in the dispatcher, batched, and sent out later.
        
        // make sure that eventDispatcher is not-nil (still registered when async dispatchEvent is called)
        self.eventDispatcher?.dispatchEvent(event: event, completionHandler: completionHandler)
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
                                  variableValues: [String: Any]? = nil,
                                  ruleKey: String? = nil,
                                  reasons: [String]? = nil,
                                  sentEvent: Bool = false,
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
                                                           variableValue: variableValue,
                                                           variableValues: variableValues,
                                                           ruleKey: ruleKey,
                                                           reasons: reasons,
                                                           sentEvent: sentEvent)],
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
                          variableValue: Any? = nil,
                          variableValues: [String: Any]? = nil,
                          ruleKey: String? = nil,
                          reasons: [String]? = nil,
                          sentEvent: Bool = false) -> [String: Any] {
        
        var decisionInfo = [String: Any]()
        
        switch decisionType {
        case .featureTest, .abTest:
            guard let experiment = experiment else { return decisionInfo }
            
            decisionInfo[Constants.ExperimentDecisionInfoKeys.experiment] = experiment.key
            decisionInfo[Constants.ExperimentDecisionInfoKeys.variation] = variation?.key ?? NSNull()
            
        case .feature, .featureVariable, .allFeatureVariables:
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
            } else if  decisionType == .allFeatureVariables {
                guard let variableValues = variableValues else {
                    return decisionInfo
                }
                decisionInfo[Constants.DecisionInfoKeys.variableValues] = variableValues
            }
            
        // Decide-APIs
            
        case .flag:
            guard let flagKey = feature?.key, let enabled = featureEnabled else { return decisionInfo }
            
            decisionInfo[Constants.DecisionInfoKeys.flagKey] = flagKey
            decisionInfo[Constants.DecisionInfoKeys.enabled] = enabled
            decisionInfo[Constants.DecisionInfoKeys.variables] = variableValues
            decisionInfo[Constants.DecisionInfoKeys.variationKey] = variation?.key
            decisionInfo[Constants.DecisionInfoKeys.ruleKey] = ruleKey
            decisionInfo[Constants.DecisionInfoKeys.reasons] = reasons
            decisionInfo[Constants.DecisionInfoKeys.decisionEventDispatched] = sentEvent
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
        datafileHandler?.stopUpdates(sdkKey: sdkKey)
        eventLock.sync {}
        eventDispatcher?.close()
    }
    
}
