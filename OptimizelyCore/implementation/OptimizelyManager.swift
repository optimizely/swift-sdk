//
//  OptimizelyManager.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/7/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public class OptimizelyManager : Optimizely {
    internal var isValid = false
    
    public var bucketer: Bucketer?
    
    public var decisionService: DecisionService?
    
    public var config: ProjectConfig?
    
    public var errorHandler: ErrorHandler?
    
    public var eventDispatcher: EventDispatcher?
    
    public var datafileHandler: DatafileHandler?
    
    public var logger: Logger?
    
    public var userProfileService: UserProfileService?
    
    public var notificationCenter: NotificationCenter?
    
    internal init(bucketer:Bucketer?, decisionService:DecisionService?, errorHandler:ErrorHandler?, eventDispatcher:EventDispatcher?, datafileHandler:DatafileHandler?, logger:Logger?, userProfileService:UserProfileService?, notificationCenter:NotificationCenter?) {
        self.bucketer = bucketer
        self.decisionService = decisionService
        self.errorHandler = errorHandler
        self.eventDispatcher = eventDispatcher  ?? DefaultEventDispatcher.createInstance()
        self.datafileHandler = datafileHandler
        self.logger = logger
        self.userProfileService = userProfileService
        self.notificationCenter = notificationCenter
        
    }

    public func initialize(data:Data) -> Optimizely? {
        config = try! JSONDecoder().decode(ProjectConfig.self, from: data)
        if let config = config, let bucketer = DefaultBucketer.createInstance(config: config) {
            decisionService = DefaultDecisionService.createInstance(config: config, bucketer: bucketer, userProfileService: userProfileService ?? DefaultUserProfileService.createInstance())
            isValid = true
            return self
        }
        
        return nil
    }

    public func initialize(datafile:String) -> Optimizely? {
        if let data = datafile.data(using: .utf8) {
            return initialize(data: data)
        }
        
        return nil
    }
    
    public func initialize(sdkKey:String, completetionHandler:@escaping OptimizelyInitCompletionHandler) {
        if let _ = datafileHandler {
            
        }
        else {
            datafileHandler = DefaultDatafileHandler.createInstance()
        }
        
        datafileHandler?.downloadDatafile(sdkKey: sdkKey, completionHandler: { (result) in
            switch result {
            case .failure(let err):
                self.logger?.log(level: OptimizelyLogLevel.OptimizelyLogLevelError, message: err.description)
                completetionHandler(Result.failure(IntializeError(description: err.description)))
            case .success(let datafile):
                let optimizely = self.initialize(datafile: datafile)
                if let optimizely = optimizely {
                    completetionHandler(Result.success(optimizely))
                }
                else {
                    completetionHandler(Result.failure(IntializeError(description: "Problem initializing")))
                }
                
            }
        })
    }
    

    
    public func activate(experimentKey: String, userId: String) -> Variation? {
        if isValid {
            return activate(experimentKey: experimentKey, userId: userId, attributes: nil)
        }
        
        return nil
    }
    
    public func activate(experimentKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Variation? {
        if isValid {
            if let experiment = config?.experiments.filter({$0.key == experimentKey}).first,
                let variation = variation(experimentKey: experimentKey, userId: userId, attributes: attributes) {
                
                if let body = BatchEventBuilder.createImpressionEvent(config: config!, decisionService: decisionService!, experiment: experiment, varionation: variation, userId: userId, attributes: attributes) {
                    eventDispatcher?.dispatchEvent(event: EventForDispatch(body: body), completionHandler: { (result) -> (Void) in
                        
                    })
                }
                
                return variation
            }
        }
        
        return nil
    }
    
    public func variation(experimentKey: String, userId: String) -> Variation? {
        return variation(experimentKey: experimentKey, userId: userId, attributes: nil)
    }
    
    public func variation(experimentKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Variation? {
        if isValid {
            if let experiment = config?.experiments.filter({$0.key == experimentKey}).first {
                return decisionService?.getVariation(userId: userId, experiment: experiment, attributes: attributes ?? [:])
            }
        }
        return nil
    }
    
    public func getForcedVariation(experimentKey: String, userId: String) -> Variation? {
        if let dict = config?.whitelistUsers[userId], let variationKey = dict[experimentKey] {
            return  config?.experiments.filter({$0.key == experimentKey}).first?.variations.filter({$0.key == variationKey}).first
        }
        
        return nil
    }
    
    public func setForcedVariation(experimentKey: String, userId: String, variationKey: String) -> Bool {
        if var dict = config?.whitelistUsers[userId] {
            dict[experimentKey] = variationKey
        }
        else {
            config?.whitelistUsers[userId] = [experimentKey:variationKey]
        }
        return true
    }
    
    public func isFeatureEnabled(featureKeyy: String, userId: String, attributes: Dictionary<String, Any>?) -> Bool {
        guard let featureFlag = config?.featureFlags?.filter({$0.key == featureKeyy}).first  else {
            return false
        }
        
        if let pair = decisionService?.getVariationForFeature(featureFlag: featureFlag, userId: userId, attributes: attributes ?? [:]), let experiment = pair.experiment, let variation = pair.variation {
            if let body = BatchEventBuilder.createImpressionEvent(config: config!, decisionService: decisionService!, experiment: experiment, varionation: variation, userId: userId, attributes: attributes) {
                eventDispatcher?.dispatchEvent(event: EventForDispatch(body: body), completionHandler: { (result) -> (Void) in
                    
                })
            }
            
            return pair.variation?.featureEnabled ?? false
        }
        return false
    }
    
    public func getFeatureVariableBoolean(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Bool? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "boolean" {
                if let value = variable.defaultValue {
                    return Bool(value)
                }
            }
        }
        return nil
    }
    
    public func getFeatureVariableDouble(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Double? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "double" {
                if let value = variable.defaultValue  {
                    return Double(value)
                }
            }
        }
        return nil
    }
    
    public func getFeatureVariableInteger(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Int? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "integer" {
                if let value = variable.defaultValue  {
                    return Int(value)
                }
            }
        }
        return nil

    }
    
    public func getFeatureVariableString(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> String? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "string" {
                if let value = variable.defaultValue  {
                    return value
                }
            }
        }
        return nil

    }
    
    public func getEnabledFeatures(userId: String, attributes: Dictionary<String, Any>?) -> Array<String> {
        return config?.featureFlags?.filter({ isFeatureEnabled(featureKeyy: $0.key, userId: userId, attributes: attributes)}).map({$0.key}) ?? []
    }

    public func track(eventKey: String, userId: String) {
        track(eventKey: eventKey, userId: userId, eventTags: nil)
    }
    
    public func track(eventKey: String, userId: String, attributes: Dictionary<String, Any>?) {
        return track(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: nil)
    }
    
    public func track(eventKey: String, userId: String, eventTags: Dictionary<String, Any>?) {
        return track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
    }
    
    public func track(eventKey: String, userId: String, attributes: Dictionary<String, Any>?, eventTags: Dictionary<String, Any>?) {
        if let event = BatchEventBuilder.createConversionEvent(config:config!, decisionService:decisionService!, eventKey:eventKey, userId:userId, attributes:attributes, eventTags:eventTags) {
            let eventForDispatch = EventForDispatch(body:event)
            eventDispatcher?.dispatchEvent(event: eventForDispatch, completionHandler: { (result) -> (Void) in
                
            })
        }
        
    }
    
    public class Builder {
        var bucketer: Bucketer?
        
        var decisionService: DecisionService?
        
        var config: ProjectConfig?
        
        var errorHandler: ErrorHandler?
        
        var eventDispatcher: EventDispatcher?
        
        var datafileHandler: DatafileHandler?
        
        var logger: Logger?
        
        var userProfileService: UserProfileService?
        
        var notificationCenter: NotificationCenter?
        
        func withBucketer(bucketer:Bucketer) {
            self.bucketer = bucketer
        }
        
        public init() {
            
        }

        public func withDecisionService(decisionService:DecisionService) {
            self.decisionService = decisionService
        }
        
        public func withConfig(projectConfig:ProjectConfig) {
            self.config = projectConfig
        }
        
        public func withErrorHandler(errorHandler:ErrorHandler) {
            self.errorHandler = errorHandler
        }
        
        public func withEventDispatcher(eventDispatcher:EventDispatcher) {
            self.eventDispatcher = eventDispatcher
        }
        
        public func withDatafileHandler(datafileHandler:DatafileHandler) {
            self.datafileHandler = datafileHandler
        }
        
        public func withLogger(logger:Logger) {
            self.logger = logger
        }
        
        public func withUserProfileService(userProfileService:UserProfileService) {
            self.userProfileService = userProfileService
        }
        
        public func withNotificationCenter(notificationCenter:NotificationCenter) {
            self.notificationCenter = notificationCenter
        }
        
        public func build() -> OptimizelyManager? {
            return OptimizelyManager(bucketer:bucketer, decisionService:decisionService, errorHandler: errorHandler, eventDispatcher: eventDispatcher, datafileHandler: datafileHandler, logger: logger, userProfileService: userProfileService, notificationCenter: notificationCenter)
        }

    }
}
