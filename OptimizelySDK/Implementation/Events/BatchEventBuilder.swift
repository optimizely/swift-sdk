//
//  BatchEventBuilder.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/13/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class BatchEventBuilder {
    static private var logger = HandlerRegistryService.shared.injectLogger()
    
    static func createImpressionEvent(config:ProjectConfig,
                                      decisionService:OPTDecisionService,
                                      experiment:Experiment,
                                      varionation:Variation,
                                      userId:String,
                                      attributes:OptimizelyAttributes?) -> Data? {
        var decisions = [Decision]()
        
        let decision = Decision(variationID: varionation.id, campaignID: experiment.layerId, experimentID: experiment.id)
        
        decisions.append(decision)
        
        // create batch event.
        let early = Date.timeIntervalBetween1970AndReferenceDate * 1000
        let after = Date.timeIntervalSinceReferenceDate * 1000
        let fullNumber:Int64 = Int64(early + after)
        let dispatchEvent = DispatchEvent(timestamp: fullNumber,
                                          key: DispatchEvent.activateEventKey,
                                          entityID: experiment.layerId,
                                          uuid: UUID().uuidString)
        let snapShot = Snapshot(decisions: decisions, events: [dispatchEvent])
        
        let eventAttributes = getEventAttributes(config: config, attributes: attributes)
        
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        let batchEvent = BatchEvent(revision: config.project.revision,
                                    accountID: config.project.accountId,
                                    clientVersion: "3.0",
                                    visitors: [visitor],
                                    projectID: config.project.projectId,
                                    clientName: "swift-sdk",
                                    anonymizeIP: config.project.anonymizeIP,
                                    enrichDecisions: true)
        
        if let data = try? JSONEncoder().encode(batchEvent) {
            return data
        }
        
        return nil

    }
    
    static func createConversionEvent(config:ProjectConfig,
                                      decisionService:OPTDecisionService,
                                      eventKey:String,
                                      userId:String,
                                      attributes:OptimizelyAttributes?,
                                      eventTags:Dictionary<String, Any>?) -> Data? {
        
        guard let event = config.project.events.filter({$0.key == eventKey}).first  else {
            return nil
        }

        // create batch event.
        let early = Date.timeIntervalBetween1970AndReferenceDate * 1000
        let after = Date.timeIntervalSinceReferenceDate * 1000
        let fullNumber:Int64 = Int64(early + after)
        let tags = eventTags?.mapValues({AttributeValue(value:$0)}).filter({$0.value != nil}) as? Dictionary<String, AttributeValue> ?? [:]
        var value:AttributeValue?
        var revenue:AttributeValue?
        
        if let val = eventTags?[DispatchEvent.valueKey], let v = AttributeValue(value: val) {
            value = v
        }
        if let rev = eventTags?[DispatchEvent.revenueKey], let r = AttributeValue(value: rev) {
            revenue = r
        }
        
        let dispatchEvent = DispatchEvent(timestamp: fullNumber, key: event.key, entityID: event.id, uuid: UUID().uuidString, tags: tags, value:value, revenue:revenue)
        
        let snapShot = Snapshot(decisions: nil, events: [dispatchEvent])
        
        let eventAttributes = getEventAttributes(config: config, attributes: attributes)
        
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        
        let batchEvent = BatchEvent(revision: config.project.revision,
                                    accountID: config.project.accountId,
                                    clientVersion: "3.0",
                                    visitors: [visitor],
                                    projectID: config.project.projectId,
                                    clientName: "swift-sdk",
                                    anonymizeIP: config.project.anonymizeIP,
                                    enrichDecisions:true)
        
        if let data = try? JSONEncoder().encode(batchEvent) {
            return data
        }

        return nil
    }
    
    static func getEventAttributes(config: ProjectConfig,
                                   attributes: OptimizelyAttributes?) -> [EventAttribute] {
        var eventAttributes = [EventAttribute]()
        
        if let attributes = attributes {
            for attr in attributes.keys {
                if let attributeId = config.project.attributes.filter({$0.key == attr}).first?.id ?? (attr.hasPrefix("$opt_") ? attr : nil) {
                    let attrValue = attributes[attr] ?? nil    // default to nil to avoid warning "coerced from 'Any??' to 'Any?'"
                    if let eventValue = AttributeValue(value: attrValue) {
                        let eventAttribute = EventAttribute(value: eventValue,
                                                            key: attr,
                                                            type: "custom",
                                                            entityID: attributeId)
                        eventAttributes.append(eventAttribute)
                    }
                }
                else {
                    logger?.log(level: .debug, message: "Attribute " + attr + " skipped. Not in datafile.")
                }
            }
        }
        
        if let botFiltering = config.project.botFiltering, let attrValue = AttributeValue(value: botFiltering) {
            let botAttr = EventAttribute(value: attrValue,
                                         key: Constants.Attributes.OptimizelyBotFilteringAttribute,
                                         type:"custom",
                                         entityID: Constants.Attributes.OptimizelyBotFilteringAttribute)
            eventAttributes.append(botAttr)
        }
        return eventAttributes
    }

}
