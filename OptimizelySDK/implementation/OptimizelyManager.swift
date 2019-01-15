//
//  OptimizelyManager.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/7/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public class OptimizelyManager : Optimizely {
    
    public var bucketer: OPTBucketer?
    public var decisionService: OPTDecisionService?
    public var config: ProjectConfig?
    public var errorHandler: OPTErrorHandler?
    public var eventDispatcher: OPTEventDispatcher?
    public var datafileHandler: DatafileHandler?
    public var logger: Logger?
    public var userProfileService: UserProfileService?
    public var notificationCenter: NotificationCenter?
    private var periodicDownloadInterval:Int?
    
    public init(bucketer:OPTBucketer? = nil, decisionService:OPTDecisionService? = nil, errorHandler:OPTErrorHandler? = nil, eventDispatcher:OPTEventDispatcher? = nil, datafileHandler:DatafileHandler? = nil, logger:Logger? = nil, userProfileService:UserProfileService? = nil, notificationCenter:NotificationCenter? = nil, periodicDownloadInterval:Int? = nil) {
        self.bucketer = bucketer
        self.periodicDownloadInterval = periodicDownloadInterval
        self.decisionService = decisionService
        self.errorHandler = errorHandler
        self.eventDispatcher = eventDispatcher  ?? DefaultEventDispatcher.createInstance()
        self.datafileHandler = datafileHandler
        self.logger = logger
        self.userProfileService = userProfileService
        self.notificationCenter = notificationCenter ?? DefaultNotificationCenter.createInstance()
        
    }

    public func initialize(data:Data) -> Optimizely? {
        config = try! JSONDecoder().decode(ProjectConfig.self, from: data)
        if let config = config, let bucketer = DefaultBucketer.createInstance(config: config) {
            decisionService = DefaultDecisionService.createInstance(config: config, bucketer: bucketer, userProfileService: userProfileService ?? DefaultUserProfileService.createInstance())
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
        
        if let periodicDownloadInterval = periodicDownloadInterval, periodicDownloadInterval > 0 {
            datafileHandler?.startPeriodicUpdates(sdkKey: sdkKey, updateInterval: periodicDownloadInterval)
        }
        
        datafileHandler?.downloadDatafile(sdkKey: sdkKey, completionHandler: { (result) in
            switch result {
            case .failure(let err):
                self.logger?.log(level: .error, message: err.description)
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
        return activate(experimentKey: experimentKey, userId: userId, attributes: nil)
    }
    
    public func activate(experimentKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Variation? {
          if let experiment = config?.experiments.filter({$0.key == experimentKey}).first,
              let variation = variation(experimentKey: experimentKey, userId: userId, attributes: attributes) {

              if let body = BatchEventBuilder.createImpressionEvent(config: config!, decisionService: decisionService!, experiment: experiment, varionation: variation, userId: userId, attributes: attributes) {
                  let event = EventForDispatch(body: body)
                  eventDispatcher?.dispatchEvent(event: event, completionHandler: { (result) -> (Void) in
                      switch result {
                      case .failure(let error):
                          self.logger?.log(level: .error, message: "Failed to dispatch event " + error.localizedDescription)
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
    
    public func variation(experimentKey: String, userId: String) -> Variation? {
        return variation(experimentKey: experimentKey, userId: userId, attributes: nil)
    }
    
    public func variation(experimentKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Variation? {

        if let experiment = config?.experiments.filter({$0.key == experimentKey}).first {
            return decisionService?.getVariation(userId: userId, experiment: experiment, attributes: attributes ?? [:])
        }

        return nil
    }
    
    public func getForcedVariation(experimentKey: String, userId: String) -> Variation? {
        if let dict = config?.whitelistUsers[userId], let variationKey = dict[experimentKey] {
            return  config?.experiments.filter({$0.key == experimentKey}).first?.variations.filter({$0.key == variationKey}).first
        }
        
        return nil
    }
    
    public func setForcedVariation(experimentKey: String, userId: String, variationKey: String?) -> Bool {
        if config?.experiments.filter({$0.key == experimentKey}).first == nil {
            return false
        }
        if let _variationKey = variationKey {
            if _variationKey.trimmingCharacters(in: NSCharacterSet.whitespaces) == "" {
                return false
            }
            
            if var dict = config?.whitelistUsers[userId] {
                dict[experimentKey] = variationKey
            }
            else {
                config?.whitelistUsers[userId] = [experimentKey:_variationKey]
            }
        }
        else {
            config?.whitelistUsers[userId]?.removeValue(forKey: experimentKey)
        }
        return true
    }
    
    public func isFeatureEnabled(featureKey: String, userId: String, attributes: Dictionary<String, Any>?) -> Bool {
        guard let featureFlag = config?.featureFlags?.filter({$0.key == featureKey}).first  else {
            return false
        }
        
        if let pair = decisionService?.getVariationForFeature(featureFlag: featureFlag, userId: userId, attributes: attributes ?? [:]), let experiment = pair.experiment, let variation = pair.variation {
            if let body = BatchEventBuilder.createImpressionEvent(config: config!, decisionService: decisionService!, experiment: experiment, varionation: variation, userId: userId, attributes: attributes) {
                let event = EventForDispatch(body: body)
                eventDispatcher?.dispatchEvent(event: event, completionHandler:{ (result) -> (Void) in
                    switch result {
                    case .failure(let error):
                        self.logger?.log(level: .error, message: "Failed to dispatch event " + error.localizedDescription)
                    case .success( _):
                        self.notificationCenter?.sendNotifications(type: NotificationType.Activate.rawValue, args: [experiment, userId, attributes, variation, ["url":event.url as Any,"body":event.body as Any]])
                    }

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
        return config?.featureFlags?.filter({ isFeatureEnabled(featureKey: $0.key, userId: userId, attributes: attributes)}).map({$0.key}) ?? []
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
                switch result {
                case .failure(let error):
                    self.logger?.log(level: .error, message: "Failed to dispatch event " + error.localizedDescription)
                case .success( _):
                    self.notificationCenter?.sendNotifications(type: NotificationType.Track.rawValue, args: [eventKey, userId, attributes, eventTags, ["url":eventForDispatch.url as Any, "body":eventForDispatch.body as Any]])
                }

            })
        }
        
    }
}
