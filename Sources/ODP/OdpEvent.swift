//
// Copyright 2022-2023, Optimizely, Inc. and contributors 
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

public struct OdpEvent: Codable {
    let type: String
    let action: String
    let identifiers: [String: String]
    
    // [String: Any?] is not Codable. Serialize it before storing and then deserialize when reading back.
    let data: [String: Any?]
    let dataSerial: Data
    
    public init(type: String, action: String, identifiers: [String: String], data: [String: Any?]) {
        self.type = type
        self.action = action
        self.identifiers = identifiers
        self.data = data
        
        // serialize for DataStoreQueueStackImpl store (Codable required)
        self.dataSerial = (try? JSONSerialization.data(withJSONObject: data)) ?? Data()
    }
    
    // for JSON encoding (storing) and decoding (reading back from store)
    
    enum CodingKeys: String, CodingKey {
        case type
        case action
        case identifiers
        case dataSerial
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        self.type = try values.decode(String.self, forKey: .type)
        self.action = try values.decode(String.self, forKey: .action)
        self.identifiers = try values.decode([String: String].self, forKey: .identifiers)
        self.dataSerial = try values.decode(Data.self, forKey: .dataSerial)
        
        self.data = (try? JSONSerialization.jsonObject(with: dataSerial, options: []) as? [String: Any]) ?? [:]
    }
    
    // For JSON encoding (POST request body)
    
    public var dict: [String: Any] {
        return [
            "type": type,
            "action": action,
            "identifiers": identifiers,
            "data": data
        ]
    }

}

extension OdpEvent: Equatable {
    
    public static func == (lhs: OdpEvent, rhs: OdpEvent) -> Bool {
        return lhs.type == rhs.type &&
            lhs.action == rhs.action &&
            lhs.identifiers == rhs.identifiers &&
            lhs.dataSerial == rhs.dataSerial
    }
    
}
