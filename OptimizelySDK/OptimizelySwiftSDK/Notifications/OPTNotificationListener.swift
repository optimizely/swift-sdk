//
//  OPTNotificationListener.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 1/22/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

// MARK: Listener Protocol

protocol CoreNotificationListener {
    
    init(callback: @escaping OPTNotificationListenr)
    
    func notify(data: Array<Any?>) throws
    
    func isNotficationType(of: OPTNotificationType) -> Bool
}

extension CoreNotificationListener {
    func notifyIfTypeMatched(type: OPTNotificationType, data: Array<Any?>) throws {
        guard isNotficationType(of: type) else { return }
        try notify(data: data)
    }
}

// MARK: Listener Types

struct CoreGenericListner: CoreNotificationListener {
    let callback: OPTNotificationListenr
    
    init(callback: @escaping OPTNotificationListenr) {
        self.callback = callback
    }
    
    func notify(data: Array<Any?>) throws {
        callback([:])
    }
    
    func isNotficationType(of type: OPTNotificationType) -> Bool {
        return type == .generic
    }
}


struct CoreActivateListner: CoreNotificationListener {
    let callback: OPTNotificationListenr
    
    init(callback: @escaping OPTNotificationListenr) {
        self.callback = callback
    }
    
    // experimentKey: String
    // userId: String
    // attributes: Dictionary<String,Any>?
    // variationKey: String,
    // event: Dictionary<String, Any>
    
    func notify(data: Array<Any?>) throws {
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
            
            //entry(experiment.key, userId, attributes, variation.key, event)
            callback([:])
        }
    }
    
    func isNotficationType(of type: OPTNotificationType) -> Bool {
        return type == .activate
    }
}

public struct CoreTrackListner: CoreNotificationListener {
    let callback: OPTNotificationListenr
    
    init(callback: @escaping OPTNotificationListenr) {
        self.callback = callback
    }
    
    // eventKey: String
    // userId: String
    // attributes: Dictionary<String, Any>?
    // eventTags: Dictionary<String, Any>?
    // event: Dictionary<String, Any>
    
    func notify(data: Array<Any?>) {
        
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
            
            //trackListener(eventKey, userId, attributes, eventTags, event)
            callback([:])
        }
    }
    
    func isNotficationType(of type: OPTNotificationType) -> Bool {
        return type == .track
    }
}
