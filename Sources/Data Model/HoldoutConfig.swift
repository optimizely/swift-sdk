//
// Copyright 2025, Optimizely, Inc. and contributors
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

struct HoldoutConfig {
    var allHoldouts: [Holdout] {
        didSet {
            updateHoldoutMapping()
        }
    }
    private(set) var global: [Holdout] = []
    private(set) var holdoutIdMap: [String: Holdout] = [:]
    private(set) var ruleHoldoutsMap: [String: [Holdout]] = [:]
    
    init(allholdouts: [Holdout] = []) {
        self.allHoldouts = allholdouts
        updateHoldoutMapping()
    }
    
    /// Updates internal mappings of holdouts including the id map, global list, and per-rule maps.
    mutating func updateHoldoutMapping() {
        holdoutIdMap = {
            var map = [String: Holdout]()
            allHoldouts.forEach { map[$0.id] = $0 }
            return map
        }()

        global = []
        ruleHoldoutsMap = [:]

        for holdout in allHoldouts {
            if holdout.isGlobal {
                // includedRules == nil → global holdout
                global.append(holdout)
            } else {
                // includedRules == [ruleId, ...] → local holdout
                for ruleId in holdout.includedRules! {
                    ruleHoldoutsMap[ruleId, default: []].append(holdout)
                }
            }
        }
    }
    
    /// Returns local holdouts targeting a specific rule.
    /// - Parameter ruleId: The rule identifier.
    /// - Returns: An array of `Holdout` objects targeting the given rule.
    func getHoldoutsForRule(ruleId: String) -> [Holdout] {
        return ruleHoldoutsMap[ruleId] ?? []
    }

    /// Returns all global holdouts.
    /// - Returns: An array of global `Holdout` objects.
    func getGlobalHoldouts() -> [Holdout] {
        return global
    }
    
    /// Get a Holdout object for an Id.
    func getHoldout(id: String) -> Holdout? {
        return holdoutIdMap[id]
    }
}
