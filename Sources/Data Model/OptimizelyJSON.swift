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

class OptimizelyJSON {
    
    private typealias schemaHandler = (Any) throws -> Void
    private var payload: String?
    private var data: [String: Any]?
    
    // MARK: - Init
    
    init(payload: String) throws {
        do {
            guard let data = payload.data(using: .utf8),
                let jsonData = try JSONSerialization.jsonObject(with: data, options : .allowFragments) as? [String: Any] else
            {
                throw OptimizelyError.invalidJSONString
            }
            self.data = jsonData
            self.payload = payload
        } catch {
            throw OptimizelyError.failedToConvertStringToDictionary
        }
    }
    
    init(data: [String: Any]) {
        self.data = data
    }
    
    private init() {}
    
    // MARK: - OptimizelyJSON Implementation
    
    /// - Returns:  the string representation of json
    /// - Throws: `OptimizelyError`
    func toString() throws -> String {
        guard let payload = self.payload else {
            guard let data = self.data, JSONSerialization.isValidJSONObject(data) else {
                throw OptimizelyError.invalidJSONDictionary
            }
            guard let jsonData = try? JSONSerialization.data(
                withJSONObject: data,
                options: .prettyPrinted
                ),
                let jsonString = String(data: jsonData,
                                        encoding: String.Encoding.ascii) else {
                                            throw OptimizelyError.failedToConvertJSONToString
            }
            self.payload = jsonString
            return jsonString
        }
        return payload
    }
    
    /// - Returns:  the json dictionary
    /// - Throws: `OptimizelyError`
    func toMap() throws -> [String: Any] {
        guard let data = self.data else {
            throw OptimizelyError.invalidJSONDictionary
        }
        return data
    }
    
    /// populates the decodable schema passed by the user
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    ///   - decodableSchema: Schema to decode into.
    /// - Throws: `OptimizelyError`
    func getValue<T: Decodable>(jsonPath: String, decodableSchema: inout T) throws {
        func populateDecodableSchema(value: Any) throws {
            guard JSONSerialization.isValidJSONObject(value) else {
                throw OptimizelyError.invalidJSONDictionary
            }
            do {
                let jsonData = try JSONSerialization.data(
                    withJSONObject: value,
                    options: .prettyPrinted
                )
                decodableSchema = try JSONDecoder().decode(T.self, from: jsonData)
            } catch {
                throw OptimizelyError.failedToAssignValueToSchema
            }
        }
        try findValue(jsonPath: jsonPath, schemaHandler: populateDecodableSchema(value:))
    }
    
    /// populates the schema passed by the user
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    ///   - decodableSchema: Schema to decode into.
    /// - Throws: `OptimizelyError`
    func getValue<T>(jsonPath: String, schema: inout T) throws {
        func populateSchema(value: Any) throws {
            if let v = value as? T {
                schema = v
                return
            }
            throw OptimizelyError.failedToAssignValueToSchema
        }
        try findValue(jsonPath: jsonPath, schemaHandler: populateSchema(value:))
    }
    
    private func findValue(jsonPath: String, schemaHandler: schemaHandler) throws {
        let pathArray = jsonPath.components(separatedBy: ".")
        if pathArray.count == 0 {
            // Populate the whole schema
            guard let data = self.data, JSONSerialization.isValidJSONObject(data) else {
                throw OptimizelyError.invalidJSONDictionary
            }
            try schemaHandler(data)
            return
        }
        
        let lastIndex = pathArray.count - 1
        guard let data = self.data else {
            throw OptimizelyError.invalidJSONDictionary
        }
        
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
