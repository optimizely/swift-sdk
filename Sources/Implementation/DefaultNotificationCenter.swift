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

public class DefaultNotificationCenter: OPTNotificationCenter {
    let notificationListeners = NotificationListeners()
    
    public var notificationId: Int {
        get {
            return notificationListeners.notificationId
        }
        set {
            notificationListeners.notificationId = newValue
        }
    }
        
    var observerLogEvent: NSObjectProtocol?

    required public init() {
        addInternalNotificationListners()
    }
    
    deinit {
        removeInternalNotificationListners()
    }
    

    public func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) -> Int? {
        return notificationListeners.add(type: .generic, listener: listener)
    }
    
    public func addActivateNotificationListener(activateListener: @escaping (OptimizelyExperimentData, String, OptimizelyAttributes?, OptimizelyVariationData, [String: Any]) -> Void) -> Int? {
        return notificationListeners.add(type: .activate) { (args: Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 5 {
                return
            }
            if let experiement = myArgs[0] as? Experiment,
                let userId = myArgs[1] as? String,
                let variation = myArgs[3] as? Variation {
                let attributes = myArgs[2] as? OptimizelyAttributes
                let event = myArgs[4] as! [String: Any]
                
                let experimentData = ["key": experiement.key, "id": experiement.id]
                
                let variationData = ["key": variation.key, "id": variation.id]
                
                activateListener(experimentData, userId, attributes, variationData, event)
            }
        }
    }
    
    public func addTrackNotificationListener(trackListener: @escaping (String, String, OptimizelyAttributes?, [String: Any]?, [String: Any]) -> Void) -> Int? {
        return notificationListeners.add(type: .track) { (args: Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 5 {
                return
            }
            if let eventKey = myArgs[0] as? String,
                let userId = myArgs[1] as? String,
                let attributes = myArgs[2] as? OptimizelyAttributes?,
                let eventTags = myArgs[3] as? [String: Any]?,
                let event = myArgs[4] as? [String: Any] {
                trackListener(eventKey, userId, attributes, eventTags, event)
            }
        }
    }
    
    public func addDecisionNotificationListener(decisionListener: @escaping (String, String, OptimizelyAttributes?, [String: Any]) -> Void) -> Int? {
        return notificationListeners.add(type: .decision) { (args: Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 4 {
                return
            }
            if let type = myArgs[0] as? String,
                let userId = myArgs[1] as? String,
                let attributes = myArgs[2] as? OptimizelyAttributes?,
                let decisionInfo = myArgs[3] as? [String: Any] {
                decisionListener(type, userId, attributes, decisionInfo)
            }
        }
    }

    public func addDatafileChangeNotificationListener(datafileListener: @escaping DatafileChangeListener) -> Int? {
        return notificationListeners.add(type: .datafileChange) { (args: Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 1 {
                return
            }
            if let data = myArgs[0] as? Data {
                datafileListener(data)
            }
        }
    }
    
    public func addLogEventNotificationListener(logEventListener: @escaping LogEventListener) -> Int? {
        return notificationListeners.add(type: .logEvent) { (args: Any...) in
            guard let myArgs = args[0] as? [Any?] else {
                return
            }
            if myArgs.count < 2 {
                return
            }
            if let url = myArgs[0] as? String,
                let event = myArgs[1] as? [String: Any] {
                logEventListener(url, event)
            }
        }
    }
    
    public func removeNotificationListener(notificationId: Int) {
        notificationListeners.remove(notificationId: notificationId)
    }
    
    public func clearNotificationListeners(type: NotificationType) {
        notificationListeners.clear(type: type)
    }
    
    public func clearAllNotificationListeners() {
        notificationListeners.clearAll()
    }
    
    public func sendNotifications(type: Int, args: [Any?]) {
        for listener in notificationListeners.getAll(type: type) {
            listener(args)
        }
    }
    
}

// MARK: Notification Translation

extension DefaultNotificationCenter {
    
    func addInternalNotificationListners() {
        observerLogEvent = NotificationCenter.default.addObserver(forName: .willSendOptimizelyEvents, object: nil, queue: nil) { (notif) in
            guard let eventForDispatch = notif.object as? EventForDispatch else { return }
            
            let url = eventForDispatch.url.absoluteString
            let eventData = eventForDispatch.body
            
            if let event = try? JSONSerialization.jsonObject(with: eventData, options: []) as? [String: Any] {
                let args: [Any] = [url, event]
                self.sendNotifications(type: NotificationType.logEvent.rawValue, args: args)
            } else {
                print("LogEvent notification discarded due to invalid event")
            }
        }
    }
    
    func removeInternalNotificationListners() {
        if let observer = observerLogEvent {
            NotificationCenter.default.removeObserver(observer, name: .willSendOptimizelyEvents, object: nil)
        }
    }
    
}

// MARK: - NotificationListeners

class NotificationListeners {
    var listeners = [Int: (Int, GenericListener)]()
    let lock = DispatchQueue(label: "notification")
    
    
   // private var id = AtomicProperty(property: 1)
//    var notificationId: Int {
//        get {
//            return id.property!
//        }
//        set {
//            id.property = newValue
//        }
//    }
    var notificationId = 1
    
    
    
    func add(type: NotificationType, listener: @escaping GenericListener) -> Int? {
        var returnId = 0
        lock.sync {
            listeners[notificationId] = (type.rawValue, listener)
            returnId = notificationId
            notificationId = returnId + 1
        }
        return returnId
    }
    
    func remove(notificationId: Int) {
        lock.async {
            _ = self.listeners.removeValue(forKey: notificationId)
        }
    }
    
    func clear(type: NotificationType) {
        lock.async {
            self.listeners = self.listeners.filter({$1.0 != type.rawValue})
        }
    }
    
    func clearAll() {
        lock.async {
            self.listeners.removeAll()
        }
    }
    
    func getAll(type: Int) -> [GenericListener] {
        var result = [GenericListener]()
        lock.sync {
            result = listeners.values.filter{ $0.0 == type }.map{ $0.1 }
        }
        return result
    }
}
