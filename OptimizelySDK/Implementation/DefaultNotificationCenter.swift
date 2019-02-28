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
    
    public func addActivateNotificationListener(activateListener: @escaping (OptimizelyExperimentData, String, Dictionary<String, Any>?, OptimizelyVariationData, Dictionary<String, Any>) -> Void) -> Int? {
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
                
                // TODO: fix this temp data type for internal data model issueus
                let experimentData = [String: Any]()
                let variationData = [String: Any]()
                activateListener(experimentData, userId, attributes, variationData, event)
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
            if let eventKey = myArgs[0] as? String, let userId = myArgs[1] as? String,
                let attributes = myArgs[2] as? Dictionary<String, Any>,
                let eventTags = myArgs[3] as? Dictionary<String,Any>,
                let event = myArgs[4] as? Dictionary<String,Any>
                {
                trackListener(eventKey, userId, attributes, eventTags, event)
            }
        })
        
        return incrementNotificationId()
    }
    
    public func addDatafileChangeNotificationListener(datafileListener: @escaping DatafileChangeListener) -> Int? {
        notificationListeners[notificationId] = (NotificationType.DatafileChange.rawValue,  { (args:Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 1 {
                return
            }
            if let data = myArgs[0] as? Data {
                datafileListener(data)
            }
        })
        
        return incrementNotificationId()
    }
    
    public func addFeatureFlagRolloutChangeListener(featureListener: @escaping FeatureFlagRolloutChangeListener) -> Int? {
        notificationListeners[notificationId] = (NotificationType.FeatureFlagRolloutToggle.rawValue,  { (args:Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 2 {
                return
            }
            if let featureKey = myArgs[0] as? String, let toogle = myArgs[1] as? FeatureFlagToggle {
                featureListener(featureKey, toogle)
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
