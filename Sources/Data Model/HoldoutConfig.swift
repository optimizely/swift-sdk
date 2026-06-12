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
/// FSSDK-12760: Two top-level datafile sections drive holdout scoping:
///   - `holdouts`      -> ALL entries are global (applied to every flag).
///                        Any `includedRules` field on these entries is
///                        STRIPPED at parse time; section membership alone
///                        determines scope.
///   - `localHoldouts` -> ALL entries are local (rule-scoped via
///                        `includedRules`). Entries with no/empty
///                        `includedRules` are invalid; the SDK logs an error
///                        and excludes them (no fallback to global application).
///
/// Backward compatibility: datafiles that emit only the `holdouts` section
/// continue to work — every entry is treated as global, matching pre-
/// localHoldouts behavior. The legacy `allHoldouts` setter is also preserved:
/// it partitions a flat list by `includedRules == nil` (global) vs non-nil
/// (local) and then applies the same section semantics as if the datafile
/// had been split, so existing test fixtures and code paths continue to work.
struct HoldoutConfig {
    private let logger = OPTLoggerFactory.getLogger()

    /// Combined flat view of all holdouts after applying section semantics.
    /// Setting this property partitions entries the legacy way (nil
    /// `includedRules` -> global section, non-nil -> local section) and
    /// rebuilds all maps. Reads always reflect post-parsing state:
    ///   - global-section entries have `includedRules` stripped
    ///   - invalid local entries (missing/empty `includedRules`) are excluded
    var allHoldouts: [Holdout] {
        get { return _allHoldouts }
        set { applyFlatList(newValue) }
    }

    private var _allHoldouts: [Holdout] = []

    private(set) var global: [Holdout] = []
    private(set) var holdoutIdMap: [String: Holdout] = [:]
    private(set) var ruleHoldoutsMap: [String: [Holdout]] = [:]

    // MARK: - Init

    init() {}

    /// Backward-compatible init that accepts a single flat list and partitions it
    /// the legacy way: entries with `includedRules == nil` go to the global
    /// section, entries with a non-nil list go to the local section.
    init(allholdouts: [Holdout]) {
        applyFlatList(allholdouts)
    }

    /// Section-aware init. Mirrors the datafile layout: callers pass the
    /// `holdouts` section and the `localHoldouts` section separately.
    init(globalHoldouts: [Holdout], localHoldouts: [Holdout]) {
        applySections(globalHoldouts: globalHoldouts, localHoldouts: localHoldouts)
    }

    // MARK: - Section application

    /// Legacy path — partitions a flat list by `includedRules` and rebuilds maps.
    private mutating func applyFlatList(_ holdouts: [Holdout]) {
        var globals: [Holdout] = []
        var locals: [Holdout] = []
        for h in holdouts {
            if h.includedRules == nil {
                globals.append(h)
            } else {
                locals.append(h)
            }
        }
        applySections(globalHoldouts: globals, localHoldouts: locals)
    }

    /// Section-based path — applies the canonical FSSDK-12760 semantics:
    ///   - Global section entries: `includedRules` is STRIPPED (set to nil).
    ///     Section membership alone determines global scope; any stray
    ///     `includedRules` field must not narrow the entry's application.
    ///   - Local section entries: must carry a non-nil, non-empty
    ///     `includedRules` list. Invalid entries are logged and excluded
    ///     from every map; they do NOT fall back to global application.
    private mutating func applySections(globalHoldouts: [Holdout], localHoldouts: [Holdout]) {
        var newAll: [Holdout] = []
        var newIdMap: [String: Holdout] = [:]
        var newGlobal: [Holdout] = []
        var newRuleMap: [String: [Holdout]] = [:]

        // Global section: strip `includedRules` so the entity is unambiguously
        // global (isGlobal == true), even if the datafile (or caller) included
        // the field by mistake.
        for var holdout in globalHoldouts {
            holdout.includedRules = nil
            newAll.append(holdout)
            newIdMap[holdout.id] = holdout
            newGlobal.append(holdout)
        }

        // Local section: every entry must carry a non-empty `includedRules`
        // list. Invalid entries are logged and excluded.
        for holdout in localHoldouts {
            guard let rules = holdout.includedRules, !rules.isEmpty else {
                logger.e(
                    "Local holdout '\(holdout.key)' (id: \(holdout.id)) is missing or has empty 'includedRules'; skipping."
                )
                continue
            }
            newAll.append(holdout)
            newIdMap[holdout.id] = holdout
            for ruleId in rules {
                newRuleMap[ruleId, default: []].append(holdout)
            }
        }

        self._allHoldouts = newAll
        self.holdoutIdMap = newIdMap
        self.global = newGlobal
        self.ruleHoldoutsMap = newRuleMap
    }

    // MARK: - Lookups

    /// Returns local holdouts targeting a specific rule.
    /// Local holdouts come from the `localHoldouts` datafile section and are
    /// scoped per-rule via their `includedRules` field. A rule ID not present
    /// in any holdout's `includedRules` returns an empty list — silently skipped.
    /// - Parameter ruleId: The rule identifier.
    /// - Returns: An array of `Holdout` objects targeting the given rule.
    func getHoldoutsForRule(ruleId: String) -> [Holdout] {
        return ruleHoldoutsMap[ruleId] ?? []
    }

    /// Returns all global holdouts (parsed from the top-level `holdouts` section).
    /// Section membership in `holdouts` is the sole signal for global scope —
    /// any `includedRules` field on these entries is ignored at parse time.
    /// - Returns: An array of global `Holdout` objects.
    func getGlobalHoldouts() -> [Holdout] {
        return global
    }

    /// Get a Holdout object for an Id. Works for both global and local entries.
    func getHoldout(id: String) -> Holdout? {
        return holdoutIdMap[id]
    }
}
