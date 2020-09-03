//
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

/// A struct for user contexts that the SDK will use to make decisions for.
///
/// If the userId parameter is nil, a random user-id will be created in the SDK (UUID).
/// The created value will be saved to be used as a deterministic user-id.
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
    
    /// Set an attribute for a given key.
    /// - Parameters:
    ///   - key: An attribute key
    ///   - value: An attribute value
    public mutating func setAttribute(key: String, value: Any) {
        attributes[key] = value
    }
    
    /// Set the default decide-options which are commonly applied to all following decide API calls.
    ///
    /// These options will be overridden when each decide-API call provides own options.
    ///
    /// - Parameter options: An array of default decision options.
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
