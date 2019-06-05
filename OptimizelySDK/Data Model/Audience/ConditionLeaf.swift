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

enum ConditionLeaf: Codable, Equatable {
    case audienceId(String)
    case attribute(UserAttribute)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let value = try? container.decode(String.self) {
            self = .audienceId(value)
            return
        } else if let value = try? container.decode(UserAttribute.self) {
            self = .attribute(value)
            return
        }
        
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to decode ConditionLeaf"))
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .audienceId(let id):
            try container.encode(id)
        case .attribute(let userAttribute):
            try container.encode(userAttribute)
        }
    }
    
    func evaluate(project: ProjectProtocol?, attributes: OptimizelyAttributes?) throws -> Bool {
        switch self {
        case .audienceId(let id):
            guard let project = project else {
                throw OptimizelyError.conditionCannotBeEvaluated("audienceId: \(id)")
            }
            
            return try project.evaluateAudience(audienceId: id, attributes: attributes)
        case .attribute(let userAttribute):
            return try userAttribute.evaluate(attributes: attributes)
        }
    }
    
}
