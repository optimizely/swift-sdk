//
//  BatchEventBuilder.swift
//  OptimizelySDK
//
//  Created by Thomas Zurkan on 12/13/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import Foundation

class BatchEventBuilder {
    static private let swiftSdkClientName = "swift-sdk"
    static private var swiftSdkClientVersion = {
        // TODO: fix this version controlled via xcode settings
        return "3.0.0"
    }()
    
    static private var logger = HandlerRegistryService.shared.injectLogger()
    
    // MARK: - Impression Event
    
    static func createImpressionEvent(config: ProjectConfig,
                                      experiment: Experiment,
                                      varionation: Variation,
                                      userId: String,
                                      attributes: OptimizelyAttributes?) -> Data? {
        
        let decision = Decision(variationID: varionation.id,
                                campaignID: experiment.layerId,
                                experimentID: experiment.id)
        
        let dispatchEvent = DispatchEvent(timestamp: timestampSince1970,
                                          key: DispatchEvent.activateEventKey,
                                          entityID: experiment.layerId,
                                          uuid: uuid)
        
        return createBatchEvent(config: config,
                                userId: userId,
                                attributes: attributes,
                                decisions: [decision],
                                dispatchEvents: [dispatchEvent])
    }
    
    // MARK: - Converison Event
    
    static func createConversionEvent(config: ProjectConfig,
                                      eventKey: String,
                                      userId: String,
                                      attributes: OptimizelyAttributes?,
                                      eventTags: [String: Any]?) -> Data? {
        
        guard let event = config.getEvent(key: eventKey) else {
            return nil
        }
        
        // filter and convert event tags
        let (tags, value, revenue) = filterEventTags(eventTags)
        
        let dispatchEvent = DispatchEvent(timestamp: timestampSince1970,
                                          key: event.key,
                                          entityID: event.id,
                                          uuid: uuid,
                                          tags: tags,
                                          value: value,
                                          revenue: revenue)
        
        return createBatchEvent(config: config,
                                userId: userId,
                                attributes: attributes,
                                decisions: nil,
                                dispatchEvents: [dispatchEvent])
    }
    
    // MARK: - Create Event
    
    static func createBatchEvent(config: ProjectConfig,
                                 userId: String,
                                 attributes: OptimizelyAttributes?,
                                 decisions: [Decision]?,
                                 dispatchEvents: [DispatchEvent]) -> Data?
    {
        let snapShot = Snapshot(decisions: decisions, events: dispatchEvents)
        
        let eventAttributes = getEventAttributes(config: config, attributes: attributes)
        
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        
        let batchEvent = BatchEvent(revision: config.project.revision,
                                    accountID: config.project.accountId,
                                    clientVersion: swiftSdkClientVersion,
                                    visitors: [visitor],
                                    projectID: config.project.projectId,
                                    clientName: swiftSdkClientName,
                                    anonymizeIP: config.project.anonymizeIP,
                                    enrichDecisions: true)
        
        return try? JSONEncoder().encode(batchEvent)
    }
            
    // MARK: - Event Tags
    
    static func filterEventTags(_ eventTags: [String: Any]?) -> ([String: AttributeValue]?, AttributeValue?, AttributeValue?) {
        guard let eventTags = eventTags else {
            return ([:], nil, nil)
        }
        
        let tags = eventTags.mapValues{AttributeValue(value:$0)}.filter{$0.value != nil} as? [String: AttributeValue] ?? [:]
        var value = tags[DispatchEvent.valueKey]
        var revenue = tags[DispatchEvent.revenueKey]
        
        // export {value, revenue} only for {double, int64} types
        
        if let _value = value {
            switch _value {
            case .double:
                // valid value type
                break
            case .int(let int64Value):
                value = AttributeValue(value: Double(int64Value))
            default:
                value = nil
            }
        }
        
        if let _revenue = revenue {
            switch _revenue {
            case .int:
                // valid revenue type
                break
            case .double(let doubleValue):
                
                // TODO: [Jae] is this double-to-integer conversion safe?
                
                // - special integer types ("NSNumber(intValue: )", ...) are parsed as .double()
                //   since double has higher pririorty when cannot tell from {integer, double}
                // - check if integer value
                if doubleValue == Double(Int64(doubleValue)){
                    revenue = AttributeValue(value: Int64(doubleValue))
                } else {
                    revenue = nil
                }
            default:
                revenue = nil
            }
        }

        return (tags, value, revenue)
    }
    
    
    // MARK: - Event Attributes
    
    static func getEventAttributes(config: ProjectConfig,
                                   attributes: OptimizelyAttributes?) -> [EventAttribute] {
        var eventAttributes = [EventAttribute]()
        
        if let attributes = attributes {
            for attr in attributes.keys {
                if let attributeId = config.getAttributeId(key: attr) ?? (attr.hasPrefix("$opt_") ? attr : nil) {
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
        
        if let botFiltering = config.project.botFiltering, let eventValue = AttributeValue(value: botFiltering) {
            let botAttr = EventAttribute(value: eventValue,
                                         key: Constants.Attributes.OptimizelyBotFilteringAttribute,
                                         type:"custom",
                                         entityID: Constants.Attributes.OptimizelyBotFilteringAttribute)
            eventAttributes.append(botAttr)
        }
        
        return eventAttributes
    }
    
    // MARK: - Utils
    
    static var timestampSince1970: Int64 {
        let early = Date.timeIntervalBetween1970AndReferenceDate * 1000
        let after = Date.timeIntervalSinceReferenceDate * 1000
        return Int64(early + after)
    }
    
    static var uuid: String {
        return UUID().uuidString
    }
    
}
