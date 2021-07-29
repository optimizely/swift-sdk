/****************************************************************************
* Copyright 2020-2021, Optimizely, Inc. and contributors                   *
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
    
    private let logger = OPTLoggerFactory.getLogger()
    private typealias ValueHandler<T> = (Any) -> T?
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
    
    static func createEmpty() -> OptimizelyJSON {
        return OptimizelyJSON(map: [:])!
    }
    
    public var isEmpty: Bool {
        return map.isEmpty
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
    /// If JSON Data is {"k1":true, "k2":{"k3":"v3"}}
    ///
    /// Set jsonPath to "k2" to access {"k3":"v3"} or set it to "k2.k3" to access "v3".
    /// Set it to nil or empty to access the entire JSON data. See more examples below:
    ///
    ///
    ///     struct Student: Decodable {
    ///         let name: String
    ///         let age: Int
    ///         let address: Address
    ///     }
    ///
    ///     struct Address: Decodable {
    ///         let state: String
    ///         let emails: [String]
    ///     }
    ///
    ///     let student: Student? = optimizelyJSON.getValue(jsonPath: nil)
    ///     let address: Address? = optimizelyJSON.getValue(jsonPath: "address")
    ///     let name: String? = optimizelyJSON.getValue(jsonPath: "name")
    ///     let emails: [String]? = optimizelyJSON.getValue(jsonPath: "address.emails")
    ///
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    /// - Returns: Value if decoded successfully
    public func getValue<T: Decodable>(jsonPath: String?) -> T? {
        func handler(value: Any) -> T? {
            guard JSONSerialization.isValidJSONObject(value) else {
                // Try and typecast value to required return type
                if let v = value as? T {
                    return v
                }
                logger.e(.failedToAssignValue)
                return nil
            }
            // Try to decode value into return type
            guard let jsonData = try? JSONSerialization.data(withJSONObject: value, options: []),
                let decodedValue = try? JSONDecoder().decode(T.self, from: jsonData) else {
                    logger.e(.failedToAssignValue)
                    return nil
            }
            return decodedValue
        }
        return getValue(jsonPath: jsonPath, valueHandler: handler(value:))
    }
    
    /// Returns parsed value for jsonPath
    ///
    /// If JSON Data is {"k1":true, "k2":{"k3":"v3"}}
    ///
    /// Set jsonPath to "k2" to access {"k3":"v3"} or set it to "k2.k3" to access "v3".
    /// Set it to nil or empty to access the entire JSON data. See more examples below:
    ///
    ///
    ///     struct Student: Decodable {
    ///         let name: String
    ///         let age: Int
    ///         let address: Address
    ///     }
    ///
    ///     struct Address: Decodable {
    ///         let state: String
    ///         let emails: [String]
    ///     }
    ///
    ///     let student: Student? = optimizelyJSON.getValue(jsonPath: nil)
    ///     let address: Address? = optimizelyJSON.getValue(jsonPath: "address")
    ///     let name: String? = optimizelyJSON.getValue(jsonPath: "name")
    ///     let emails: [String]? = optimizelyJSON.getValue(jsonPath: "address.emails")
    ///
    ///
    /// - Parameters:
    ///   - jsonPath: Key path for the value.
    /// - Returns: Value if parsed successfully
    public func getValue<T>(jsonPath: String?) -> T? {
        func handler(value: Any) -> T? {
            guard let v = value as? T else {
                self.logger.e(.failedToAssignValue)
                return nil
            }
            return v
        }
        return getValue(jsonPath: jsonPath, valueHandler: handler(value:))
    }
    
    private func getValue<T>(jsonPath: String?, valueHandler: ValueHandler<T>) -> T? {
        
        guard let path = jsonPath, !path.isEmpty else {
            // Retrieve value for path
            return valueHandler(map)
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
                return valueHandler(value)
            }
        }
        return nil
    }
}

extension OptimizelyJSON {
    
    // override NSObject Equatable ('==' overriding not working for NSObject)
    override public func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? OptimizelyJSON else { return false }
        return NSDictionary(dictionary: map).isEqual(to: object.toMap())
    }
    
}

extension OptimizelyJSON {
    public override var description: String {
        return "\(map)"
    }
}
