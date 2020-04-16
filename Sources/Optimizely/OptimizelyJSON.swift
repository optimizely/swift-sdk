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
    
    private typealias schemaHandler = (Any) throws -> Void
    private var payload: String?
    private var data = [String: Any]()
    
    // MARK: - Init
    
    @objc init(payload: String) throws {
        do {
            guard let data = payload.data(using: .utf8),
                let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] else
            {
                throw OptimizelyError.failedToConvertStringToDictionary
            }
            self.data = jsonData
            self.payload = payload
        } catch {
            throw OptimizelyError.failedToConvertStringToDictionary
        }
    }
    
    @objc init(data: [String: Any]) throws {
        if !JSONSerialization.isValidJSONObject(data) {
            throw OptimizelyError.invalidDictionary
        }
        self.data = data
    }
    
    // MARK: - OptimizelyJSON Implementation
    
    /// - Returns: The string representation of json
    /// - Throws: `OptimizelyError`
    @objc public func toString() throws -> String {
        guard let payload = self.payload else {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: data,
                                                             options: []),
                let jsonString = String(data: jsonData,
                                        encoding: .utf8) else {
                                            throw OptimizelyError.failedToConvertDictionaryToString
            }
            self.payload = jsonString
            return jsonString
        }
        return payload
    }
    
    /// - Returns: The json dictionary
    /// - Throws: `OptimizelyError`
    @objc public func toMap() throws -> [String: Any] {
        return data
    }
    
    /// Populates the decodable schema passed by the user
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    ///   - schema: Decodable schema to populate.
    /// - Throws: `OptimizelyError`
    public func getValue<T: Decodable>(jsonPath: String, schema: UnsafeMutablePointer<T>) throws {
        func populateDecodableSchema(value: Any) throws {
            guard JSONSerialization.isValidJSONObject(value) else {
                // Try and assign value directly to schema
                if let v = value as? T {
                    schema.pointee = v
                    return
                }
                throw OptimizelyError.failedToAssignValueToSchema
            }
            // Try to decode value into schema
            if let jsonData = try? JSONSerialization.data(
                withJSONObject: value,
                options: []
                ),
                let decodedValue = try? JSONDecoder().decode(T.self, from: jsonData)
            {
                schema.pointee = decodedValue
                return
            }
            throw OptimizelyError.failedToAssignValueToSchema
        }
        try getValue(jsonPath: jsonPath, schemaHandler: populateDecodableSchema(value:))
    }
    
    /// Populates the schema passed by the user
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    ///   - schema: Schema to populate.
    /// - Throws: `OptimizelyError`
    public func getValue<T>(jsonPath: String, schema: UnsafeMutablePointer<T>) throws {
        func populateSchema(value: Any) throws {
            guard let v = value as? T else {
                throw OptimizelyError.failedToAssignValueToSchema
            }
            schema.pointee = v
        }
        try getValue(jsonPath: jsonPath, schemaHandler: populateSchema(value:))
    }
    
    private func getValue(jsonPath: String, schemaHandler: schemaHandler) throws {
        
        if jsonPath == "" {
            // Populate the whole schema
            try schemaHandler(data)
            return
        }
        
        let pathArray = jsonPath.components(separatedBy: ".")
        let lastIndex = pathArray.count - 1
        
        var internalMap = data
        for (index,key) in pathArray.enumerated() {
            guard let value = internalMap[key] else {
                throw OptimizelyError.valueForKeyNotFound(key)
            }
            if let dict = value as? [String:Any] {
                internalMap = dict
            }
            if index == lastIndex {
                try schemaHandler(value)
            }
        }
    }
}
