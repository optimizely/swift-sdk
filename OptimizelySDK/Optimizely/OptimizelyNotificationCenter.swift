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

// MARK: Notification Types

public enum OptimizelyNotificationType: Int {
    case generic = 0
    case activate
    case track
}

// MARK: Callbacks

public typealias OptimizelyActivateCallback = (_ experimentKey: String, _ userId: String, _ attributes: Dictionary<String,Any>?, _ variation: String, _ event: Dictionary<String, Any>) -> Void

public typealias OptimizelyTrackCallback = (_ eventKey: String, _ userId: String, _ attributes: Dictionary<String, Any>?, _ eventTags: Dictionary<String, Any>?, _ event: Dictionary<String, Any>) -> Void

public typealias OptimizelyGenericCallback = (Any?...) -> Void

// MARK: NotficationCenter

public class OptimizelyNotificationCenter {

    var notificationId: Int = 1
    var notificationListeners = [Int: CoreEventListener]()
    
    public func addActivateNotificationListener(callback: @escaping OptimizelyActivateCallback) -> Int {
        return addNotificationListener(ActivateEventListener(callback: callback))
    }
    
    public func addTrackNotificationListener(callback: @escaping OptimizelyTrackCallback) -> Int {
        return addNotificationListener(TrackEventListener(callback: callback))
    }
    
    public func addGenericNotificationListener(callback: @escaping OptimizelyGenericCallback) -> Int {
        return addNotificationListener(GenericEventListener(callback: callback))
    }
    
    func addNotificationListener(_ listener: CoreEventListener) -> Int {
        notificationListeners[notificationId] = listener
        return incrementNotificationId()
    }
    
    func incrementNotificationId() -> Int {
        let returnValue = notificationId
        notificationId += 1
        return returnValue
    }

    public func clearNotificationListener(notificationId: Int) {
        notificationListeners.removeValue(forKey: notificationId)
    }
    
    public func clearNotificationListeners(type: OptimizelyNotificationType) {
        notificationListeners = notificationListeners.filter{ !$0.value.isType(of: type) }
    }
    
    public func clearAllNotificationListeners() {
        notificationListeners.removeAll()
    }
    
    func sendNotifications(type: OptimizelyNotificationType, args: [Any]) {
        notificationListeners.values.filter{ $0.isType(of: type) }.forEach {
            do {
                try $0.notify(data: args)
            } catch {
                print("ERROR: notification callback error: \(error)")
            }
        }
    }
    
}
