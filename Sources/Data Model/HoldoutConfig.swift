//
// Copyright 2025-2026, Optimizely, Inc. and contributors
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

/// Holds parsed holdout entries and exposes per-rule and global lookups.
///
/// Two top-level datafile sections drive holdout scoping:
///   - `holdouts`      → global (applied to every flag); `includedRules` is stripped at parse time.
///   - `localHoldouts` → rule-scoped via `includedRules`; entries without rules are excluded.
struct HoldoutConfig {
    private let logger = OPTLoggerFactory.getLogger()

    private(set) var global: [Holdout] = []
    private(set) var holdoutIdMap: [String: Holdout] = [:]
    private(set) var ruleHoldoutsMap: [String: [Holdout]] = [:]

    // MARK: - Init

    init() {}

    init(globalHoldouts: [Holdout], localHoldouts: [Holdout]) {
        applySections(globalHoldouts: globalHoldouts, localHoldouts: localHoldouts)
    }

    // MARK: - Section application

    private mutating func applySections(globalHoldouts: [Holdout], localHoldouts: [Holdout]) {
        var newIdMap: [String: Holdout] = [:]
        var newGlobal: [Holdout] = []
        var newRuleMap: [String: [Holdout]] = [:]

        // Strip `includedRules` so global entries are unambiguously global.
        for var holdout in globalHoldouts {
            holdout.includedRules = nil
            newIdMap[holdout.id] = holdout
            newGlobal.append(holdout)
        }

        // Local entries must carry a non-empty `includedRules`; invalid ones are excluded.
        for holdout in localHoldouts {
            guard let rules = holdout.includedRules, !rules.isEmpty else {
                logger.e(
                    "Local holdout '\(holdout.key)' (id: \(holdout.id)) is missing or has empty 'includedRules'; skipping."
                )
                continue
            }
            newIdMap[holdout.id] = holdout
            for ruleId in rules {
                newRuleMap[ruleId, default: []].append(holdout)
            }
        }

        self.holdoutIdMap = newIdMap
        self.global = newGlobal
        self.ruleHoldoutsMap = newRuleMap
    }

    // MARK: - Lookups

    /// Returns local holdouts targeting a specific rule.
    func getHoldoutsForRule(ruleId: String) -> [Holdout] {
        return ruleHoldoutsMap[ruleId] ?? []
    }

    /// Returns all global holdouts.
    func getGlobalHoldouts() -> [Holdout] {
        return global
    }

    /// Get a Holdout object for an Id.
    func getHoldout(id: String) -> Holdout? {
        return holdoutIdMap[id]
    }
}
