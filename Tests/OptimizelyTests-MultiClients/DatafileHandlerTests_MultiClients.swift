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

    let testSdkKeyBasename = "testSdkKey"
    var sdkKeys = [String]()
    var handler = DefaultDatafileHandler()

    override func setUp() {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
        
        makeSdkKeys(10)
    }

    override func tearDown() {
        OTUtils.clearAllBinders()
        OTUtils.clearAllTestStorage(including: testSdkKeyBasename)
    }
    
    // MARK: - downloadDatafile
    
    func testConcurrentDownloadDatafiles() {
        makeSdkKeys(100)
        
        let result = runConcurrent(for: sdkKeys, timeoutInSecs: 10) { sdkKey, _ in
            let mockHandler = MockDatafileHandler(failureCode: 0,
                                                  passError: false,
                                                  sdkKey: sdkKey,
                                                  strData: sdkKey)
            
            let group = DispatchGroup()
            
            group.enter()
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        let str = String(data: data, encoding: .utf8)
                        XCTAssert(str == sdkKey)
                    } else {
                        XCTAssert(false)
                    }
                default:
                    XCTAssert(false)
                }
                
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    func testConcurrentDownloadDatafilesWithErrors() {
        let numSdkKeys = 100
        makeSdkKeys(numSdkKeys)

        let num304 = 20
        let num400 = 20
        let numError = 20
        let numSuccess = 40
        XCTAssert(num304 + num400 + numError + numSuccess == numSdkKeys)

        let recv304 = AtomicProperty<Int>(property: 0)
        let recvSuccess = AtomicProperty<Int>(property: 0)

        let result = runConcurrent(for: sdkKeys, timeoutInSecs: 10) { sdkKey, idx in
            var statusCode: Int = 0
            var passError: Bool = false
            
            switch idx {
            case 0..<num304:
                statusCode = 304
                passError = false
            case (num304+1)..<(num304+num400):
                statusCode = 400
                passError = false
            case (num304+num400+1)..<(num304+num400+numError):
                statusCode = 999
                passError = true
            default:
                statusCode = 200
                passError = false
            }
            
            let mockHandler = MockDatafileHandler(failureCode: statusCode,
                                                  passError: passError,
                                                  sdkKey: sdkKey,
                                                  strData: sdkKey)
            
            let group = DispatchGroup()
            
            group.enter()
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        recvSuccess.performAtomic{ $0 += 1 }

                        let str = String(data: data, encoding: .utf8)
                        XCTAssert(str == sdkKey)
                    } else if statusCode == 304 {
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
        makeSdkKeys(100)
        
        let result = runConcurrent(for: sdkKeys, timeoutInSecs: 10) { sdkKey, _ in
            let expectedLastModified = "date-for-\(sdkKey)"
            
            let mockHandler = MockDatafileHandler(failureCode: 0,
                                                  passError: false,
                                                  sdkKey: sdkKey,
                                                  strData: sdkKey,
                                                  lastModified: expectedLastModified)
            
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
    
    // MARK: - Periodic Interval
    
    func testConcurrentAccessPeriodicInterval() {
        makeSdkKeys(100)

        let result = runConcurrent(for: sdkKeys) { _, _ in
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
    
    // MARK: - Datafile Caches
    
    func testConcurrentAccessDatafileCaches() {
        makeSdkKeys(100)
        
        let result = runConcurrent(for: sdkKeys) { sdkKey, idx in
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
        
        let numSdks = 10
        makeSdkKeys(numSdks)
        var exps = [XCTestExpectation]()
        var periodics = [Periodics]()
        
        for i in 0..<numSdks {
            exps.append(expectation(description: "\(i)"))
            periodics.append(Periodics(sdkKey: sdkKeys[i], exp: exps[i]))
        }
        
        for var p in periodics {
            let sdkKey = p.sdkKey
            
            let mockHandler = MockDatafileHandler(failureCode: 0,
                                                  passError: false,
                                                  sdkKey: sdkKey,
                                                  strData: sdkKey)
            mockHandler.setPeriodicInterval(sdkKey: sdkKey, interval: 1)
            
            //print("[MultiClientsTest] datafile backgroup update started for: \(sdkKey)")
            mockHandler.startUpdates(sdkKey: sdkKey, datafileChangeNotification: { data in
                //print("[MultiClientsTest] datafile change notification called for: \(sdkKey)")
                let str = String(data: data, encoding: .utf8)
                XCTAssert(str == sdkKey)
                p.notify()
                
                // random inteference with other sdkKeys
                for _ in 0..<100 {
                    mockHandler.setPeriodicInterval(sdkKey: String(Int.random(in: 0..<1000000)), interval: 60)
                    _ = mockHandler.hasPeriodicInterval(sdkKey: String(Int.random(in: 0..<1000000)))
                }
            })
        }
        
        wait(for: exps, timeout: 10)
    }

}

// MARK: - Utils
    
extension DatafileHandlerTests_MultiClients {
    
    func runConcurrent(for items: [String], timeoutInSecs: Int = 10, task: @escaping (String, Int) -> Void) -> Bool {
        let group = DispatchGroup()
        
        for (idx, item) in items.enumerated() {
            group.enter()
            
            // NOTE: do not use DispatchQueue.global(), which looks like a deadlock because of too many threads
            DispatchQueue(label: item).async {
                task(item, idx)
                group.leave()
            }
        }
        
        let timeout = DispatchTime.now() + .seconds(timeoutInSecs)
        let result = group.wait(timeout: timeout)
        return result == .success
    }
    
    func makeSdkKeys(_ num: Int) {
        sdkKeys = []
        for i in 0..<num {
            let randId = Int.random(in: 0..<1000000)
            sdkKeys.append("\(testSdkKeyBasename)-\(i)-\(randId)")
        }
    }
        
}

