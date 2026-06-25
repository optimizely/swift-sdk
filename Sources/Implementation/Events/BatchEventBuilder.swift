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

        let (campaignId, variationId) = normalizeDecisionIds(rawCampaignId: rawCampaignId,
                                                             rawVariationId: rawVariationId,
                                                             experimentId: experimentId)

        let decision = Decision(variationID: variationId,
                                campaignID: campaignId,
                                experimentID: experimentId,
                                metaData: metaData)

        // FR-009: events[].entity_id shares the same source as
        // decisions[].campaign_id (experiment.layerId) and the same fallback
        // contract. Use the normalized value so the two fields never diverge
        // on the wire — see spec US3 / SC-006.
        let dispatchEvent = DispatchEvent(timestamp: timestampSince1970,
                                          key: DispatchEvent.activateEventKey,
                                          entityID: campaignId,
                                          uuid: uuid)

        return createBatchEvent(config: config,
                                userId: userId,
                                attributes: attributes,
                                decisions: [decision],
                                dispatchEvents: [dispatchEvent])
    }

    // MARK: - Decision Event ID Normalization (FSSDK-12813)

    /// Normalizes `campaign_id` and `variation_id` so every dispatched decision
    /// event carries pipeline-valid values, regardless of decision type
    /// (experiment, feature test, rollout, or holdout). See spec FR-001–FR-005.
    ///
    /// - `campaign_id` falls back to `experiment_id` when the raw value is an
    ///   empty string. Any non-empty string (numeric like `"12345"` or opaque
    ///   like `"layer_abc"`/`"default-12345"`) is accepted and passes through
    ///   unchanged. The fallback fires on holdout events (which legitimately
    ///   may lack `layerId`) and acts as a safety net for any future malformed
    ///   input. See spec FR-001 / FR-002 (relaxed per 2026-06-24 update).
    /// - `variation_id` keeps the stricter numeric-string contract: it becomes
    ///   `nil` (emitted as JSON `null`) when the raw value is not a non-empty
    ///   decimal-digit string. See spec FR-003 / FR-004.
    static func normalizeDecisionIds(rawCampaignId: String,
                                     rawVariationId: String?,
                                     experimentId: String) -> (campaignId: String, variationId: String?) {
        // campaign_id only needs to be a non-empty string of any character
        // content. If it is empty, fall back to experiment_id. The upstream
        // experiment_id is passed through unchanged even if it is itself
        // invalid (FR-006 — never drop the event).
        let campaignId = isNonEmptyString(rawCampaignId) ? rawCampaignId : experimentId

        // variation_id must be a numeric string or JSON null. Anything else
        // (empty, whitespace, non-numeric) becomes nil so the encoder emits
        // JSON `null`.
        let variationId: String?
        if let raw = rawVariationId, isValidNumericIdString(raw) {
            variationId = raw
        } else {
            variationId = nil
        }

        return (campaignId, variationId)
    }

    /// Returns true iff `value` is a non-empty string. Used for the relaxed
    /// `campaign_id` / `entity_id` validation per spec FR-001 / FR-009 — any
    /// non-empty string passes regardless of character content (IDs may be
    /// opaque, e.g. `"default-12345"`, `"layer_abc"`).
    static func isNonEmptyString(_ value: String) -> Bool {
        return !value.isEmpty
    }

    /// Returns true iff `value` is a non-empty string consisting entirely of
    /// decimal digits `[0-9]`. Empty strings, whitespace-only strings, and any
    /// string containing non-digit characters return false. Leading zeros are
    /// allowed because Optimizely IDs are opaque identifiers (see spec).
    ///
    /// Used only for `variation_id` validation per spec FR-003 — `variation_id`
    /// retains the stricter numeric-string-only contract even after the
    /// 2026-06-24 spec relaxation. `campaign_id` and `entity_id` use
    /// `isNonEmptyString(_:)` instead.
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
