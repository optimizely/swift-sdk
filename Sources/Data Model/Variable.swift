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

public struct Variable: Codable, Equatable {
    public var id: String
    public var value: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case value
    }
    
    // MARK: - OptimizelyConfig
    
    public var key: String = ""
    public var type: String = "string"
    
    init(id: String, value: String, key: String? = nil, type: String? = nil) {
        self.id = id
        self.value = value
        if let key = key {
            self.key = key
        }
        if let type = type {
            self.type = type
        }
    }
}
