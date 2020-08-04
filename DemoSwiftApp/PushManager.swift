//
//  PushManager.swift
//  PushExp
//
//  Created by Jae Kim on 7/15/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import UIKit
import UserNotifications
import Optimizely

class PushManager: NSObject {
    
    var currentDeviceToken: String?
    
    override init() {}
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter
            .current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                NSLog("[PushExp] Push Permission granted: \(granted)")
                
                guard granted else { return }
                self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter
            .current()
            .getNotificationSettings { settings in
                NSLog("[PushExp] Notification Settings: \(settings)")
                
                guard settings.authorizationStatus == .authorized else { return }
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
        }
    }
    
    func registerDeviceTokenToServer(deviceToken: Data) {
        currentDeviceToken = deviceToken.map{ byte in String(format: "%02x", byte) }.joined()
        
        guard let token = currentDeviceToken else { return }
        
        NSLog("[PushExp] Push DeviceToken Registered: \(token) ")
        
        // token should be forwarded to the server for sending push
        // but we do manual push-testing with Mac PushNotifications app, so skip the process.
    }
    
}

// MARK: - custom push message processing

extension PushManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("[PushExp] Open App By Touching Push Notification: \(response.notification.request.content)")
    
        completionHandler()
    }
}
