//
//  OPTNotificationListener.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 1/22/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

// MARK: notification type

enum NotificationType: Int {
    case generic = 0
    case activate
    case track
}

// MARK: Listener Protocol

protocol CoreNotificationListener {
    func notify(data: [Any]) throws
    func isNotficationType(of: NotificationType) -> Bool
}

extension CoreNotificationListener {
    func notifyTypeMatched(type: NotificationType, data: [Any]) throws {
        guard isNotficationType(of: type) else { return }
        try notify(data: data)
    }
}

// MARK: Listener Types

struct CoreGenericListner: CoreNotificationListener {
    let callback: OPTGenericCallback
    
    init(callback: @escaping OPTGenericCallback) {
        self.callback = callback
    }
    
    func notify(data: [Any]) throws {
        callback([:])
    }
    
    func isNotficationType(of type: NotificationType) -> Bool {
        return type == .generic
    }
}

struct CoreActivateListner: CoreNotificationListener {
    let callback: OPTActivateCallback
    
    init(callback: @escaping OPTActivateCallback) {
        self.callback = callback
    }
    
    // experimentKey: String
    // userId: String
    // attributes: Dictionary<String,Any>?
    // variationKey: String,
    // event: Dictionary<String, Any>
    
    func notify(data: [Any]) throws {
        
        guard let data = data.first as? [Any?] else {
            // TODO: refine error-type
            throw OPTError.generic
        }

        guard data.count >= 5 else {
            // TODO: refine error-type
            throw OPTError.generic
        }

        if let experiment = data[0] as? OPTExperiment,
            let userId = data[1] as? String,
            let variation = data[3] as? OPTVariation
        {
            let attributes = data[2] as? Dictionary<String, Any>
            let event = data[4] as! Dictionary<String,Any>

            callback(experiment.key, userId, attributes, variation.key, event)
        }
    }
    
    func isNotficationType(of type: NotificationType) -> Bool {
        return type == .activate
    }
}

struct CoreTrackListner: CoreNotificationListener {
    let callback: OPTTrackCallback
    
    init(callback: @escaping OPTTrackCallback) {
        self.callback = callback
    }
    
    // eventKey: String
    // userId: String
    // attributes: Dictionary<String, Any>?
    // eventTags: Dictionary<String, Any>?
    // event: Dictionary<String, Any>
    
    func notify(data: [Any]) {

        guard let data = data[0] as? [Any?] else {
            return
        }
        if data.count < 5 {
            return
        }
        if let eventKey = data[0] as? String,
            let userId = data[1] as? String
        {
            let attributes = data[2] as? Dictionary<String, Any>
            let eventTags = data[3] as? Dictionary<String,Any>
            let event = data[4] as! Dictionary<String,Any>

            callback(eventKey, userId, attributes, eventTags, event)
        }
    }
    
    func isNotficationType(of type: NotificationType) -> Bool {
        return type == .track
    }
}
