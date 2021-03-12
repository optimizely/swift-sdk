//
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

import XCTest

class DataStoreTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            if (!FileManager.default.fileExists(atPath: url.path)) {
                do {
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print(error)
                }
                
            }
        }

    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testMemoryStore() {
        let datastore = DataStoreMemory<String>(storeName: "testingDataStoreMemory")
        
        datastore.saveItem(forKey: "testString", value: "value")
        
        let value = datastore.getItem(forKey: "testString") as! String
        
        XCTAssert(value == "value")
        
        datastore.unsubscribe()
        
        datastore.subscribe()
        
        datastore.load(forKey: "testingDataStoreMemory")
        
        let v2 = datastore.getItem(forKey: "testString") as! String
        
        XCTAssert(v2 == value)
    }

    func testUserDefaults2() {
        let ds = DataStoreUserDefaults()
        let data = "{}".data(using: .utf8)
        
        ds.saveItem(forKey: "item", value: [data])
        
        var item = ds.getItem(forKey: "item") as? [Data]
        
        XCTAssertNotNil(item)
        
        ds.removeItem(forKey: "item")

        item = ds.getItem(forKey: "item") as? [Data]
        
        XCTAssertNil(item)
    }
    
    func testBackgroundSave() {
         let datastore = DataStoreMemory<[String]>(storeName: "testBackgroundSave")
         
         let key = "testBackgroundSave"
         datastore.saveItem(forKey: key, value: ["value"])
         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")

         datastore.applicationDidEnterBackground()
         datastore.saveItem(forKey: key, value:["v"])
         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")

         datastore.applicationDidBecomeActive()
         
         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")
         XCTAssertNotNil(datastore.data)

        datastore.load(forKey: key)
         
         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")
         XCTAssertEqual(datastore.data, ["value"])
         
         datastore.removeItem(forKey: key)
     }

    func testBackgroundSaveUserDefaults() {
        let datastore = DataStoreMemory<String>(storeName: "testBackgroundSaveUserDefaults",
                                                backupStore: .userDefaults)
        
        let key = "testBackgroundSaveUserDefaults"
        datastore.saveItem(forKey: key, value: "value")
        print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")

        datastore.applicationDidEnterBackground()
        datastore.saveItem(forKey: key, value:"v")
        print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")

        datastore.applicationDidBecomeActive()
        
        print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")
        XCTAssertNotNil(datastore.data)
        
        datastore.load(forKey: key)
        
        print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")
        XCTAssertEqual(datastore.data, "value")
        
        datastore.removeItem(forKey: key)
    }

    func testFileStore() {
        // simple file store test
        
        let datastore = DataStoreFile<[String]>(storeName: "testFileStore")
        
        datastore.saveItem(forKey: "testString", value: ["value"])
        
        let vj = datastore.getItem(forKey: "testString") as! [String]
        
        XCTAssert(vj.first == "value")
        
        datastore.removeItem(forKey: "testString")
        
    }
    
    func testFileStoreString() {
         let datastore = DataStoreFile<String>(storeName: "testFileStoreString")
         
         let key = "testFileStoreString"
         datastore.saveItem(forKey: key, value: "value")
         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")

         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")
        let item = datastore.getItem(forKey:key) as? String
        
         XCTAssertEqual(item, "value")
         
         datastore.removeItem(forKey: key)
     }

    func testFileStoreInt() {
         let datastore = DataStoreFile<Int>(storeName: "testFileStoreInt")
         
         let key = "testFileStoreInt"
         datastore.saveItem(forKey: key, value: 5)
         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")

         print("[DataStoreTest] \(String(describing: datastore.getItem(forKey: key)))")
        let item = datastore.getItem(forKey:key) as? Int
        
         XCTAssertEqual(item, 5)
         
         datastore.removeItem(forKey: key)
     }


    
    func testUserDefaults() {
        // simple user defaults test
        
        let datastore = DataStoreUserDefaults()
        
        datastore.saveItem(forKey: "testString", value: "value")
        
        let value = datastore.getItem(forKey: "testString") as! String
        
        XCTAssert(value == "value")
        
        datastore.removeItem(forKey: "testString")
        
    }

    func testUserDefaultsTooBig() {
        // Since UserDefaults has a hard limit in tvOS, we chose a relatively small size
        // 128k as a max for user defaults saving.
        HandlerRegistryService.shared.binders.property?.removeAll()

        let datastore = DataStoreUserDefaults()
        
        class Logger : OPTLogger {
            public var messages: [String] = [String]()
            required init() {
    
            }
            static var logLevel: OptimizelyLogLevel {
                get {
                    return OptimizelyLogLevel.info
                }
                set {
                    // necessary for OPTLogger protocol
                }
            }
            
            func log(level: OptimizelyLogLevel, message: String) {
                messages.append(message)
            }
        }
        let logger = Logger()
        
        let binder: Binder = Binder<OPTLogger>(service: OPTLogger.self, factory: { () -> OPTLogger? in
            return logger
        })

        HandlerRegistryService.shared.registerBinding(binder: binder)
        
        var array = [Data]()
        for _ in 0 ... DataStoreUserDefaults.MAX_DS_SIZE + 1 {
            array.append("01234567890abcdef".data(using: .ascii)!)
        }
        
        datastore.saveItem(forKey: "testUserDefaultsTooBig", value: array)
        
        let value = datastore.getItem(forKey: "testUserDefaultsTooBig") as? [Data]
        XCTAssert(value == nil)
        XCTAssert(logger.messages.last!.contains("Save to User Defaults error: testUserDefaultsTooBig is too big to save size"))
        HandlerRegistryService.shared.binders.property?.removeAll()
    }
 }
