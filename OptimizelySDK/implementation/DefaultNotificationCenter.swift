//
//  DefaultNotificationListener.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/18/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

public class DefaultNotificationCenter : OPTNotificationCenter {
    
    public var notificationId: Int = 1
    var notificationListeners = [Int:(Int,GenericListener)]()
    
    public static func createInstance() -> OPTNotificationCenter? {
            return DefaultNotificationCenter()
    }
    
    internal init() {
        
    }
    
    internal func incrementNotificationId() -> Int {
        let returnValue = notificationId
        notificationId += 1
        return returnValue
    }

    public func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) -> Int? {
        notificationListeners[notificationId] = (notificationType, listener)
        
        return incrementNotificationId()
    }
    
    public func addActivateNotificationListener(activateListener: @escaping (Experiment, String, Dictionary<String, Any>?, Variation, Dictionary<String, Any>) -> Void) -> Int? {
        notificationListeners[notificationId] = (NotificationType.Activate.rawValue,  { (args:Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 5 {
                return
            }
            if let experiment = myArgs[0] as? Experiment, let userId = myArgs[1] as? String,
                let variation = myArgs[3] as? Variation {
                let attributes = myArgs[2] as? Dictionary<String, Any>
                let event = myArgs[4] as! Dictionary<String,Any>
                activateListener(experiment, userId, attributes, variation, event)
            }
        })
        
        return incrementNotificationId()
    }
    
    public func addTrackNotificationListener(trackListener: @escaping (String, String, Dictionary<String, Any>?, Dictionary<String, Any>?, Dictionary<String, Any>) -> Void) -> Int? {
        notificationListeners[notificationId] = (NotificationType.Track.rawValue,  { (args:Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 5 {
                return
            }
            if let eventKey = myArgs[0] as? String, let userId = myArgs[1] as? String {
                let attributes = myArgs[2] as? Dictionary<String, Any>
                let eventTags = myArgs[3] as? Dictionary<String,Any>
                let event = myArgs[4] as! Dictionary<String,Any>
                trackListener(eventKey, userId, attributes, eventTags, event)
            }
        })
        
        return incrementNotificationId()
    }
    
    public func removeNotificationListener(notificationId: Int) {
        self.notificationListeners.removeValue(forKey: notificationId)
    }
    
    public func clearNotificationListeners(type: NotificationType) {
        self.notificationListeners = self.notificationListeners.filter({$1.0 != type.rawValue})
    }
    
    public func clearAllNotificationListeners() {
        self.notificationListeners.removeAll()
    }
    
    public func sendNotifications(type: Int, args: Array<Any?>) {
        for values in notificationListeners.values {
            if values.0 == type {
                values.1(args)
            }
        }
    }
    
    
}
