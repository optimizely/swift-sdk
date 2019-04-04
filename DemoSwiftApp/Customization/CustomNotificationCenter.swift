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
    
    func addFeatureFlagRolloutChangeListener(featureListener: @escaping FeatureFlagRolloutChangeListener) -> Int? {
        return nil
    }
    
    var notificationId: Int
    
    required init() {
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
    
    func addDecisionNotificationListener(decisionListener: @escaping DecisionListener) -> Int? {
        //
        return nil
    }
    
    func addDatafileChangeNotificationListener(datafileListener: @escaping DatafileChangeListener) -> Int? {
        return nil
    }
    
}
