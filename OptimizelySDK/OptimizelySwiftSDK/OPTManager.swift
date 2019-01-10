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
    var config:ProjectConfig!
    var datafileHandler:DatafileHandler!
    
    // MARK: - Public properties (customization allowed)
    
    let logger: Logger
    let bucketer: Bucketer
    let decisionService: DecisionService
    let config: ProjectConfig
    let eventDispatcher: EventDispatcher
    let datafileHandler: DatafileHandler
    let userProfileService: UserProfileService
    let notificationCenter: NotificationCenter
    
    let periodicDownloadInterval:Int

    
    // MARK: - Public interfaces
    
    /// Initialize Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - bucketer: custom Bucketer
    ///   - ...
    public init(sdkKey: String,
                logger:Logger? = nil,
                bucketer:Bucketer? = nil,
                decisionService:DecisionService? = nil,
                eventDispatcher:EventDispatcher? = nil,
                datafileHandler:DatafileHandler? = nil,
                userProfileService:UserProfileService? = nil,
                notificationCenter:NotificationCenter? = nil,
                periodicDownloadInterval:Int? = nil) {
        
        self.sdkKey = sdkKey
        
        // default services (can be customized by clients
        
        self.logger = logger ?? DefaultLogger(level: .error)
        self.bucketer = bucketer ?? DefaultBucketer()
        self.decisionService = decisionService ?? DefaultDecisionService()
        self.eventDispatcher = eventDispatcher ?? DefaultEventDispatcher()
        self.datafileHandler = datafileHandler ?? DefaultDatafileHandler()
        self.userProfileService = userProfileService ?? DefaultUserProfileService()
        self.notificationCenter = notificationCenter ?? DefaultNotificationCenter()
        self.periodicDownloadInterval = periodicDownloadInterval ?? (5 * 60)
    }
    
    /// Initialize Optimizely Manager
    ///
    /// - Parameters:
    ///   - datafile: when given, this datafile will be used when cached copy is not available (fresh start)
    ///                       a cached copy from previous download is used if it's available
    ///                       the datafile will be updated from the server in the background thread
    ///   - completion: callback when initialization is completed
    public func initializeSDK(completion: ((OPTResult) -> Void)?=nil) {
        
        fetchDatafileBackground() { result in
            
            switch result {
            case .failure(let err):
                completion?(result)
            case .success(let datafileData):
                
                do {
                    try configSDK(datafile: datafileData)
                } catch {
                    // current cached copy has error
                    // continue to fetch datafile from server
                }
                
            }

            completion?(result)
        }
    }
    
    // MARK: synchronous initialization
    
    public func initializeSDK(datafile: String) throws {
        guard let datafileData = datafile.data(using: .utf8) else {
            throw OPTError.dataFileInvalid
        }
        
        try initializeSDK(datafile: datafileData)
    }
    
    public func initializeSDK(datafile: Data) throws {
        
        // TODO: get the cached copy
        let cachedDatafile: Data?

        let selectedDatafile = cachedDatafile ?? datafile
        
        do {
            try configSDK(datafileData: selectedDatafile)
        } catch {
            // current cached copy has error
            // continue to fetch datafile from server
        }
        
        fetchDatafileBackground()
    }
    
    func configSDK(datafileData:Data) throws {
        config = try! JSONDecoder().decode(ProjectConfig.self, from: datafileData)
        
        if let config = config, let bucketer = DefaultBucketer.createInstance(config: config) {
            decisionService = DefaultDecisionService.createInstance(config: config, bucketer: bucketer, userProfileService: userProfileService)
        } else {
            throw OPTError.dataFileInvalid
        }
    }
    
    func fetchDatafileBackground(completion: ((OPTResult) -> Void)?=nil) {
        datafileHandler.downloadDatafile(sdkKey: self.sdkKey){ result in
            switch result {
            case .failure(let err):
                self.logger.log(level: .error, message: err.description)
                completion?(result)
            case .success:
                completion?(result)
            }
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
    public func activate(experimentKey:String,
                         userId:String,
                         attributes:Dictionary<String, Any>?=nil) throws -> String {
        
        guard let experiment = config.experiments.filter({$0.key == experimentKey}).first else {
            throw OPTError.experimentUnknown(experimentKey)
            
        }
        
        
            let variation = try getVariation(experimentKey: experimentKey, userId: userId, attributes: attributes)
            
            if let body = BatchEventBuilder.createImpressionEvent(config: config!, decisionService: decisionService!, experiment: experiment, varionation: variation, userId: userId, attributes: attributes) {
                let event = EventForDispatch(body: body)
                eventDispatcher?.dispatchEvent(event: event, completionHandler: { (result) -> (Void) in
                    switch result {
                    case .failure(let error):
                        self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelError, message: "Failed to dispatch event " + error.localizedDescription)
                    case .success( _):
                        self.notificationCenter?.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any, "body":event.body as Any]])
                    }
                })
                return variation
            }
            
            return variation
        }
        
        return nil

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
                      attributes:Dictionary<String, Any>?=nil) throws -> Variation {
        
        if let experiment = config?.experiments.filter({$0.key == experimentKey}).first,
            let variation = decisionService?.getVariation(userId: userId, experiment: experiment, attributes: attributes ?? [:]) {
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
        return nil
    }
    
    /// Set forced variation for experiment and user ID to variationKey.
    ///
    /// - Parameters:
    ///   - experimentKey The key for the experiment.
    ///   - userId The user ID to be used for bucketing.
    ///   - variationKey The variation the user should be forced into.
    ///                  This value can be nil, in which case, the forced variation is cleared.
    /// - Returns: true if no error is detected, false otherwise.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func setForcedVariation(experimentKey:String,
                                   userId:String,
                                   variationKey:String) throws -> Bool {
        return false
    }
    
    /// Determine whether a feature is enabled.
    ///
    /// - Parameters:
    ///   - featureKey The key for the feature flag.
    ///   - userId The user ID to be used for bucketing.
    ///   - attributes The user's attributes.
    /// - Returns: true if feature is enabled, false otherwise.
    /// - Throws: `OPTError` if feature parameter is not valid
    public func isFeatureEnabled(featureKeyy:String,
                                 userId:String,
                                 attributes:Dictionary<String,Any>?=nil) throws -> Bool {
        return false
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
        return false
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
        return 0.0
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
        return 0
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
    public func getFeatureVariableString(featureKey:String,
                                         variableKey:String,
                                         userId:String,
                                         attributes:Dictionary<String, Any>?=nil) throws -> String {
        return String()
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
        return [String]()
    }
    
    /// Track an event
    ///
    /// - Parameters:
    ///   - eventKey: The event name
    ///   - userId: The user ID associated with the event to track
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
    /// - Throws: `OPTError` if event parameter is not valid
    public func track(eventKey:String,
                      userId:String,
                      eventTags:Dictionary<String,Any>?=nil) throws {
        
    }
    
}
