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

extension OptimizelyClient {
    
    @available(swift, obsoleted: 1.0)
    /// Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    @objc public convenience init(sdkKey: String) {
        self.init(sdkKey: sdkKey,
                  logger: nil,
                  eventProcessor: nil,
                  eventHandler: nil,
                  userProfileService: nil,
                  periodicDownloadInterval: nil as NSNumber?,
                  defaultLogLevel: .info)
    }
    
    /// Optimizely Manager
    ///
    /// - Parameters:
    ///   - sdkKey: sdk key
    ///   - logger: custom Logger
    ///   - eventDispatcher: custom EventDispatcher (optional)
    ///   - userProfileService: custom UserProfileService (optional)
    ///   - periodicDownloadInterval: custom interval for periodic background datafile download (optional. default = 10 * 60 secs)
    ///   - defaultLogLevel: default log level (optional. default = .info)
    @objc public convenience init(sdkKey: String,
                                  logger: OPTLogger?,
                                  eventProcessor: _ObjcOPTEventProcessor?,
                                  eventHandler: _ObjcOPTEventHandler?,
                                  userProfileService: OPTUserProfileService?,
                                  periodicDownloadInterval: NSNumber?,
                                  defaultLogLevel: OptimizelyLogLevel) {
        self.init(sdkKey: sdkKey,
                  logger: logger,
                  eventProcessor: SwiftEventProcessor(eventProcessor),
                  eventHandler: SwiftEventHandler(eventHandler),
                  userProfileService: userProfileService,
                  periodicDownloadInterval: periodicDownloadInterval?.intValue,
                  defaultLogLevel: defaultLogLevel)
        
    }
    
    // deprecated
    @objc public convenience init(sdkKey: String,
                                  logger: OPTLogger?,
                                  eventDispatcher: _ObjcOPTEventDispatcher?,
                                  userProfileService: OPTUserProfileService?,
                                  periodicDownloadInterval: NSNumber?,
                                  defaultLogLevel: OptimizelyLogLevel) {
        self.init(sdkKey: sdkKey,
                  logger: logger,
                  eventDispatcher: SwiftEventDispatcher(eventDispatcher),
                  userProfileService: userProfileService,
                  periodicDownloadInterval: periodicDownloadInterval?.intValue,
                  defaultLogLevel: defaultLogLevel)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(startWithCompletion:)
    /// Start Optimizely SDK (Asynchronous)
    ///
    /// If an updated datafile is available in the server, it's downloaded and the SDK is configured with
    /// the updated datafile.
    ///
    /// - Parameters:
    ///   - completion: callback when initialization is completed
    public func objcStart(completion: ((Data?, NSError?) -> Void)?) {
        start { result in
            switch result {
            case .failure(let error):
                completion?(nil, error as NSError)
            case .success(let data):
                completion?(data, nil)
            }
        }
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(startWithDatafile:error:)
    /// Start Optimizely SDK (Synchronous)
    ///
    /// - Parameters:
    ///   - datafile: This datafile will be used when cached copy is not available (fresh start).
    ///             A cached copy from previous download is used if it's available.
    ///             The datafile will be updated from the server in the background thread.
    public func objcStartWith(datafile: String) throws {
        try self.start(datafile: datafile)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(startWithDatafile:doFetchDatafileBackground:error:)
    /// Start Optimizely SDK (Synchronous)
    ///
    /// - Parameters:
    ///   - datafile: This datafile will be used when cached copy is not available (fresh start)
    ///             A cached copy from previous download is used if it's available.
    ///             The datafile will be updated from the server in the background thread.
    ///   - doFetchDatafileBackground: This is for debugging purposes when
    ///             you don't want to download the datafile.  In practice, you should allow the
    ///             background thread to update the cache copy (optional)
    public func objcStart(datafile: Data, doFetchDatafileBackground: Bool = true) throws {
        try self.start(datafile: datafile, doFetchDatafileBackground: doFetchDatafileBackground)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(activateWithExperimentKey:userId:attributes:error:)
    /// Try to activate an experiment based on the experiment key and user ID with user attributes.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: The variation key the user was bucketed into
    /// - Throws: `OptimizelyError` if error is detected
    public func objcActivate(experimentKey: String,
                             userId: String,
                             attributes: [String: Any]?) throws -> String {
        return try self.activate(experimentKey: experimentKey, userId: userId, attributes: attributes as OptimizelyAttributes?)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getVariationKeyWithExperimentKey:userId:attributes:error:)
    /// Get variation for experiment and user ID with user attributes.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: A map of attribute names to current user attribute values.
    /// - Returns: The variation key the user was bucketed into
    /// - Throws: `OptimizelyError` if error is detected
    public func objcGetVariationKey(experimentKey: String,
                                    userId: String,
                                    attributes: [String: Any]?) throws -> String {
        return try getVariationKey(experimentKey: experimentKey,
                                   userId: userId,
                                   attributes: attributes)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getForcedVariationWithExperimentKey:userId:)
    /// Get forced variation for experiment and user ID.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    /// - Returns: forced variation key if it exists, otherwise return nil.
    public func objcGetForcedVariation(experimentKey: String, userId: String) -> String? {
        return getForcedVariation(experimentKey: experimentKey,
                                  userId: userId)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(setForcedVariationWithExperimentKey:userId:variationKey:)
    /// Set forced variation for experiment and user ID to variationKey.
    ///
    /// - Parameters:
    ///   - experimentKey: The key for the experiment.
    ///   - userId: The user ID to be used for bucketing.
    ///   - variationKey: The variation the user should be forced into.
    ///                  This value can be nil, in which case, the forced variation is cleared.
    /// - Returns: true if forced variation set successfully
    public func objcSetForcedVariation(experimentKey: String,
                                       userId: String,
                                       variationKey: String?) -> Bool {
        return setForcedVariation(experimentKey: experimentKey,
                                  userId: userId,
                                  variationKey: variationKey)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(isFeatureEnabledWithFeatureKey:userId:attributes:)
    /// Determine whether a feature is enabled.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: true if feature is enabled, false otherwise.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func objcIsFeatureEnabled(featureKey: String,
                                     userId: String,
                                     attributes: [String: Any]?) -> Bool {
        let enabled = self.isFeatureEnabled(featureKey: featureKey,
                                            userId: userId,
                                            attributes: attributes)
        return enabled
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableBooleanWithFeatureKey:variableKey:userId:attributes:error:)
    /// Gets boolean feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type boolean.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func objcGetFeatureVariableBoolean(featureKey: String,
                                              variableKey: String,
                                              userId: String,
                                              attributes: [String: Any]?) throws -> NSNumber {
        let value = try self.getFeatureVariableBoolean(featureKey: featureKey,
                                                       variableKey: variableKey,
                                                       userId: userId,
                                                       attributes: attributes)
        return value as NSNumber
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableDoubleWithFeatureKey:variableKey:userId:attributes:error:)
    /// Gets double feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type double.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func objcGetFeatureVariableDouble(featureKey: String,
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
    /// Gets integer feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type integer.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func objcGetFeatureVariableInteger(featureKey: String,
                                              variableKey: String,
                                              userId: String,
                                              attributes: [String: Any]?) throws -> NSNumber {
        let value = try self.getFeatureVariableInteger(featureKey: featureKey,
                                                       variableKey: variableKey,
                                                       userId: userId,
                                                       attributes: attributes)
        return value as NSNumber
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getFeatureVariableStringWithFeatureKey:variableKey:userId:attributes:error:)
    /// Gets string feature variable value.
    ///
    /// - Parameters:
    ///   - featureKey: The key for the feature flag.
    ///   - variableKey: The key for the variable.
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: feature variable value of type string.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func objcGetFeatureVariableString(featureKey: String,
                                             variableKey: String,
                                             userId: String,
                                             attributes: [String: Any]?) throws -> String {
        return try self.getFeatureVariableString(featureKey: featureKey,
                                                 variableKey: variableKey,
                                                 userId: userId,
                                                 attributes: attributes)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(getEnabledFeaturesWithUserId:attributes:)
    /// Get array of features that are enabled for the user.
    ///
    /// - Parameters:
    ///   - userId: The user ID to be used for bucketing.
    ///   - attributes: The user's attributes.
    /// - Returns: Array of feature keys that are enabled for the user.
    /// - Throws: `OptimizelyError` if feature parameter is not valid
    public func objcGetEnabledFeatures(userId: String,
                                       attributes: [String: Any]?) -> [String] {
        return self.getEnabledFeatures(userId: userId, attributes: attributes)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(trackWithEventKey:userId:attributes:eventTags:error:)
    /// Track an event
    ///
    /// - Parameters:
    ///   - eventKey: The event name
    ///   - userId: The user ID associated with the event to track
    ///   - eventTags: A map of event tag names to event tag values (NSString or NSNumber containing float, double, integer, or boolean)
    /// - Throws: `OptimizelyError` if event parameter is not valid
    public func objcTrack(eventKey: String,
                          userId: String,
                          attributes: [String: Any]?,
                          eventTags: [String: Any]?) throws {
        try self.track(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: eventTags)
    }
    
}

// MARK: - ObjC Type Conversions

extension OptimizelyClient {
    
    /// EventProcessor implementation for Objective-C interface support
    class SwiftEventProcessor: OPTEventProcessor {
        let objcEventProcessor: _ObjcOPTEventProcessor
        
        init?(_ objcEventProcessor: _ObjcOPTEventProcessor?) {
            guard let objcProcesser = objcEventProcessor else { return nil }
            
            self.objcEventProcessor = objcProcesser
        }
        
        func processEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
            var objcHandler: ((Data?, NSError?) -> Void)?
            
            if let completionHandler = completionHandler {
                objcHandler = { (data, error) in
                    var result: OptimizelyResult<Data>
                    
                    if let error = error {
                        result = .failure(.eventDispatchFailed(error.localizedDescription))
                    } else {
                        result = .success(data ?? Data())
                    }
                    
                    completionHandler(result)
                }
            }
            
            objcEventProcessor.processEvent(event: event, completionHandler: objcHandler)
        }
        
        func flushEvents() {
            objcEventProcessor.flushEvents()
        }
    }
    
    /// EventHandler implementation for Objective-C interface support
    class SwiftEventHandler: OPTEventHandler {
        let objcEventHandler: _ObjcOPTEventHandler
        
        init?(_ objcEventHandler: _ObjcOPTEventHandler?) {
            guard let objcProcesser = objcEventHandler else { return nil }
            
            self.objcEventHandler = objcProcesser
        }
        
        func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
            var objcHandler: ((Data?, NSError?) -> Void)?
            
            if let completionHandler = completionHandler {
                objcHandler = { (data, error) in
                    var result: OptimizelyResult<Data>
                    
                    if let error = error {
                        result = .failure(.eventDispatchFailed(error.localizedDescription))
                    } else {
                        result = .success(data ?? Data())
                    }
                    
                    completionHandler(result)
                }
            }
            
            objcEventHandler.dispatchEvent(event: event, completionHandler: objcHandler)
        }
    }

    // deprecated
    class SwiftEventDispatcher: OPTEventDispatcher {
        let objcEventDispatcher: _ObjcOPTEventDispatcher
        
        init?(_ objcEventDispatcher: _ObjcOPTEventDispatcher?) {
            guard let objcDispatcher = objcEventDispatcher else { return nil }
            
            self.objcEventDispatcher = objcDispatcher
        }
        
        func dispatchEvent(event: EventForDispatch, completionHandler: DispatchCompletionHandler?) {
            var objcHandler: ((Data?, NSError?) -> Void)?
            
            if let completionHandler = completionHandler {
                objcHandler = { (data, error) in
                    var result: OptimizelyResult<Data>
                    
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

    @available(swift, obsoleted: 1.0)
    @objc(notificationCenter)
    /// NotificationCenter for Objective-C interface support
    public var objcNotificationCenter: ObjcOPTNotificationCenter {
        
        class ObjcCenter: ObjcOPTNotificationCenter {
            var notifications: OPTNotificationCenter
            
            init(notificationCenter: OPTNotificationCenter) {
                notifications = notificationCenter
            }
            
            internal func convertAttribues(attributes: OptimizelyAttributes?) -> [String: Any]? {
                return attributes?.mapValues({ (val) -> Any in
                    if let val = val {
                        return val
                    } else {
                        return NSNull()
                    }
                })
            }
            
            internal func returnVal(num: Int?) -> NSNumber? {
                if let num = num {
                    return NSNumber(value: num)
                }
                
                return nil
            }
            
            func addActivateNotificationListener(activateListener: @escaping ([String: Any], String, [String: Any]?, [String: Any], [String: Any]) -> Void) -> NSNumber? {
                
                let num = notifications.addActivateNotificationListener { (experiment, userId, attributes, variation, event) in
                    
                    activateListener(experiment, userId, self.convertAttribues(attributes: attributes), variation, event)
                }
                
                return returnVal(num: num)
            }
            
            func addTrackNotificationListener(trackListener: @escaping (String, String, [String: Any]?, [String: Any]?, [String: Any]) -> Void) -> NSNumber? {
                let num = notifications.addTrackNotificationListener { (eventKey, userId, attributes, eventTags, event) in
                    
                    trackListener(eventKey, userId, self.convertAttribues(attributes: attributes), eventTags, event)
                }
                
                return returnVal(num: num)
            }
            
            func addDecisionNotificationListener(decisionListener: @escaping (String, String, [String: Any]?, [String: Any]) -> Void) -> NSNumber? {
                
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
            
            func addLogEventNotificationListener(logEventListener: @escaping (String, [String: Any]) -> Void) -> NSNumber? {
                let num = notifications.addLogEventNotificationListener { (url, event) in
                    logEventListener(url, event)
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
        
        return ObjcCenter(notificationCenter: self.notificationCenter!)
    }
}

// MARK: - ObjC protocols
@objc(OPTEventProcessor) public protocol _ObjcOPTEventProcessor {
    func processEvent(event: EventForDispatch, completionHandler: ((Data?, NSError?) -> Void)?)
    
    /// Attempts to flush the event queue if there are any events to process.
    func flushEvents()
}
@objc(OPTEventHandler) public protocol _ObjcOPTEventHandler {
    func dispatchEvent(event: EventForDispatch, completionHandler: ((Data?, NSError?) -> Void)?)
}
// deprecated
@objc(OPTEventDispatcher) public protocol _ObjcOPTEventDispatcher {
    func dispatchEvent(event: EventForDispatch, completionHandler: ((Data?, NSError?) -> Void)?)
    
    /// Attempts to flush the event queue if there are any events to process.
    func flushEvents()
}


@available(swift, obsoleted: 1.0)
@objc(DefaultEventProcessor) public class ObjEventProcessor: NSObject, _ObjcOPTEventProcessor {
    
    let innerEventProcessor: DefaultEventProcessor
    
    @objc public init(batchSize: Int = DefaultEventProcessor.DefaultValues.batchSize,
                      timerInterval: TimeInterval = DefaultEventProcessor.DefaultValues.timeInterval,
                      maxQueueSize: Int = DefaultEventProcessor.DefaultValues.maxQueueSize) {
        innerEventProcessor = DefaultEventProcessor(batchSize: batchSize, timerInterval: timerInterval, maxQueueSize: maxQueueSize)
    }
    
    public func processEvent(event: EventForDispatch, completionHandler: ((Data?, NSError?) -> Void)?) {
        innerEventProcessor.processEvent(event: event) { (result) -> Void in
            guard let completionHandler = completionHandler else { return }
            
            switch result {
            case .success(let value):
                completionHandler(value, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError)
            }
        }
    }
    
    public func flushEvents() {
        innerEventProcessor.flushEvents()
    }
    
}

@available(swift, obsoleted: 1.0)
@objc(DefaultEventHandler) public class ObjEventHandler: NSObject, _ObjcOPTEventHandler {
    
    let innerEventHandler: DefaultEventHandler
    
    @objc public override init() {
        innerEventHandler = DefaultEventHandler()
    }
    
    public func dispatchEvent(event: EventForDispatch, completionHandler: ((Data?, NSError?) -> Void)?) {
        innerEventHandler.dispatchEvent(event: event) { (result) -> Void in
            guard let completionHandler = completionHandler else { return }
            
            switch result {
            case .success(let value):
                completionHandler(value, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError)
            }
        }
    }
    
}

// deprecated
@available(swift, obsoleted: 1.0)
@objc(DefaultEventDispatcher) public class ObjEventDispatcher: NSObject, _ObjcOPTEventDispatcher {
    
    let innerEventDispatcher: DefaultEventDispatcher
    
    @objc public init(batchSize: Int = DefaultEventDispatcher.DefaultValues.batchSize,
                      timerInterval: TimeInterval = DefaultEventDispatcher.DefaultValues.timeInterval,
                      maxQueueSize: Int = DefaultEventDispatcher.DefaultValues.maxQueueSize) {
        innerEventDispatcher = DefaultEventDispatcher(batchSize: batchSize, timerInterval: timerInterval, maxQueueSize: maxQueueSize)
    }
    
    public func dispatchEvent(event: EventForDispatch, completionHandler: ((Data?, NSError?) -> Void)?) {
        innerEventDispatcher.dispatchEvent(event: event) { (result) -> Void in
            guard let completionHandler = completionHandler else { return }
            
            switch result {
            case .success(let value):
                completionHandler(value, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError)
            }
        }
    }
    
    public func flushEvents() {
        innerEventDispatcher.flushEvents()
    }
    
}
