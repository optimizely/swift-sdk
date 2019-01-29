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

public typealias OPTActivateCallback = (_ experimentKey: String, _ userId: String, _ attributes: Dictionary<String,Any>?, _ variation: String, _ event: Dictionary<String, Any>) -> Void

public typealias OPTTrackCallback = (_ eventKey: String, _ userId: String, _ attributes: Dictionary<String, Any>?, _ eventTags: Dictionary<String, Any>?, _ event: Dictionary<String, Any>) -> Void

public typealias OPTGenericCallback = (Any?...) -> Void


public class OPTNotificationCenter {

    var notificationId: Int = 1
    var notificationListeners = [Int: CoreNotificationListener]()
    
    public func addActivateNotificationListener(callback: @escaping OPTActivateCallback) -> Int {
        return addNotificationListener(CoreActivateListner(callback: callback))
    }
    
    public func addTrackNotificationListener(callback: @escaping OPTTrackCallback) -> Int {
        return addNotificationListener(CoreTrackListner(callback: callback))
    }
    
    public func addGenericNotificationListener(callback: @escaping OPTGenericCallback) -> Int {
        return addNotificationListener(CoreGenericListner(callback: callback))
    }
    
    func addNotificationListener(_ listener: CoreNotificationListener) -> Int {
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
    
    public func clearAllNotificationListeners() {
        notificationListeners.removeAll()
    }
    
    func sendNotifications(type: NotificationType, args: [Any]) {
        notificationListeners.values.forEach {
            try? $0.notifyTypeMatched(type: type, data: args)
        }
    }
    
    
}
