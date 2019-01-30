//
//  OPTNotificationListener.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 1/22/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation

// MARK: Listener Protocol

protocol CoreEventListener {
    func isType(of type: OptimizelyNotificationType) -> Bool
    func notify(data: [Any]) throws
}

extension CoreEventListener {
    func notify(type: OptimizelyNotificationType, data: [Any]) throws {
        guard isType(of: type) else { return }
        
        try notify(data: data)
    }
}

// MARK: Listener Types

struct GenericEventListner: CoreEventListener {
    let callback: OptimizelyGenericCallback
    
    init(callback: @escaping OptimizelyGenericCallback) {
        self.callback = callback
    }
    
    func isType(of type: OptimizelyNotificationType) -> Bool {
        return type == .generic
    }
    
    func notify(data: [Any]) throws {
        callback(data)
    }
}

struct ActivateEventListner: CoreEventListener {
    let callback: OptimizelyActivateCallback
    
    init(callback: @escaping OptimizelyActivateCallback) {
        self.callback = callback
    }
    
    func isType(of type: OptimizelyNotificationType) -> Bool {
        return type == .activate
    }

    // experimentKey: String
    // userId: String
    // attributes: Dictionary<String,Any>?
    // variationKey: String,
    // event: Dictionary<String, Any>
    
    func notify(data: [Any]) throws {
        
        guard let data = data.first as? [Any?] else {
            // TODO: refine error-type
            throw OptimizelyError.generic
        }

        guard data.count >= 5 else {
            // TODO: refine error-type
            throw OptimizelyError.generic
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
}

struct TrackEventListner: CoreEventListener {
    let callback: OptimizelyTrackCallback
    
    init(callback: @escaping OptimizelyTrackCallback) {
        self.callback = callback
    }
    
    func isType(of type: OptimizelyNotificationType) -> Bool {
        return type == .track
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
}
