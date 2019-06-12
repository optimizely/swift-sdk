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
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
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
    
    func testBackgroundSave() {
        let datastore = DataStoreMemory<String>(storeName: "testingBackgroundSave")
        
        datastore.saveItem(forKey: "testString1", value: "value")
        
        datastore.applicationDidEnterBackground()
        
        datastore.applicationDidBecomeActive()
        
        XCTAssertNotNil(datastore.data)
        
        datastore.save(forKey: "testString1", value: 100)
        
        datastore.load(forKey: "testingBackgroundSave")
        
        XCTAssertEqual(datastore.data, "value")
    }

    func testFileStore() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let datastore = DataStoreFile<[String]>(storeName: "testingDataStoreFile")
        
        datastore.saveItem(forKey: "testString", value: ["value"])
        
        let vj = datastore.getItem(forKey: "testString") as! [String]
        
        XCTAssert(vj.first == "value")
        
    }
    
    func testUserDefaults() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let datastore = DataStoreMemory<String>(storeName: "testingDataStoreUserDefaults")
        
        datastore.saveItem(forKey: "testString", value: "value")
        
        let value = datastore.getItem(forKey: "testString") as! String
        
        XCTAssert(value == "value")
        
        datastore.unsubscribe()
        
        datastore.subscribe()
        
        datastore.load(forKey: "testingDataStoreUserDefaults")
        
        let v2 = datastore.getItem(forKey: "testString") as! String
        
        XCTAssert(v2 == value)

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
