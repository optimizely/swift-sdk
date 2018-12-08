//
//  OptimizelyManager.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/7/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class OptimizelyManager : Optimizely {
    internal var isValid = false
    
    internal var bucketer: Bucketer?
    
    internal var decisionService: DecisionService?
    
    internal var config: ProjectConfig?
    
    internal var errorHandler: ErrorHandler?
    
    internal var eventDispatcher: EventDispatcher?
    
    internal var datafileHandler: DatafileHandler?
    
    internal var logger: Logger?
    
    internal var userProfileService: UserProfileService?
    
    internal var notificationCenter: NotificationCenter?
    
    internal init(bucketer:Bucketer?, decisionService:DecisionService?, errorHandler:ErrorHandler?, eventDispatcher:EventDispatcher?, datafileHandler:DatafileHandler?, logger:Logger?, userProfileService:UserProfileService?, notificationCenter:NotificationCenter?) {
        var b = bucketer
        var ds = decisionService
        var eh = errorHandler
        var ed = eventDispatcher
        var dh = datafileHandler
        var l = logger
        var ups = userProfileService
        var n = notificationCenter
        
        self.bucketer = b
        self.decisionService = ds
        self.errorHandler = eh
        self.eventDispatcher = ed
        self.datafileHandler = dh
        self.logger = l
        self.userProfileService = ups
        self.notificationCenter = n
    }

    func initialize(data:Data) -> Optimizely? {
        config = try! JSONDecoder().decode(ProjectConfig.self, from: data)
        if let config = config, let bucketer = DefaultBucketer.createInstance(config: config) {
            decisionService = DefaultDecisionService.createInstance(config: config, bucketer: bucketer, userProfileService: userProfileService ?? DefaultUserProfileService.createInstance())
            isValid = true
            return self
        }
        
        return nil
    }

    func initialize(datafile:String) -> Optimizely? {
        if let data = datafile.data(using: .utf8) {
            return initialize(data: data)
        }
        
        return nil
    }
    
    func initialize(sdkKey:String, completetionHandler:OptimizelyInitCompletionHandler) {
        
    }
    

    
    func activate(experimentKey: String, userId: String) -> Variation? {
        if isValid {
            return activate(experimentKey: experimentKey, userId: userId, attributes: nil)
        }
        
        return nil
    }
    
    func activate(experimentKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Variation? {
        if isValid {
            return variation(experimentKey: experimentKey, userId: userId, attributes: attributes)
        }
        
        return nil
    }
    
    func variation(experimentKey: String, userId: String) -> Variation? {
        return variation(experimentKey: experimentKey, userId: userId, attributes: nil)
    }
    
    func variation(experimentKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Variation? {
        if isValid {
            if let experiment = config?.experiments.filter({$0.key == experimentKey}).first {
                return decisionService?.getVariation(userId: userId, experiment: experiment, attributes: attributes ?? [:])
            }
        }
        return nil
    }
    
    func getForcedVariation(experimentKey: String, userId: String) -> Variation? {
        if let dict = config?.whitelistUsers[userId], let variationKey = dict[experimentKey] {
            return  config?.experiments.filter({$0.key == experimentKey}).first?.variations.filter({$0.key == variationKey}).first
        }
        
        return nil
    }
    
    func setForcedVariation(experimentKey: String, userId: String, variationKey: String) -> Bool {
        if var dict = config?.whitelistUsers[userId] {
            dict[experimentKey] = variationKey
        }
        else {
            config?.whitelistUsers[userId] = [experimentKey:variationKey]
        }
        return true
    }
    
    func isFeatureEnabled(featureKeyy: String, userId: String, attributes: Dictionary<String, Any>?) -> Bool {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKeyy}).first ,let variation = decisionService?.getVariationForFeature(featureFlag: featureFlag, userId: userId, attributes: attributes ?? [:]), variation.featureEnabled == true {
            return true
        }
        
        return false
    }
    
    func getFeatureVariableBoolean(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Bool? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "boolean" {
                if let value = variable.defaultValue {
                    return Bool(value)
                }
            }
        }
        return nil
    }
    
    func getFeatureVariableDouble(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Double? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "double" {
                if let value = variable.defaultValue  {
                    return Double(value)
                }
            }
        }
        return nil
    }
    
    func getFeatureVariableInteger(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Int? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "integer" {
                if let value = variable.defaultValue  {
                    return Int(value)
                }
            }
        }
        return nil

    }
    
    func getFeatureVariableString(featureKey: String, variableKey: String, userId: String, attributes: Dictionary<String, Any>?) -> String? {
        if let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first ,let variable = featureFlag.variables?.filter({$0.key == variableKey}).first {
            if variable.type == "string" {
                if let value = variable.defaultValue  {
                    return value
                }
            }
        }
        return nil

    }
    
    func getEnabledFeatures(userId: String, attributes: Dictionary<String, Any>?) -> Array<String> {
        return config?.featureFlags?.filter({ isFeatureEnabled(featureKeyy: $0.key, userId: userId, attributes: attributes)}).map({$0.key}) ?? []
    }

    func track(eventKey: String, userId: String) {
        track(eventKey: eventKey, userId: userId, eventTags: nil)
    }
    
    func track(eventKey: String, userId: String, attributes: Dictionary<String, Any>?) {
        return track(eventKey: eventKey, userId: userId, attributes: attributes, eventTags: nil)
    }
    
    func track(eventKey: String, userId: String, eventTags: Dictionary<String, Any>?) {
        return track(eventKey: eventKey, userId: userId, attributes: nil, eventTags: eventTags)
    }
    
    func track(eventKey: String, userId: String, attributes: Dictionary<String, Any>?, eventTags: Dictionary<String, Any>?) {
        if let experimentIds = config?.events?.filter({$0.key == eventKey}).first?.experimentIds {
            let experiments = experimentIds.map { (id) -> Experiment? in
                config?.experiments.filter({$0.id == id}).first
            }
            var trackExperiments = [String:String]()
            for experiment in experiments where experiment != nil && experiment?.status == Experiment.Status.Running {
                if let variation = decisionService?.getVariation(userId: userId, experiment: experiment!, attributes: attributes ?? [String:Any]()) {
                    trackExperiments[experiment!.id] = variation.id
                }
            }
            
            // create batch event.
        }
    }
    
    class Builder {
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

        func withDecisionService(decisionService:DecisionService) {
            self.decisionService = decisionService
        }
        
        func withConfig(projectConfig:ProjectConfig) {
            self.config = projectConfig
        }
        
        func withErrorHandler(errorHandler:ErrorHandler) {
            self.errorHandler = errorHandler
        }
        
        func withEventDispatcher(eventDispatcher:EventDispatcher) {
            self.eventDispatcher = eventDispatcher
        }
        
        func withDatafileHandler(datafileHandler:DatafileHandler) {
            self.datafileHandler = datafileHandler
        }
        
        func withLogger(logger:Logger) {
            self.logger = logger
        }
        
        func withUserProfileService(userProfileService:UserProfileService) {
            self.userProfileService = userProfileService
        }
        
        func withNotificationCenter(notificationCenter:NotificationCenter) {
            self.notificationCenter = notificationCenter
        }
        
        func build() -> OptimizelyManager? {
            return OptimizelyManager(bucketer:bucketer, decisionService:decisionService, errorHandler: errorHandler, eventDispatcher: eventDispatcher, datafileHandler: datafileHandler, logger: logger, userProfileService: userProfileService, notificationCenter: notificationCenter)
        }

    }
}
