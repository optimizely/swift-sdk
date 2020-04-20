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
    private typealias SchemaHandler = (Any) -> Bool
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
    
    /// Populates the decodable schema passed by the user
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    ///   - schema: Decodable schema to populate.
    /// - Returns: true if value decoded successfully
    public func getValue<T: Decodable>(jsonPath: String?, schema: inout T) -> Bool {
        func populateDecodableSchema(value: Any) -> Bool {
            guard JSONSerialization.isValidJSONObject(value) else {
                // Try and assign value directly to schema
                if let v = value as? T {
                    schema = v
                    return true
                }
                logger.e(.failedToAssignValueToSchema)
                return false
            }
            // Try to decode value into schema
            guard let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []),
                let decodedValue = try? JSONDecoder().decode(T.self, from: jsonData) else {
                    logger.e(.failedToAssignValueToSchema)
                    return false
            }
            schema = decodedValue
            return true
        }
        return getValue(jsonPath: jsonPath, schemaHandler: populateDecodableSchema(value:))
    }
    
    /// Populates the schema passed by the user
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    ///   - schema: Schema to populate.
    /// - Returns: true if value decoded successfully
    public func getValue<T>(jsonPath: String?, schema: inout T) -> Bool {
        func populateSchema(value: Any) -> Bool {
            guard let v = value as? T else {
                self.logger.e(.failedToAssignValueToSchema)
                return false
            }
            schema = v
            return true
        }
        return getValue(jsonPath: jsonPath, schemaHandler: populateSchema(value:))
    }
    
    private func getValue(jsonPath: String?, schemaHandler: SchemaHandler) -> Bool {
        
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
                return false
            }
            if let dict = value as? [String: Any] {
                internalMap = dict
            }
            if index == lastIndex {
                return schemaHandler(value)
            }
        }
        return false
    }
}
