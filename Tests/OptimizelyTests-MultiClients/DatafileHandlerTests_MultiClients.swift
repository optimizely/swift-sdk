//
// Copyright 2021, Optimizely, Inc. and contributors 
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

import XCTest

class DatafileHandlerTests_MultiClients: XCTestCase {

    var sdkKeys = [String]()
    var handler = DefaultDatafileHandler()

    override func setUp() {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
        OTUtils.clearAllTestStorage()

        sdkKeys = OTUtils.makeRandomSdkKeys(10)
    }

    override func tearDown() {
        OTUtils.clearAllBinders()
        OTUtils.clearAllTestStorage()
    }
    
    // MARK: - downloadDatafile
    
    func testConcurrentDownloadDatafiles() {
        // use a shared DatafileHandler instance
        let mockHandler = MockDatafileHandler(statusCode: 200)
        
        sdkKeys = OTUtils.makeRandomSdkKeys(100)

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { _, sdkKey in
            let group = DispatchGroup()
            
            group.enter()
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                let expectedDatafile = mockHandler.getDatafile(sdkKey: sdkKey)

                switch result {
                case .success(let data):
                    if let data = data {
                        let str = String(data: data, encoding: .utf8)
                        XCTAssert(str == expectedDatafile)
                    } else {
                        XCTFail()
                    }
                default:
                    XCTFail()
                }
                
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    func testConcurrentDownloadDatafilesWithErrors() {
        let numSdkKeys = 100
        sdkKeys = OTUtils.makeRandomSdkKeys(100)

        // set response code + error distribution
        
        let num304 = 20
        let num400 = 20
        let numError = 20
        let numSuccess = 40
        XCTAssert(num304 + num400 + numError + numSuccess == numSdkKeys)
    
        var settingsMap = [String: (Int, Bool)]()
        for (idx, sdkKey) in sdkKeys.enumerated() {
            var statusCode: Int = 0
            var withError: Bool = false

            switch idx {
            case 0..<num304:
                statusCode = 304
                withError = false
            case (num304+1)..<(num304+num400):
                statusCode = 400
                withError = false
            case (num304+num400+1)..<(num304+num400+numError):
                statusCode = 999
                withError = true
            default:
                statusCode = 200
                withError = false
            }
            
            settingsMap[sdkKey] = (statusCode, withError)
            
            OTUtils.createDatafileCache(sdkKey: sdkKey)
        }
        
        // use a shared DatafileHandler instance
        let mockHandler = MockDatafileHandler(settingsMap: settingsMap)
    
        let recv304 = AtomicProperty<Int>(property: 0)
        let recvSuccess = AtomicProperty<Int>(property: 0)

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { idx, sdkKey in
            let group = DispatchGroup()
            
            group.enter()
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                let expectedDatafile = mockHandler.getDatafile(sdkKey: sdkKey)
                
                switch result {
                case .success(let data):
                    if let data = data {
                        recvSuccess.performAtomic{ $0 += 1 }

                        let str = String(data: data, encoding: .utf8)
                        XCTAssert(str == expectedDatafile)
                    } else if settingsMap[sdkKey]!.0 == 304 {
                        recv304.performAtomic{ $0 += 1 }
                    }
                default:
                    // DefaultDatafileHandler will return .success (cached datafile) on any error
                    XCTAssert(false, "Unexpected datafile error for \(String(describing: sdkKey))")
                }
                
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
        XCTAssertEqual(recvSuccess.property, numSuccess + num400 + numError)
        XCTAssertEqual(recv304.property, num304)
    }
    
    func testConcurrentAccessLastModified() {
        // use a shared DatafileHandler instance
        let mockHandler = MockDatafileHandler(statusCode: 200)

        sdkKeys = OTUtils.makeRandomSdkKeys(100)

        let result = OTUtils.runConcurrent(for: sdkKeys, timeoutInSecs: 10) { _, sdkKey in
            let expectedLastModified = mockHandler.getLastModified(sdkKey: sdkKey)
            
            let group = DispatchGroup()
            
            group.enter()
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                // validate lastModified saved and read ok concurrently for multiple sdkKeys
                XCTAssertEqual(mockHandler.getRequest(sdkKey: sdkKey)?.getLastModified(), expectedLastModified)
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    // MARK: - Datafile Caches
    
    func testConcurrentAccessDatafileCaches() {
        sdkKeys = OTUtils.makeRandomSdkKeys(100)

        let result = OTUtils.runConcurrent(for: sdkKeys) { idx, sdkKey in
            let maxCnt = 10
            for _ in 0..<maxCnt {
                let data = sdkKey.data(using: .utf8)!
                
                self.handler.saveDatafile(sdkKey: sdkKey, dataFile: data)
                if self.handler.isDatafileSaved(sdkKey: sdkKey) {
                    let loadData = self.handler.loadSavedDatafile(sdkKey: sdkKey)
                    XCTAssertEqual(String(bytes: loadData ?? Data(), encoding: .utf8)!, sdkKey)
                    self.handler.removeSavedDatafile(sdkKey: sdkKey)
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    // MARK: - Periodic Interval
    
    func testConcurrentAccessPeriodicInterval() {
        sdkKeys = OTUtils.makeRandomSdkKeys(100)

        let result = OTUtils.runConcurrent(for: sdkKeys) { _, _ in
            let maxCnt = 100
            for _ in 0..<maxCnt {
                let writeKey = String(Int.random(in: 0..<maxCnt))
                self.handler.setPeriodicInterval(sdkKey: writeKey, interval: 60)
                
                let readKey = String(Int.random(in: 0..<maxCnt))
                _ = self.handler.hasPeriodicInterval(sdkKey: readKey)
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    // MARK: - Periodic Updates
    
    func testConcurrentControlPeriodicUpdates() {
        
        struct Periodics {
            let sdkKey: String
            var exp: XCTestExpectation
            var count: Int = 5

            init(sdkKey: String, exp: XCTestExpectation) {
                self.sdkKey = sdkKey
                self.exp = exp
            }

            mutating func notify() {
                count -= 1
                if count == 0 {
                    self.exp.fulfill()
                }
            }
        }
        
        // use a shared DatafileHandler instance
        let mockHandler = MockDatafileHandler(statusCode: 200)
        
        let numSdks = 50
        sdkKeys = OTUtils.makeRandomSdkKeys(numSdks)
        
        var exps = [XCTestExpectation]()
        var periodics = [Periodics]()
        
        for i in 0..<numSdks {
            exps.append(expectation(description: "\(i)"))
            periodics.append(Periodics(sdkKey: sdkKeys[i], exp: exps[i]))
        }
        
        for var p in periodics {
            let sdkKey = p.sdkKey
            
            mockHandler.setPeriodicInterval(sdkKey: sdkKey, interval: 1)
            
            //print("[MultiClientsTest] datafile backgroup update started for: \(sdkKey)")
            mockHandler.startUpdates(sdkKey: sdkKey, datafileChangeNotification: { data in
                let expectedDatafile = mockHandler.getDatafile(sdkKey: sdkKey)

                let str = String(data: data, encoding: .utf8)
                XCTAssert(str == expectedDatafile)
                p.notify()
            })
        }
        
        wait(for: exps, timeout: 10)
    }

}

