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

// Tests for FSSDK-12813: every decision event (experiment, feature test,
// rollout, or holdout) must carry a valid numeric `campaign_id` (falling back
// to `experiment_id` if invalid) and either a valid numeric `variation_id` or
// JSON `null`. The normalization is uniform across decision types per FR-005.

import XCTest

class BatchEventBuilderTests_HoldoutIds: XCTestCase {

    // MARK: - isValidNumericIdString

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
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
    }

    func testNormalize_whitespaceCampaignFallsBackToExperimentId() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "   ",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
    }

    func testNormalize_nonNumericCampaignFallsBackToExperimentId() {
        let (campaign, _) = BatchEventBuilder.normalizeDecisionIds(
            rawCampaignId: "not_a_number",
            rawVariationId: "777",
            experimentId: "exp_42")
        XCTAssertEqual(campaign, "exp_42")
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
}
