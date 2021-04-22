//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

/// Implementation of OPTDataStore as a generic for per type storeage in a flat file.
/// This class should be used as a singleton per storeName and type (T)
open class DataStoreFile<T>: OPTDataStore where T: Codable {
    let dataStoreName: String
    let lock: DispatchQueue
    let async: Bool
    public let url: URL
    lazy var logger: OPTLogger? = OPTLoggerFactory.getLogger()
    
    public init(storeName: String, async: Bool = true) {
        self.async = async
        dataStoreName = storeName
        lock = DispatchQueue(label: storeName)
        #if os(tvOS) || os(macOS)
        let directory = FileManager.SearchPathDirectory.cachesDirectory
        #else
        let directory = FileManager.SearchPathDirectory.documentDirectory
        #endif
        if let url = FileManager.default.urls(for: directory, in: .userDomainMask).first {
            self.url = url.appendingPathComponent(storeName, isDirectory: false)
        } else {
            self.url = URL(fileURLWithPath: storeName)
        }
    }
    
    func isArray() -> Bool {
        let t = "\(type(of: T.self))"
        return t.hasPrefix("Array") || t.hasPrefix("Swift.Array") || t.hasPrefix("__C.NSArray") || t.hasPrefix("NSArray")
    }
    public func getItem(forKey: String) -> Any? {
        var returnItem: T?
        
        lock.sync {
            do {
                
                if !FileManager.default.fileExists(atPath: self.url.path) {
                    return
                }
                
                let contents = try self.readData()

                if type(of: T.self) == type(of: Data.self) {
                    returnItem = contents as? T
                } else {
                    if isArray() {
                        let item = try JSONDecoder().decode(T.self, from: contents)
                        returnItem = item
                    } else {
                        let item = try JSONDecoder().decode([T].self, from: contents)
                        returnItem = item.first
                    }
                }
            } catch let e as NSError {
                if e.code != 260 {
                    self.logger?.e(e.localizedDescription)
                }
            }
        }
        
        return returnItem
    }
    
    func doCall(async: Bool, block:@escaping () -> Void) {
        if async {
            lock.async {
                block()
            }
        } else {
            lock.sync {
                block()
            }
        }
    }
    
    public func saveItem(forKey: String, value: Any) {
        doCall(async: self.async) {
            do {
                if let value = value as? T {
                    var data: Data?
                    
                    // don't bother to convert... otherwise, do
                    if let value = value as? Data {
                        data = value
                    } else if (value as? NSArray) != nil {
                        data = try JSONEncoder().encode(value)
                    } else {
                        data = try JSONEncoder().encode([value])
                    }
                    
                    if let data = data {
                        try self.writeData(data)
                    }
                }
            } catch let e {
                self.logger?.e(e.localizedDescription)
            }
        }
    }
    
    public func removeItem(forKey: String) {
        doCall(async: self.async) {
            do {
                try FileManager.default.removeItem(at: self.url)
            } catch let e {
                self.logger?.e(e.localizedDescription)
            }
        }

    }

    // Read Data contents from the URL
    open func readData() throws -> Data {
        return try Data(contentsOf: self.url)
    }

    // Write Data to the URL
    open func writeData(_ data: Data) throws {
        try data.write(to: self.url, options: .atomic)
    }
}
