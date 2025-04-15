//
// Copyright 2022, Optimizely, Inc. and contributors 
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
            updateHoldoutProperties()
        }
    }
    private(set) var holdoutIdMap: [String: Holdout] = [:]
    private(set) var global: [Holdout] = []
    private(set) var others: [Holdout] = []
    private(set) var includedHoldouts: [String: [Holdout]] = [:]
    private(set) var excludedHoldouts: [String: [Holdout]] = [:]
    private(set) var flagHoldoutsMap: [String: [Holdout]] = [:]
    
    init(allholdouts: [Holdout] = []) {
        self.allHoldouts = allholdouts
        updateHoldoutProperties()
    }
    
    mutating func updateHoldoutProperties() {
        holdoutIdMap = {
            var map = [String: Holdout]()
            allHoldouts.forEach { map[$0.id] = $0 }
            return map
        }()
        flagHoldoutsMap = [:]
        global = []
        others = []
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
                case (_, false):
                    others.append(holdout)
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
    
    mutating func getHoldoutForFlag(id: String) -> [Holdout] {
        guard !allHoldouts.isEmpty else { return [] }
        
        if let holdouts = flagHoldoutsMap[id] {
            return holdouts
        }
        
        if let included = includedHoldouts[id], !included.isEmpty {
            flagHoldoutsMap[id] = global + included
        } else {
            let excluded = excludedHoldouts[id] ?? []
            let filteredHoldouts = others.filter { holdout in
                return !excluded.contains(holdout)
            }
            flagHoldoutsMap[id] = global + filteredHoldouts
        }
        return flagHoldoutsMap[id] ?? []
    }
    
    func getHoldout(id: String) -> Holdout? {
        return holdoutIdMap[id]
    }
}

