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

/// Enum representing notification types.
@objc public enum NotificationType: Int {
    case activate = 1
    case track
    case datafileChange
    case decision
}

// TODO: fix this
// - temporary public data types to avoid {OPTExperiment, OPTVariation}
public typealias OptimizelyExperimentData = [String: Any]
public typealias OptimizelyVariationData = [String: Any]

public typealias GenericListener = (Any...) -> Void

public typealias ActivateListener = (_ experiment: OptimizelyExperimentData, _ userId: String, _ attributes: OptimizelyAttributes?, _ variation: OptimizelyVariationData, _ event: [String: Any]) -> Void

public typealias TrackListener = (_ eventKey: String, _ userId: String, _ attributes: OptimizelyAttributes?, _ eventTags: [String: Any]?, _ event: [String: Any]) -> Void

public typealias DecisionListener = (_ type: String, _ userId: String, _ attributes: OptimizelyAttributes?, _ decisionInfo: [String: Any]) -> Void

public typealias DatafileChangeListener = (_ datafile: Data) -> Void

public protocol OPTNotificationCenter {
    init()

// Notification Id represeting id of notification.
    var notificationId: Int { get set }

/**
 Add a generic notificaiton that can be trggered at anytime using send notification
 - Parameter notificationType: unique id for that notificaiton type
 - Parameter listener: listener to be called when the event is fired.
 */
func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) -> Int?

/**
 Add an activate notification listener to the notification center.
 - Parameter activateListener: Notification to add.
 - Returns: the notification id used to remove the notification. It is greater than 0 on success.
 */
func addActivateNotificationListener(activateListener:@escaping ActivateListener) -> Int?

/**
 Add a track notification listener to the notification center.
 - Parameter trackListener: Notification to add.
 - Returns: the notification id used to remove the notification. It is greater than 0 on success.
 */
func addTrackNotificationListener(trackListener:@escaping TrackListener) -> Int?

/**
 Add a decision notification listener to the notification center.
 - Parameter decisionListener: Notification to add.
 - Returns: the notification id used to remove the notification. It is greater than 0 on success.
 */
func addDecisionNotificationListener(decisionListener:@escaping DecisionListener) -> Int?

/**
 Add a datafile change notification listener
 - Parameter datafileListener: Notification to add.
 - Returns: the notification id used to remove the notification. It is greater than 0 on success.
 */
func addDatafileChangeNotificationListener(datafileListener:@escaping DatafileChangeListener) -> Int?

/**
 Remove the notification listener based on the notificationId passed back from addNotification.
 - Parameter notificationId: the id passed back from add notification.
 - Returns: true if removed otherwise false (if the notification is already removed, it returns false).
 */
func removeNotificationListener(notificationId: Int)

/**
 Clear notification listeners by notification type.
 - Parameter type: type of OPTLYNotificationType to remove.
 */
func clearNotificationListeners(type: NotificationType)

/**
 * Clear out all the notification listeners.
 */
func clearAllNotificationListeners()

//
/**
 fire notificaitons of a certain type.
 - Parameter type: type of OPTLYNotificationType to fire.
 - Parameter args: The arg list changes depending on the type of notification sent.
 */
func sendNotifications(type: Int, args: [Any?])
    
}

@objc(OPTNotificationCenter) public protocol ObjcOPTNotificationCenter {
    /**
     Add an activate notification listener to the notification center.
     - Parameter activateListener: Notification to add.
     - Returns: the notification id used to remove the notification. It is greater than 0 on success.
     */
    func addActivateNotificationListener(activateListener:@escaping (_ experiment: [String: Any], _ userId: String, _ attributes: [String: Any]?, _ variation: [String: Any], _ event: [String: Any]) -> Void) -> NSNumber?
    
    /**
     Add a track notification listener to the notification center.
     - Parameter trackListener: Notification to add.
     - Returns: the notification id used to remove the notification. It is greater than 0 on success.
     */
    func addTrackNotificationListener(trackListener:@escaping (_ eventKey: String, _ userId: String, _ attributes: [String: Any]?, _ eventTags: [String: Any]?, _ event: [String: Any]) -> Void) -> NSNumber?
    
    /**
     Add a decision notification listener to the notification center.
     - Parameter decisionListener: Notification to add.
     - Returns: the notification id used to remove the notification. It is greater than 0 on success.
     */
    func addDecisionNotificationListener(decisionListener:@escaping (_ type: String, _ userId: String, _ attributes: [String: Any]?, _ decisionInfo: [String: Any]) -> Void) -> NSNumber?
    
    /**
     Add a datafile change notification listener
     - Parameter datafileListener: Notification to add.
     - Returns: the notification id used to remove the notification. It is greater than 0 on success.
     */
    func addDatafileChangeNotificationListener(datafileListener:@escaping (_ datafile: Data) -> Void) -> NSNumber?
    
    /**
     Remove the notification listener based on the notificationId passed back from addNotification.
     - Parameter notificationId: the id passed back from add notification.
     - Returns: true if removed otherwise false (if the notification is already removed, it returns false).
     */
    func removeNotificationListener(notificationId: Int)
    
    /**
     Clear notification listeners by notification type.
     - Parameter type: type of OPTLYNotificationType to remove.
     */
    func clearNotificationListeners(type: NotificationType)
    
    /**
     * Clear out all the notification listeners.
     */
    func clearAllNotificationListeners()

}
