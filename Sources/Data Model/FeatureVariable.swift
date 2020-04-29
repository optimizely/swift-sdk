/****************************************************************************
* Copyright 2019-2020, Optimizely, Inc. and contributors                   *
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

struct FeatureVariable: Codable, Equatable {
    var id: String
    var key: String
    var type: String
    var subType: String?
    // datafile schema requires this, but test has "null" value case. keep optional for FSC
    var defaultValue: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case key
        case type
        case subType
        case defaultValue
    }
    
    init(id: String, key: String, type: String, subType: String?, defaultValue: String?) {
        self.id = id
        self.key = key
        self.type = type
        self.subType = subType
        self.defaultValue = defaultValue
        overrideTypeIfJSON()
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        type = try container.decode(String.self, forKey: .type)
        subType = try container.decodeIfPresent(String.self, forKey: .subType)
        defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
        overrideTypeIfJSON()
    }
    
    mutating func overrideTypeIfJSON() {
        if type == Constants.VariableValueType.string.rawValue && subType == Constants.VariableValueType.json.rawValue {
            type = Constants.VariableValueType.json.rawValue
        }
    }
}
