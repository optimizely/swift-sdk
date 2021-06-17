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

struct Variation: Codable, OptimizelyVariation {
    var id: String
    var key: String
    var featureEnabled: Bool?
    var variables: [Variable]?

    enum CodingKeys: String, CodingKey {
        case id, key, featureEnabled, variables
    }

    // MARK: - OptimizelyConfig

    var variablesMap: [String: OptimizelyVariable] = [:]
}

extension Variation: Equatable {
    static func == (lhs: Variation, rhs: Variation) -> Bool {
        return lhs.id == rhs.id &&
            lhs.key == rhs.key &&
            lhs.featureEnabled == rhs.featureEnabled &&
            lhs.variables == rhs.variables
    }
}

// MARK: - Utils

extension Variation {
    func getVariable(id: String) -> Variable? {
        return variables?.filter { $0.id == id }.first
    }
}
