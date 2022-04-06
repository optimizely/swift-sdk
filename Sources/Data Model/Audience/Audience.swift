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

struct Audience: Codable, Equatable, OptimizelyAudience {
    var id: String
    var name: String
    var conditionHolder: ConditionHolder
    var conditions: String   // string representation for OptimizelyConfig

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case conditions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        let hint = "id: \(self.id), name: \(self.name)"
        let decodeError = DecodingError.dataCorrupted(
            DecodingError.Context(codingPath: container.codingPath,
                                  debugDescription: "Failed to decode Audience Condition (\(hint))"))
        
        if let value = try? container.decode(String.self, forKey: .conditions) {
            // legacy stringified conditions
            // - "[\"or\",{\"value\":30,\"type\":\"custom_attribute\",\"match\":\"exact\",\"name\":\"geo\"}]"
            // decode it to recover to formatted CondtionHolder type
            
            guard let data = value.data(using: .utf8) else { throw decodeError }
                
            self.conditionHolder = try JSONDecoder().decode(ConditionHolder.self, from: data)
            self.conditions = value
        } else if let value = try? container.decode(ConditionHolder.self, forKey: .conditions) {
            self.conditionHolder = value
            
            // sort by keys to compare strings in tests
            let sortEncoder = JSONEncoder()
            if #available(iOS 11.0, tvOS 11.0, watchOS 4.0, *) {
                sortEncoder.outputFormatting = .sortedKeys
            }
            let data = try sortEncoder.encode(value)
            self.conditions = String(bytes: data, encoding: .utf8) ?? ""
        } else {
            throw decodeError
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(conditionHolder, forKey: .conditions)
    }
    
    func evaluate(project: ProjectProtocol?, user: OptimizelyUserContext) throws -> Bool {
        return try conditionHolder.evaluate(project: project, user: user)
    }

}
