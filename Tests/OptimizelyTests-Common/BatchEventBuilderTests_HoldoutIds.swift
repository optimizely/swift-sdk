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

// Tests for FSSDK-12813 (P1) + FSSDK-12834 (P2): every decision event
// (experiment, feature test, rollout, or holdout) must carry:
//   - `campaign_id` (and the mirrored `events[].entity_id`, FR-009) as any
//     non-empty string — numeric OR opaque (e.g. `"default-12345"`,
//     `"layer_abc"`). Fallback to `experiment_id` fires only on empty /
//     whitespace-only / null source values. (FR-001 / FR-002)
//   - `variation_id` as a decimal-digit string OR explicit JSON `null`.
//     Non-numeric strings normalize to null. (FR-003 / FR-004)
// The normalization is uniform across decision types per FR-005.

import XCTest

class BatchEventBuilderTests_HoldoutIds: XCTestCase {

    // MARK: - isValidStringId (FR-001: relaxed contract for campaign_id / entity_id)

    func testIsValidStringId_nonEmptyContent() {
        // Any non-empty string with at least one non-whitespace character is
        // valid — numeric, opaque, or mixed. This is the relaxed P2 contract.
        XCTAssertTrue(BatchEventBuilder.isValidStringId("12345"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("default-12345"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("layer_abc"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("a"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("0"))
        XCTAssertTrue(BatchEventBuilder.isValidStringId("not_a_number"))
        // Non-ASCII content is accepted — campaign_id has no character set
        // restriction (unlike variation_id).
        XCTAssertTrue(BatchEventBuilder.isValidStringId("\u{0660}\u{0661}"))
    }

    func testIsValidStringId_emptyOrWhitespaceOnly() {
        // Empty and whitespace-only strings are treated as invalid and
        // trigger the experiment_id fallback (FR-002).
        XCTAssertFalse(BatchEventBuilder.isValidStringId(""))
        XCTAssertFalse(BatchEventBuilder.isValidStringId(" "))
        XCTAssertFalse(BatchEventBuilder.isValidStringId("   "))
        XCTAssertFalse(BatchEventBuilder.isValidStringId("\t"))
        XCTAssertFalse(BatchEventBuilder.isValidStringId("\n"))
        XCTAssertFalse(BatchEventBuilder.isValidStringId(" \t\n "))
    }

    // MARK: - isValidNumericIdString (FR-003: stricter contract for variation_id)

    func testIsValidNumericIdString_validDigits() {
        XCTAssertTrue(BatchEventBuilder.isValidNumericIdString("12345"))
        XCTAssertTrue(BatchEventBuilder.isValidNumericIdString("0"))
        // Leading zeros are allowed because IDs are opaque.
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
        // Non-ASCII digit forms (e.g. Arabic-Indic) are NOT valid per spec.
        XCTAssertFalse(BatchEventBuilder.isValidNumericIdString("\u{0660}\u{0661}"))
    }

    // MARK: - normalizeDecisionIds — valid IDs pass through unchanged (SC-003)

    func testNormalize_validCampaignAndVariation_passThrough() {
        // The dominant production case: both IDs already valid. No change.
        let (campaign, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "555",
            rawVariationId: "777",
            experimentId: "999")
        XCTAssertEqual(campaign, "555")
        XCTAssertEqual(variation, "777")
    }

    func testNormalize_validCampaignAndNilVariation_variationStaysNil() {
        // Valid campaign, no variation supplied (e.g. holdout with no variation
        // assigned). variation_id must be JSON null, not empty string.
        let (campaign, variation) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "555",
            rawVariationId: nil,
            experimentId: "999")
        XCTAssertEqual(campaign, "555")
        XCTAssertNil(variation)
    }

    // MARK: - normalizeDecisionIds — campaign_id (FR-001/FR-002) applied uniformly

    func testNormalize_emptyCampaignFallsBackToExperimentId() {
        // FR-002: empty source value triggers the experiment_id fallback.
        // This is the canonical holdout case (layerId defaults to "").
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
    }

    func testNormalize_whitespaceOnlyCampaignFallsBackToExperimentId() {
        // FSSDK-12834: whitespace-only strings are treated as empty per the
        // defensive normalization in isValidStringId and fall back.
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "   ",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
    }

    func testNormalize_opaqueCampaignPassesThroughUnchanged() {
        // FSSDK-12834 (FR-001): an opaque non-numeric string is a valid
        // campaign_id under the relaxed P2 contract and MUST pass through
        // unchanged — no fallback to experiment_id.
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "default-12345",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "default-12345")
    }

    func testNormalize_nonNumericCampaignPassesThroughUnchanged() {
        // FSSDK-12834 (FR-001): any non-empty string passes through; only
        // empty/null source values trigger the fallback. This assertion was
        // inverted under P1 (digits-only) and is corrected here for P2.
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "not_a_number",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "not_a_number")
    }

    func testNormalize_opaquePrefixedLayerIdPassesThroughUnchanged() {
        // FSSDK-12834 (FR-001): typical opaque layerId shape like
        // "layer_abc123" must pass through unchanged.
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
        // FR-006: never drop the event; pass invalid experiment_id through if
        // that is all we have for the fallback.
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "",
            rawVariationId: "777",
            experimentId: "")
        XCTAssertEqual(campaign, "")
    }

