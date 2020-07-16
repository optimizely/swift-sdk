/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

public struct OptimizelyUserContext {
    var userId: String
    var attributes: [String: Any]
    var defaultDecideOptions: [OptimizelyDecideOption]
    
    public init(userId: String?, attributes: [String: Any]? = nil) {
        var validUserId = userId
        if validUserId == nil {
            let uuidKey = "optimizely-uuid"
            var uuid = UserDefaults.standard.string(forKey: uuidKey)
            if uuid == nil {
                uuid = UUID().uuidString
                UserDefaults.standard.set(uuid, forKey: uuidKey)
            }
            validUserId = uuid
        }

        self.userId = validUserId!
        self.attributes = attributes ?? [:]
        self.defaultDecideOptions = []
    }
    
    public mutating func setAttribute(key: String, value: Any) {
        attributes[key] = value
    }
    
    public mutating func setDefaultDecideOptions(_ options: [OptimizelyDecideOption]) {
        defaultDecideOptions.append(contentsOf: options)
    }
}

extension OptimizelyUserContext: Equatable {
    
    public static func ==(lhs: OptimizelyUserContext, rhs: OptimizelyUserContext) -> Bool {
        return lhs.userId == rhs.userId &&
            (lhs.attributes as NSDictionary).isEqual(to: rhs.attributes) &&
            Set(lhs.defaultDecideOptions) == Set(rhs.defaultDecideOptions)
    }
    
}
