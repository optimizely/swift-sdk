//
//  BatchEventBuilder.swift
//  OptimizelyCore
//
//  Created by Thomas Zurkan on 12/13/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class BatchEventBuilder {
    static private var logger = DefaultLogger.createInstance(logLevel: OptimizelyLogLevel.OptimizelyLogLevelDebug)
    static func createImpressionEvent(config:ProjectConfig, decisionService:DecisionService, experiment:Experiment, varionation:Variation, userId:String, attributes:Dictionary<String,Any>?) -> Data? {
        var decisions = [Decision]()
        
        let decision = Decision(variationID: varionation.id, campaignID: experiment.layerId, experimentID: experiment.id)
        
        decisions.append(decision)
        
        // create batch event.
        let early = Date.timeIntervalBetween1970AndReferenceDate * 1000
        let after = Date.timeIntervalSinceReferenceDate * 1000
        let fullNumber:Int64 = Int64(early + after)
        let dispatchEvent = DispatchEvent(timestamp: fullNumber, key: DispatchEvent.activateEventKey, entityID: experiment.layerId, uuid: UUID().uuidString)
        let snapShot = Snapshot(decisions: decisions, events: [dispatchEvent])
        
        var eventAttributes = [EventAttribute]()
        
        if let attributes = attributes {
            for attr in attributes.keys {
                if let eventAttribute = config.attributes.filter({$0.key == attr}).first {
                    if let eventValue = AttributeValue(value:attributes[attr]) {
                        let eventAttribute = EventAttribute(value: eventValue, key: attr, shouldIndex: true, type: "custom_attribute", entityID: eventAttribute.id)
                        eventAttributes.append(eventAttribute)
                    }
                }
                else {
                    logger?.log(level: .OptimizelyLogLevelDebug, message: "Attribute " + attr + "skipped")
                }
            }
        }
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        let batchEvent = BatchEvent(revision: config.revision, accountID: config.accountId, clientVersion: "1.0", visitors: [visitor], projectID: config.projectId, clientName: "swift-sdk", anonymizeIP: config.anonymizeIP ?? false)
        
        if let data = try? JSONEncoder().encode(batchEvent) {
            return data
        }
        
        return nil

    }
    
    static func createConversionEvent(config:ProjectConfig, decisionService:DecisionService, eventKey:String, userId:String, attributes:Dictionary<String,Any>?, eventTags:Dictionary<String, Any>?) -> Data? {
        
        guard let event = config.events?.filter({$0.key == eventKey}).first  else {
            return nil
        }
        let experimentIds = event.experimentIds
        let experiments = experimentIds.map { (id) -> Experiment? in
            config.experiments.filter({$0.id == id}).first
        }
        var decisions = [Decision]()
        for experiment in experiments where experiment != nil && experiment?.status == Experiment.Status.Running {
            if let variation = decisionService.getVariation(userId: userId, experiment: experiment!, attributes: attributes ?? [String:Any]()) {
                decisions.append(Decision(variationID: variation.id, campaignID: experiment!.layerId, experimentID: experiment!.id))
            }
        }
        
    // create batch event.
        let early = Date.timeIntervalBetween1970AndReferenceDate * 1000
        let after = Date.timeIntervalSinceReferenceDate * 1000
        let fullNumber:Int64 = Int64(early + after)
        let tags = eventTags?.mapValues({AttributeValue(value:$0)}).filter({$0.value != nil}) as? Dictionary<String, AttributeValue>
        var value:AttributeValue?
        var revenue:AttributeValue?
        
        if let val = eventTags?[DispatchEvent.valueKey], let v = AttributeValue(value: val) {
            value = v
        }
        if let rev = eventTags?[DispatchEvent.revenueKey], let r = AttributeValue(value: rev) {
            revenue = r
        }
        
        let dispatchEvent = DispatchEvent(timestamp: fullNumber, key: event.key, entityID: event.id, uuid: UUID().uuidString, tags: tags, value:value, revenue:revenue)
        
        let snapShot = Snapshot(decisions: decisions, events: [dispatchEvent])
        
        var eventAttributes = [EventAttribute]()
        
        if let attributes = attributes {
            for attr in attributes.keys {
                if let eventAttribute = config.attributes.filter({$0.key == attr}).first {
                    if let eventValue = AttributeValue(value:attributes[attr]) {
                        let eventAttribute = EventAttribute(value: eventValue, key: attr, shouldIndex: true, type: "custom_attribute", entityID: eventAttribute.id)
                        eventAttributes.append(eventAttribute)
                    }
                }
                else {
                    logger?.log(level: .OptimizelyLogLevelDebug, message: String(format:"Attribute %s skipped.  Not in datafile. ", attr))
                }
            }
        }
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        let batchEvent = BatchEvent(revision: config.revision, accountID: config.accountId, clientVersion: "1.0", visitors: [visitor], projectID: config.projectId, clientName: "swift-sdk", anonymizeIP: config.anonymizeIP ?? false)
        
        if let data = try? JSONEncoder().encode(batchEvent) {
            return data
        }

        return nil
    }

}