    // MARK: - normalizeDecisionIds — variation_id (FR-003/FR-004) applied uniformly

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

        // JSONSerialization surfaces JSON `null` as `NSNull`. Verify the key is
        // PRESENT with an explicit null (not omitted by encodeIfPresent).
        XCTAssertTrue(json.keys.contains("variation_id"),
                      "variation_id must be present in the JSON payload")
        XCTAssertTrue(json["variation_id"] is NSNull,
                      "variation_id must serialize as explicit JSON null when nil")

        // Sanity-check other fields are unchanged.
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

    // MARK: - Impression event entity_id (FR-009 / SC-006)

    /// End-to-end: a holdout impression event has an empty source `layerId`,
    /// so both `decisions[0].campaign_id` AND `events[0].entity_id` must fall
    /// back to the holdout's `experiment_id`, and they must be byte-equal.
    func testImpressionEvent_holdout_entityIdMirrorsNormalizedCampaignId() throws {
        let datafile = OTUtils.loadJSONDatafile("api_datafile")!
        let eventDispatcher = MockEventDispatcher()
        var optimizely: OptimizelyClient! = OptimizelyClient(sdkKey: "fssdk_12813_entity_id",
                                                             eventDispatcher: eventDispatcher)
        defer {
            optimizely?.close()
            optimizely = nil
        }
        try optimizely.start(datafile: datafile)

        // Holdout struct defaults layerId to "" (see Holdout.swift) — the
        // canonical case this fix targets. id is the fallback used by both
        // campaign_id (FR-002) and entity_id (FR-009).
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

        // FR-002: campaign_id falls back to experiment_id (holdout.id).
        XCTAssertEqual(campaignId, holdout.id,
                       "campaign_id must fall back to holdout.id when layerId is empty")
        // FR-009: entity_id falls back the same way.
        XCTAssertEqual(entityId, holdout.id,
                       "entity_id must fall back to holdout.id when layerId is empty")
        // SC-006: the two fields share source + fallback; they must never diverge.
        XCTAssertEqual(campaignId, entityId,
                       "campaign_id and entity_id must hold the same normalized value")
    }

    /// FSSDK-12834: under the relaxed campaign_id contract, an opaque
    /// non-numeric source value (e.g. `"layer_abc123"`) passes through
    /// `normalizeDecisionIds` unchanged. Together with the existing holdout
    /// end-to-end test above (which exercises the empty-layerId fallback
    /// path), this covers both branches of FR-001 / FR-002 for
    /// `campaign_id` and, via FR-009, for `events[].entity_id`.
    func testNormalize_opaqueLayerIdPassesThroughForBothCampaignAndEntity() {
        // Production wiring (see BatchEventBuilder.createImpressionEvent):
        // events[].entity_id is assigned the same value as decisions[].campaign_id
        // AFTER normalization. Therefore proving the normalized value is the
        // opaque source is sufficient to prove entity_id is also the opaque
        // source on the wire (SC-006 invariant: the two must be byte-equal).
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
