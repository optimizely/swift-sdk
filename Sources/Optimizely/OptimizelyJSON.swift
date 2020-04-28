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

public class OptimizelyJSON: NSObject {
    
    private lazy var logger = OPTLoggerFactory.getLogger()
    private typealias SchemaHandler<T> = (Any) -> T?
    var payload: String?
    var map = [String: Any]()
    
    // MARK: - Init
    
    init?(payload: String) {
        do {
            guard let data = payload.data(using: .utf8),
                let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                    return nil
            }
            self.map = dict
            self.payload = payload
        } catch {
            return nil
        }
    }
    
    init?(map: [String: Any]) {
        if !JSONSerialization.isValidJSONObject(map) {
            return nil
        }
        self.map = map
    }
    
    // MARK: - OptimizelyJSON Implementation
    
    /// - Returns: The string representation of json
    public func toString() -> String? {
        guard let payload = self.payload else {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: map,
                                                             options: []),
                let jsonString = String(data: jsonData, encoding: .utf8) else {
                    logger.e(.failedToConvertMapToString)
                    return nil
            }
            self.payload = jsonString
            return jsonString
        }
        return payload
    }
    
    /// - Returns: The json dictionary
    public func toMap() -> [String: Any] {
        return map
    }
    
    /// Returns decoded value for jsonPath
    ///
    /// If JSON Data is {"k1":true, "k2":{"k3":"v2"}}
    ///
    /// Set jsonPath to "k1" to access the true boolean value or set it to to "k2.k3" to access {"k3":"v2"}.
    /// Set it to nil or empty to access the entire JSON data.
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    /// - Returns: Value if decoded successfully
    public func getValue<T: Decodable>(jsonPath: String? = nil) -> T? {
        func populateDecodableSchema(value: Any) -> T? {
            guard JSONSerialization.isValidJSONObject(value) else {
                // Try and assign value directly to schema
                if let v = value as? T {
                    return v
                }
                logger.e(.failedToAssignValueToSchema)
                return nil
            }
            // Try to decode value into schema
            guard let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []),
                let decodedValue = try? JSONDecoder().decode(T.self, from: jsonData) else {
                    logger.e(.failedToAssignValueToSchema)
                    return nil
            }
            return decodedValue
        }
        return getValue(jsonPath: jsonPath, schemaHandler: populateDecodableSchema(value:))
    }
    
    /// Returns parsed value for jsonPath
    ///
    /// If JSON Data is {"k1":true, "k2":{"k3":"v2"}}
    ///
    /// Set jsonPath to "k1" to access the true boolean value or set it to to "k2.k3" to access {"k3":"v2"}.
    /// Set it to nil or empty to access the entire JSON data.
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    /// - Returns: Value if parsed successfully
    public func getValue<T>(jsonPath: String?) -> T? {
        func populateSchema(value: Any) -> T? {
            guard let v = value as? T else {
                self.logger.e(.failedToAssignValueToSchema)
                return nil
            }
            return v
        }
        return getValue(jsonPath: jsonPath, schemaHandler: populateSchema(value:))
    }
    
    private func getValue<T>(jsonPath: String?, schemaHandler: SchemaHandler<T>) -> T? {
        
        guard let path = jsonPath, !path.isEmpty else {
            // Populate the whole schema
            return schemaHandler(map)
        }
        
        let pathArray = path.components(separatedBy: ".")
        let lastIndex = pathArray.count - 1
        
        var internalMap = map
        for (index, key) in pathArray.enumerated() {
            guard let value = internalMap[key] else {
                self.logger.e(.valueForKeyNotFound(key))
                return nil
            }
            if let dict = value as? [String: Any] {
                internalMap = dict
            }
            if index == lastIndex {
                return schemaHandler(value)
            }
        }
        return nil
    }
}
