//
// Copyright 2019-2021, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

public class DefaultNotificationCenter: OPTNotificationCenter {
    public var notificationId: Int {
        get {
            var id = 0
            atomicListeners.performAtomic { listners in
                id = listners.notificationId
            }
            return id
        }
        set {
            _ = newValue // no setter (for suppressing SwiftLint warning)
        }
    }
    
    class Listeners {
        var notificationId: Int = 1
        var notificationListeners = [Int: (Int, GenericListener)]()
        
        func add(type: Int, listener: @escaping GenericListener) -> Int {
            notificationListeners[notificationId] = (type, listener)
            
            let returnValue = notificationId
            notificationId += 1
            return returnValue
        }
    }
    
    private var atomicListeners = AtomicProperty(property: Listeners())
    
    var observerLogEvent: NSObjectProtocol?

    required public init() {
        addInternalNotificationListners()
    }
    
    deinit {
        removeInternalNotificationListners()
    }
    
    public func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) -> Int? {
        var id = 0
        atomicListeners.performAtomic { listners in
            id = listners.add(type: notificationType, listener: listener)
        }
        return id
    }
    
    public func addActivateNotificationListener(activateListener: @escaping (OptimizelyExperimentData, String, OptimizelyAttributes?, OptimizelyVariationData, [String: Any]) -> Void) -> Int? {
        let listener = { (args: Any...) in
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
        
        return addGenericNotificationListener(notificationType: NotificationType.activate.rawValue, listener: listener)
    }
    
    public func addTrackNotificationListener(trackListener: @escaping (String, String, OptimizelyAttributes?, [String: Any]?, [String: Any]) -> Void) -> Int? {
        let listener = { (args: Any...) in
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
        
        return addGenericNotificationListener(notificationType: NotificationType.track.rawValue, listener: listener)
    }
    
    public func addDecisionNotificationListener(decisionListener: @escaping (String, String, OptimizelyAttributes?, [String: Any]) -> Void) -> Int? {
        let listener = { (args: Any...) in
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
        
        return addGenericNotificationListener(notificationType: NotificationType.decision.rawValue, listener: listener)
    }

    public func addDatafileChangeNotificationListener(datafileListener: @escaping DatafileChangeListener) -> Int? {
        let listener = { (args: Any...) in
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
        
        return addGenericNotificationListener(notificationType: NotificationType.datafileChange.rawValue, listener: listener)
    }
    
    public func addLogEventNotificationListener(logEventListener: @escaping LogEventListener) -> Int? {
        let listener = { (args: Any...) in
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
        
        return addGenericNotificationListener(notificationType: NotificationType.logEvent.rawValue, listener: listener)
    }
    
    public func removeNotificationListener(notificationId: Int) {
        atomicListeners.performAtomic { listeners in
            listeners.notificationListeners.removeValue(forKey: notificationId)
        }
    }
    
    public func clearNotificationListeners(type: NotificationType) {
        atomicListeners.performAtomic { listeners in
            listeners.notificationListeners = listeners.notificationListeners.filter({$1.0 != type.rawValue})
        }
    }
    
    public func clearAllNotificationListeners() {
        atomicListeners.performAtomic { listeners in
            listeners.notificationListeners.removeAll()
        }
    }
    
    public func sendNotifications(type: Int, args: [Any?]) {
        var selected = [GenericListener]()
        atomicListeners.performAtomic { listeners in
            selected = listeners.notificationListeners.values.filter { $0.0 == type }.map { $0.1 }
        }

        for listener in selected {
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
            }
        }
    }
    
    func removeInternalNotificationListners() {
        if let observer = observerLogEvent {
            NotificationCenter.default.removeObserver(observer, name: .willSendOptimizelyEvents, object: nil)
        }
    }
    
}
