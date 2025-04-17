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
    private(set) var flagHoldoutsMap: [String: [Holdout]] = [:]
    private(set) var includedHoldouts: [String: [Holdout]] = [:]
    private(set) var excludedHoldouts: [String: [Holdout]] = [:]
    
    init(allholdouts: [Holdout] = []) {
        self.allHoldouts = allholdouts
        updateHoldoutMapping()
    }
    
    /// Updates internal mappings of holdouts including the id map, global list, and per-flag inclusion/exclusion maps.
    mutating func updateHoldoutMapping() {
        holdoutIdMap = {
            var map = [String: Holdout]()
            allHoldouts.forEach { map[$0.id] = $0 }
            return map
        }()
        
        flagHoldoutsMap = [:]
        global = []
        includedHoldouts = [:]
        excludedHoldouts = [:]
        
        for holdout in allHoldouts {
            switch (holdout.includedFlags.isEmpty, holdout.excludedFlags.isEmpty) {
                case (true, true):
                    global.append(holdout)
                    
                case (false, _):
                    holdout.includedFlags.forEach { flagId in
                        if var existing = includedHoldouts[flagId] {
                            existing.append(holdout)
                            includedHoldouts[flagId] = existing
                        } else {
                            includedHoldouts[flagId] = [holdout]
                        }
                    }
                    
                case (true, false):
                    global.append(holdout)
                    
                    holdout.excludedFlags.forEach { flagId in
                        if var existing = excludedHoldouts[flagId] {
                            existing.append(holdout)
                            excludedHoldouts[flagId] = existing
                        } else {
                            excludedHoldouts[flagId] = [holdout]
                        }
                    }
            }
        }
    }
    
    /// Returns the applicable holdouts for the given flag ID by combining global holdouts (excluding any specified) and included holdouts, in that order.
    /// Caches the result for future calls.
    /// - Parameter id: The flag identifier.
    /// - Returns: An array of `Holdout` objects relevant to the given flag.
    mutating func getHoldoutForFlag(id: String) -> [Holdout] {
        guard !allHoldouts.isEmpty else { return [] }
        
        // Check cache and return persistent holdouts
        if let holdouts = flagHoldoutsMap[id] {
            return holdouts
        }
        
        // Prioritize global holdouts first 
        var activeHoldouts: [Holdout] = []
        
        let excluded = excludedHoldouts[id] ?? []
        
        if !excluded.isEmpty {
            activeHoldouts = global.filter { holdout in
                return !excluded.contains(holdout)
            }
        } else {
            activeHoldouts = global
        }
        
        let includedHoldouts = includedHoldouts[id] ?? []
        
        activeHoldouts += includedHoldouts
        
        flagHoldoutsMap[id] = activeHoldouts
        
        return flagHoldoutsMap[id] ?? []
    }
    
    /// Get a Holdout object for an Id.
    func getHoldout(id: String) -> Holdout? {
        return holdoutIdMap[id]
    }
}

