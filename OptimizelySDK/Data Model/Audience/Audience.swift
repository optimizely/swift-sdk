/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import Foundation

struct Audience: Codable, Equatable {
    var id: String
    var name: String
    var conditions: ConditionHolder
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case conditions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        if let value = try? container.decode(String.self, forKey: .conditions) {
            
            // legacy stringified conditions
            // - "[\"or\",{\"value\":30,\"type\":\"custom_attribute\",\"match\":\"exact\",\"name\":\"geo\"}]"
            // decode it to recover to formatted CondtionHolder type
            
            let data = value.data(using: .utf8)
            self.conditions = try JSONDecoder().decode(ConditionHolder.self, from: data!)
            
        } else if let value = try? container.decode(ConditionHolder.self, forKey: .conditions) {

            // typedAudience formats
            // [TODO] Tom: check if this is correct
            // NOTE: UserAttribute (not in array) at the top-level is allowed

            self.conditions = value

        } else {
            let hint = "id: \(self.id), name: \(self.name)"
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "Failed to decode Audience Condition (\(hint))"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(conditions, forKey: .conditions)
    }
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) throws -> Bool {
        return try conditions.evaluate(project: project, attributes: attributes)
    }
}
