//
//  File.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

/// Enum representing notification types.
public enum NotificationType : Int {
    case Activate = 1
    case Track
}

public typealias GenericListener = (Any...) -> Void

public typealias ActivateListener = (_ experiment:Experiment, _ userId:String, _ attributes:Dictionary<String,Any>?, _ variation:Variation) -> Void

public typealias TrackListener = (_ eventKey:String, _ userId:String, _ attributes:Dictionary<String, Any>?, _ eventTags:Dictionary<String, Any>?) -> Void

public protocol NotificationCenter {

    static func createInstance() -> NotificationCenter?

// Notification Id represeting id of notification.
    var notificationId:Int { get set }

/**
 * Add a generic notificaiton that can be
 */
func addGenericNotificationListener(notificationType:Int, listener: @escaping GenericListener)

/**
 * Add an activate notification listener to the notification center.
 *
 * @param activateListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
func addActivateNotificationListener(activateListener:@escaping ActivateListener)

/**
 * Add a track notification listener to the notification center.
 *
 * @param trackListener - Notification to add.
 * @return the notification id used to remove the notification. It is greater than 0 on success.
 */
func addTracNotificationListener(trackListener:@escaping TrackListener)

/**
 * Remove the notification listener based on the notificationId passed back from addNotification.
 * @param notificationId the id passed back from add notification.
 * @return true if removed otherwise false (if the notification is already removed, it returns false).
 */
func removeNotificationListener(notificationId:Int)

/**
 * Clear notification listeners by notification type.
 * @param type type of OPTLYNotificationType to remove.
 */
func clearNotificationListeners(type:NotificationType)

/**
 * Clear out all the notification listeners.
 */
func clearAllNotificationListeners()

//
/**
 * fire notificaitons of a certain type.
 * @param type type of OPTLYNotificationType to fire.
 * @param args The arg list changes depending on the type of notification sent.
 */
func sendNotifications(type:Int, args:Array<Any?>)
    
}

