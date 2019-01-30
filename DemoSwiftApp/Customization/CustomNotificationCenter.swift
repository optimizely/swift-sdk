//
//  CustomNotificationCenter.swift
//  DemoSwiftiOS
//
//  Created by Jae Kim on 1/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import Optimizely

class CustomNotificationCenter: OPTNotificationCenter {
    var notificationId: Int
    
    init() {
        notificationId = 0
    }
    
    static func createInstance() -> OPTNotificationCenter? {
        return CustomNotificationCenter()
    }

    func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) -> Int? {
        return nil
    }
    
    func removeNotificationListener(notificationId: Int) {
        //
    }
    
    func clearNotificationListeners(type: NotificationType) {
        //
    }
    
    func clearAllNotificationListeners() {
        //
    }
    
    func sendNotifications(type: Int, args: Array<Any?>) {
        //
    }
    
    func addActivateNotificationListener(activateListener: @escaping ActivateListener) -> Int? {
        //
        return nil
    }
    
    func addTrackNotificationListener(trackListener: @escaping TrackListener) -> Int? {
        //
        return nil
    }
}
