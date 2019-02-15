/****************************************************************************
 * Copyright 2018, Optimizely, Inc. and contributors                        *
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

public class Audience : Codable {
    var id:String = ""
    var name:String = ""
    var conditions:ConditionHolder?
    
    enum codingKeys : String, CodingKey {
        case id
        case name
        case conditions
    }
    
    init() {
        
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try? decoder.container(keyedBy: codingKeys.self)
        
        if let value = try container?.decode(String.self, forKey: .id) {
            id = value
        }
        if let value = try container?.decode(String.self, forKey: .name) {
            name = value
        }
        if let value = try? container?.decode(String.self, forKey: .conditions) {
            let data = value?.data(using: .utf8)
            if let holders = try? JSONDecoder().decode(ConditionHolder.self, from: data!) {
                conditions = holders
            }
            
        }
        else if let value = try? container?.nestedUnkeyedContainer(forKey: .conditions) {
            guard var value = value else { return }
            var conditionList = [ConditionHolder]()
            while !value.isAtEnd {
                if let condition = try? value.decode(ConditionHolder.self) {
                    conditionList.append(condition)
                }
            }
            conditions = ConditionHolder.array(conditionList)
        }
        
    }
    
    public func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: codingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(conditions, forKey: .conditions)
    }

}
