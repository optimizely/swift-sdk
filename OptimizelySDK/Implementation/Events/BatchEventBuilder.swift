/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import Foundation

class BatchEventBuilder {
    static private let swiftSdkClientName = "swift-sdk"
    
    static private var logger = OPTLoggerFactory.getLogger()
    
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
                                 dispatchEvents: [DispatchEvent]) -> Data? {
        let snapShot = Snapshot(decisions: decisions, events: dispatchEvents)
        
        let eventAttributes = getEventAttributes(config: config, attributes: attributes)
        
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        
        let batchEvent = BatchEvent(revision: config.project.revision,
                                    accountID: config.project.accountId,
                                    clientVersion: Utils.sdkVersion,
                                    visitors: [visitor],
                                    projectID: config.project.projectId,
                                    clientName: swiftSdkClientName,
                                    anonymizeIP: config.project.anonymizeIP,
                                    enrichDecisions: true)
        
        return try? JSONEncoder().encode(batchEvent)
    }
            
    // MARK: - Event Tags
    
    static func filterEventTags(_ eventTags: [String: Any]?) -> ([String: AttributeValue], AttributeValue?, AttributeValue?) {
        guard let eventTags = eventTags else {
            return ([:], nil, nil)
        }
        
        // should not pass tags of invalid types to the server (which will drop entire event if so)
        let filteredTags = filterTagsWithInvalidTypes(eventTags)
        
        // {revenue, value} keys are special - must be copied as separate properties
        let value = extractValueEventTag(filteredTags)
        let revenue = extractRevenueEventTag(filteredTags)
        
        return (filteredTags, value, revenue)
    }
    
    static func filterTagsWithInvalidTypes(_ eventTags: [String: Any]) -> [String: AttributeValue] {
        let filteredTags = eventTags.mapValues { AttributeValue(value: $0) }.filter { $0.value != nil } as? [String: AttributeValue]
        return filteredTags ?? [:]
    }
    
    static func extractValueEventTag(_ eventTags: [String: AttributeValue]) -> AttributeValue? {
        guard let valueFromTags = eventTags[DispatchEvent.valueKey] else { return nil }
        
        // export {value, revenue} only for {double, int64} types
        var value: AttributeValue?
        
        switch valueFromTags {
        case .double:
            // valid value type
            value = valueFromTags
        case .int(let int64Value):
            value = AttributeValue(value: Double(int64Value))
        default:
            value = nil
        }
        
        if let value = value {
            logger.i(.extractValueFromEventTags(value.stringValue))
        } else {
            logger.i(.failedToExtractValueFromEventTags(valueFromTags.stringValue))
        }
        
        return value
    }
    
    static func extractRevenueEventTag(_ eventTags: [String: AttributeValue]) -> AttributeValue? {
        guard let revenueFromTags = eventTags[DispatchEvent.revenueKey] else { return nil }
        
        // export {value, revenue} only for {double, int64} types
        var revenue: AttributeValue?
        
        switch revenueFromTags {
        case .int:
            // valid revenue type
            revenue = revenueFromTags
        case .double(let doubleValue):
            // not accurate but acceptable ("3.14" -> "3")
            revenue = AttributeValue(value: Int64(doubleValue))
        default:
            revenue = nil
        }
        
        if let revenue = revenue {
            logger.i(.extractRevenueFromEventTags(revenue.stringValue))
        } else {
            logger.i(.failedToExtractRevenueFromEventTags(revenueFromTags.stringValue))
        }
        
        return revenue
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
                } else {
                    logger.d(.unrecognizedAttribute(attr))
                }
            }
        }
        
        if let botFiltering = config.project.botFiltering, let eventValue = AttributeValue(value: botFiltering) {
            let botAttr = EventAttribute(value: eventValue,
                                         key: Constants.Attributes.OptimizelyBotFilteringAttribute,
                                         type: "custom",
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
