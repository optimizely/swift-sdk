//
//  CustomNotificationCenter.swift
//  DemoSwiftiOS
//
//  Created by Jae Kim on 1/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
import OptimizelySwiftSDK

typealias OPTNotificationCenter = OptimizelySwiftSDK.OPTNotificationCenter

class CustomNotificationCenter: OPTNotificationCenter {
    var notificationId: Int
    
    init() {
        notificationId = 0
    }
    
    static func createInstance() -> OPTNotificationCenter? {
        return CustomNotificationCenter()
    }

    func addGenericNotificationListener(notificationType: Int, listener: @escaping GenericListener) {
        //
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
    
    func addActivateNotificationListener(activateListener: @escaping ActivateListener) {
        //
    }
    
    func addTrackNotificationListener(trackListener: @escaping TrackListener) {
        //
    }
}
