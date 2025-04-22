//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

struct FeatureFlag: Codable, Equatable, OptimizelyFeature {
    static func == (lhs: FeatureFlag, rhs: FeatureFlag) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id: String
    var key: String
    var experimentIds: [String]
    var rolloutId: String
    var variables: [FeatureVariable]
    
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case experimentIds
        case rolloutId
        case variables
    }
    
    // MARK: - OptimizelyConfig

    var experimentsMap: [String: OptimizelyExperiment] = [:]
    var variablesMap: [String: OptimizelyVariable] = [:]
    var experimentRules: [OptimizelyExperiment] = []
    var deliveryRules: [OptimizelyExperiment] = []
}

// MARK: - Utils

extension FeatureFlag {
    func getVariable(key: String) -> FeatureVariable? {
        return variables.filter { $0.key == key }.first
    }
}
