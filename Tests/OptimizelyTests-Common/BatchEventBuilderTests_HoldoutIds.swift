//
// Copyright 2026, Optimizely, Inc. and contributors
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

// Tests for decision-event id normalization:
//   campaign_id / events[].entity_id: any non-empty string; fallback to
//     experiment_id on empty / whitespace / null.
//   variation_id: decimal-digit string only; otherwise JSON null.

import XCTest

class BatchEventBuilderTests_HoldoutIds: XCTestCase {

    // MARK: - isValidStringId (relaxed contract for campaign_id / entity_id)

    func testIsValidStringId_nonEmptyContent() {
        XCTAssertTrue(BatchEventBuilder.isValidStringId("12345"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("default-12345"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("layer_abc"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("a"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("0"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("not_a_number"))
        // Non-ASCII content is accepted; no character-set restriction.
        XCTAssertTrue(BatchEventBuilder.isValidStringId("\u{0660}\u{0661}"))
    }

    func testIsValidStringId_emptyOrWhitespaceOnly() {
        XCTAssertFalse(BatchEventBuilder.isValidStringId(""))
        XCTAssertFalse(BatchEventBuilder.isValidStringId(" "))
        XCTAssertFalse(BatchEventBuilder.isValidStringId("   "))
        XCTAssertFalse(BatchEventBuilder.isValidStringId("\t"))
        XCTAssertFalse(BatchEventBuilder.isValidStringId("\n"))
        XCTAssertFalse(BatchEventBuilder.isValidStringId(" \t\n "))
    }

    // MARK: - isValidNumericIdString (strict contract for variation_id)

    func testIsValidNumericIdString_validDigits() {
        XCTAssertTrue(BatchEventBuilder.isValidNumericIdString("12345"))
        XCTAssertTrue(BatchEventBuilder.isValidNumericIdString("0"))
        // Leading zeros allowed: IDs are opaque.
        XCTAssertTrue(BatchEventBuilder.isValidNumericIdString("007"))
        XCTAssertTrue(BatchEventBuilder.isValidNumericIdString("10390977714"))
    }

    func testIsValidNumericIdString_emptyOrWhitespace() {
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString(""))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString(" "))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("   "))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("\t"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("\n"))
    }

    func testIsValidNumericIdString_nonNumeric() {
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("abc"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("12a45"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("12.45"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("-12345"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("+12345"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("12 45"))
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("1e10"))
        // Non-ASCII digit forms (e.g. Arabic-Indic) are NOT valid.
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("\u{0660}\u{0661}"))
    }

    // MARK: - normalizeDecisionIds — happy path

    func testNormalize_validCampaignAndVariation_passThrough() {
        let (campaign, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "555",
            rawVariationId: "777",
            experimentId: "999")
        XCTAssertEqual(campaign, "555")
        XCTAssertEqual(variation, "777")
    }

    func testNormalize_validCampaignAndNilVariation_variationStaysNil() {
        let (campaign, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "555",
            rawVariationId: nil,
            experimentId: "999")
        XCTAssertEqual(campaign, "555")
        XCTAssertNil(variation)
    }

    // MARK: - normalizeDecisionIds — campaign_id

    func testNormalize_emptyCampaignFallsBackToExperimentId() {
        // Canonical holdout case: layerId defaults to "".
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
    }

    func testNormalize_whitespaceOnlyCampaignFallsBackToExperimentId() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "   ",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
    }

    func testNormalize_opaqueCampaignPassesThroughUnchanged() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "default-12345",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "default-12345")
    }

    func testNormalize_nonNumericCampaignPassesThroughUnchanged() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "not_a_number",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "not_a_number")
    }

    func testNormalize_opaquePrefixedLayerIdPassesThroughUnchanged() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "layer_abc123",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "layer_abc123")
    }

    func testNormalize_validNumericCampaignKept() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "12345",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "12345")
    }

    func testNormalize_invalidExperimentIdStillPassedThrough() {
        // Never drop the event — pass the invalid fallback through.
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "",
            rawVariationId: "777",
            experimentId: "")
        XCTAssertEqual(campaign, "")
    }

    // MARK: - normalizeDecisionIds — variation_id

    func testNormalize_emptyVariationBecomesNil() {
        let (_, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "12345",
            rawVariationId: "",
            experimentId: "exp_42")
        XCTAssertNil(variation)
    }

    func testNormalize_whitespaceVariationBecomesNil() {
        let (_, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "12345",
            rawVariationId: "  ",
            experimentId: "exp_42")
        XCTAssertNil(variation)
    }

    func testNormalize_nilVariationStaysNil() {
        let (_, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "12345",
            rawVariationId: nil,
            experimentId: "exp_42")
        XCTAssertNil(variation)
    }

    func testNormalize_nonNumericVariationBecomesNil() {
        let (_, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "12345",
            rawVariationId: "abc",
            experimentId: "exp_42")
        XCTAssertNil(variation)
    }

    func testNormalize_validNumericVariationKept() {
        let (_, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "12345",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(variation, "777")
    }

    // MARK: - Decision encoder — variation_id JSON null

    func testDecisionEncoder_emitsExplicitNullForNilVariationId() throws {
        let decision = Decision(
            variationID: nil,
            campaignID: "12345",
            experimentID: "67890",
            metaData: DecisionMetadata(
                ruleType: Constants.DecisionSource.holdout.rawValue,
                ruleKey: "holdout_key",
                flagKey: "flag_1",
                variationKey: "",
                enabled: false,
                cmabUUID: nil))

        let data = try JSONEncoder().encode(decision)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]

        // JSONSerialization surfaces JSON `null` as `NSNull`. The key must be
        // present with explicit null (not omitted).
        XCTAssertTrue(json.keys.contains("variation_id"),
                      "variation_id must be present in the JSON payload")
        XCTAssertTrue(json["variation_id"] is NSNull,
                      "variation_id must serialize as explicit JSON null when nil")

        XCTAssertEqual(json["campaign_id"] as? String, "12345")
        XCTAssertEqual(json["experiment_id"] as? String, "67890")
    }

    func testDecisionEncoder_emitsStringForValidVariationId() throws {
        let decision = Decision(
            variationID: "777",
            campaignID: "12345",
            experimentID: "67890",
            metaData: DecisionMetadata(
                ruleType: Constants.DecisionSource.experiment.rawValue,
                ruleKey: "exp",
                flagKey: "flag_1",
                variationKey: "a",
                enabled: true,
                cmabUUID: nil))

        let data = try JSONEncoder().encode(decision)
        let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]

        XCTAssertEqual(json["variation_id"] as? String, "777")
        XCTAssertFalse(json["variation_id"] is NSNull)
    }

    // MARK: - Impression event entity_id

    /// End-to-end: a holdout impression event has an empty source `layerId`,
    /// so both `decisions[0].campaign_id` AND `events[0].entity_id` must fall
    /// back to the holdout's `experiment_id`, and they must be byte-equal.
    func testImpressionEvent_holdout_entityIdMirrorsNormalizedCampaignId() throws {
        let datafile = OTUtils.loadJSONDatafile("api_datafile")!
        let eventDispatcher = MockEventDispatcher()
        var optimizely: OptimizelyClient! = OptimizelyClient(sdkKey: "holdout_entity_id_test",
                                                             eventDispatcher: eventDispatcher)
        defer {
            optimizely?.close()
            optimizely = nil
        }
        try optimizely.start(datafile: datafile)

        // Holdout defaults layerId to "" — the canonical case this targets.
        let holdoutJSON: [String: Any] = [
            "status": "Running",
            "id": "holdout_4444444",
            "key": "holdout_key",
            "trafficAllocation": [
                ["entityId": "holdout_variation_a11", "endOfRange": 10000]
            ],
            "audienceIds": [],
            "variations": [
                ["variables": [], "id": "holdout_variation_a11", "key": "holdout_a"]
            ]
        ]
        let holdout: Holdout = try OTUtils.model(from: holdoutJSON)
        optimizely.config?.holdoutConfig = HoldoutConfig(globalHoldouts: [holdout], localHoldouts: [])

        let user = optimizely.createUserContext(userId: "test_user_1")
        _ = user.decide(key: "feature_1")

        let exp = expectation(description: "impression dispatched")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        guard let raw = eventDispatcher.events.first?.body,
              let event = try JSONSerialization.jsonObject(with: raw, options: .allowFragments) as? [String: Any],
              let visitor = (event["visitors"] as? [[String: Any]])?.first,
              let snapshot = (visitor["snapshots"] as? [[String: Any]])?.first,
              let decision = (snapshot["decisions"] as? [[String: Any]])?.first,
              let dispatchEvent = (snapshot["events"] as? [[String: Any]])?.first else {
            return XCTFail("impression event was not dispatched in expected shape")
        }

        let campaignId = decision["campaign_id"] as? String
        let entityId = dispatchEvent["entity_id"] as? String

        XCTAssertEqual(campaignId, holdout.id,
                       "campaign_id must fall back to holdout.id when layerId is empty")
        XCTAssertEqual(entityId, holdout.id,
                       "entity_id must fall back to holdout.id when layerId is empty")
        // entity_id mirrors normalized campaign_id; they must never diverge.
        XCTAssertEqual(campaignId, entityId,
                       "campaign_id and entity_id must hold the same normalized value")
    }

    /// Opaque non-numeric source passes through normalization unchanged.
    /// entity_id is assigned from the normalized campaign_id in
    /// createImpressionEvent, so proving campaign_id passthrough also proves
    /// entity_id passthrough on the wire.
    func testNormalize_opaqueLayerIdPassesThroughForBothCampaignAndEntity() {
        let opaqueLayerId = "layer_abc123"
        let (campaignId, variationId) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: opaqueLayerId,
            rawVariationId: "777",
            experimentId: "exp_999")
        XCTAssertEqual(campaignId, opaqueLayerId,
                       "opaque layerId must pass through to campaign_id unchanged")
        XCTAssertEqual(variationId, "777",
                       "valid numeric variation_id must pass through unchanged")
    }
}
