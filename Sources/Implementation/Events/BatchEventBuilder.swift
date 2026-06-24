//
// Copyright 2019, 2021-2022, Optimizely, Inc. and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

class BatchEventBuilder {
    static private var logger = OPTLoggerFactory.getLogger()
    
    // MARK: - Impression Event
    
    static func createImpressionEvent(config: ProjectConfig,
                                      experiment: ExperimentCore?,
                                      variation: Variation?,
                                      userId: String,
                                      attributes: OptimizelyAttributes?,
                                      flagKey: String,
                                      ruleType: String,
                                      enabled: Bool,
                                      cmabUUID: String?) -> Data? {

        let metaData = DecisionMetadata(ruleType: ruleType, ruleKey: experiment?.key ?? "", flagKey: flagKey, variationKey: variation?.key ?? "", enabled: enabled, cmabUUID: cmabUUID)

        let rawCampaignId = experiment?.layerId ?? ""
        let rawVariationId = variation?.id
        let experimentId = experiment?.id ?? ""

        let isHoldout = (ruleType == Constants.DecisionSource.holdout.rawValue)
        let (campaignId, variationId) = normalizeDecisionIds(rawCampaignId: rawCampaignId,
                                                             rawVariationId: rawVariationId,
                                                             experimentId: experimentId,
                                                             isHoldout: isHoldout)

        let decision = Decision(variationID: variationId,
                                campaignID: campaignId,
                                experimentID: experimentId,
                                metaData: metaData)

        let dispatchEvent = DispatchEvent(timestamp: timestampSince1970,
                                          key: DispatchEvent.activateEventKey,
                                          entityID: rawCampaignId,
                                          uuid: uuid)

        return createBatchEvent(config: config,
                                userId: userId,
                                attributes: attributes,
                                decisions: [decision],
                                dispatchEvents: [dispatchEvent])
    }

    // MARK: - Holdout Event ID Normalization (FSSDK-12813)

    /// Normalizes `campaign_id` and `variation_id` for holdout decision events so
    /// the on-the-wire payload always carries pipeline-valid values.
    ///
    /// For **holdout** decisions only:
    /// - `campaign_id` falls back to `experiment_id` when the raw value is not a
    ///   non-empty decimal-digit string (empty, whitespace, null/nil, or non-numeric).
    /// - `variation_id` is normalized to `nil` (emitted as JSON `null`) when the
    ///   raw value is not a non-empty decimal-digit string.
    ///
    /// For all non-holdout decisions the original (pre-fix) behavior is preserved:
    /// `campaign_id` is the raw value (or empty string) and `variation_id` is the
    /// raw value (or empty string) — wrapped in Optional purely so the `Decision`
    /// struct can share one storage type across both branches.
    static func normalizeDecisionIds(rawCampaignId: String,
                                     rawVariationId: String?,
                                     experimentId: String,
                                     isHoldout: Bool) -> (campaignId: String, variationId: String?) {
        guard isHoldout else {
            // Preserve legacy behavior for non-holdout decisions (FR-005).
            return (rawCampaignId, rawVariationId ?? "")
        }

        // Holdout: campaign_id must be a numeric string, otherwise fall back to
        // experiment_id (FR-001/FR-002). Whitespace-only and non-numeric strings
        // are treated as invalid; the upstream experiment_id is passed through
        // unchanged even if it is itself invalid (FR-006 — never drop the event).
        let campaignId = isValidNumericIdString(rawCampaignId) ? rawCampaignId : experimentId

        // Holdout: variation_id must be a numeric string or JSON null
        // (FR-003/FR-004). Anything else (empty, whitespace, non-numeric) becomes
        // nil so the encoder emits JSON `null`.
        let variationId: String?
        if let raw = rawVariationId, isValidNumericIdString(raw) {
            variationId = raw
        } else {
            variationId = nil
        }

        return (campaignId, variationId)
    }

    /// Returns true iff `value` is a non-empty string consisting entirely of
    /// decimal digits `[0-9]`. Empty strings, whitespace-only strings, and any
    /// string containing non-digit characters return false. Leading zeros are
    /// allowed because Optimizely IDs are opaque identifiers (see spec).
    static func isValidNumericIdString(_ value: String) -> Bool {
        guard !value.isEmpty else { return false }
        // `CharacterSet.decimalDigits` includes non-ASCII digit forms (e.g.
        // Arabic-Indic digits). Spec restricts validity to ASCII `[0-9]`, so we
        // walk the unicode scalars explicitly instead of using
        // `rangeOfCharacter(from: CharacterSet.decimalDigits.inverted)`.
        for scalar in value.unicodeScalars {
            if scalar.value < 0x30 || scalar.value > 0x39 {
                return false
            }
        }
        return true
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
        let eventRegion = config.region
        let snapShot = Snapshot(decisions: decisions, events: dispatchEvents)
        
        let eventAttributes = getEventAttributes(config: config, attributes: attributes)
        
        let visitor = Visitor(attributes: eventAttributes, snapshots: [snapShot], visitorID: userId)
        
        let batchEvent = BatchEvent(revision: config.project.revision,
                                    accountID: config.project.accountId,
                                    clientVersion: Utils.sdkVersion,
                                    visitors: [visitor],
                                    projectID: config.project.projectId,
                                    clientName: Utils.swiftSdkClientName,
                                    anonymizeIP: config.project.anonymizeIP,
                                    enrichDecisions: true,
                                    region: eventRegion.rawValue)

        let data = try? JSONEncoder().encode(batchEvent)
        let eventForDispatch = EventForDispatch(url: nil, body: data ?? Data(), region: eventRegion)
        
        return eventForDispatch.body
    }
    
    // MARK: - Event Tags
    
    static func filterEventTags(_ eventTags: [String: Any]?) -> ([String: AttributeValue], Double?, Int64?) {
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
        return eventTags.compactMapValues { AttributeValue(value: $0) }
    }
    
    static func extractValueEventTag(_ eventTags: [String: AttributeValue]) -> Double? {
        guard let valueFromTags = eventTags[DispatchEvent.valueKey] else { return nil }
        
        // export {value, revenue} only for {double, int64} types
        var value: Double?
        
        switch valueFromTags {
        case .double(let attrValue):
            // valid value type
            value = attrValue
        case .int(let attrValue):
            value = Double(attrValue)
        default:
            value = nil
        }
        
        if let value = value {
            logger.i(.extractValueFromEventTags("\(value)"))
        } else {
            logger.i(.failedToExtractValueFromEventTags(valueFromTags.stringValue))
        }
        
        return value
    }
    
    static func extractRevenueEventTag(_ eventTags: [String: AttributeValue]) -> Int64? {
        guard let revenueFromTags = eventTags[DispatchEvent.revenueKey] else { return nil }
        
        // export {value, revenue} only for {double, int64} types
        var revenue: Int64?
        
        switch revenueFromTags {
        case .int(let value):
            // valid revenue type
            revenue = Int64(value)
        case .double(let value):
            // not accurate but acceptable ("3.14" -> "3")
            revenue = Int64(value)
        default:
            revenue = nil
        }
        
        if let revenue = revenue {
            logger.i(.extractRevenueFromEventTags("\(revenue)"))
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
                                         key: Constants.Attributes.reservedBotFilteringAttribute,
                                         type: "custom",
                                         entityID: Constants.Attributes.reservedBotFilteringAttribute)
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
