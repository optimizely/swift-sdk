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

class MultiClientsTests_DatafileHandler: XCTestCase {

    let testSdkKeyBasename = "testSdkKey"
    var sdkKeys = [String]()
    var handler = DefaultDatafileHandler()

    override func setUp() {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
        
        makeSdkKeys(10)
    }

    override func tearDown() {
        OTUtils.removeAllBinders()
        OTUtils.removeAllFiles(including: testSdkKeyBasename)
    }
    
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
    
    func testConcurrentAccessDatafileCaches() {
        makeSdkKeys(100)
        
        let result = runConcurrent(for: sdkKeys) { _, _ in
            let maxCnt = 100
            for _ in 0..<maxCnt {
                let testKey = String(Int.random(in: 0..<maxCnt))
                let data = testKey.data(using: .utf8)!
                
                self.handler.saveDatafile(sdkKey: testKey, dataFile: data)
                if self.handler.isDatafileSaved(sdkKey: testKey) {
                    let loadData = self.handler.loadSavedDatafile(sdkKey: testKey)
                    XCTAssertEqual(loadData, data)
                    self.handler.removeSavedDatafile(sdkKey: testKey)
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    func testConcurrentDownloadDatafiles() {
        makeSdkKeys(100)

        let result = runConcurrent(for: sdkKeys, timeoutInSecs: 10) { sdkKey, _ in
            let mockHandler = MockDatafileHandler(failureCode: 0, passError: false, sdkKey: sdkKey, strData: sdkKey)
            
            let group = DispatchGroup()
            
            group.enter()
            print("[MultiClientTest] requesting datafile: \(String(describing: sdkKey))")
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        let str = String(data: data, encoding: .utf8)
                        print("[MultiClientTest] got datafile: \(String(describing: str))")
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
            print("[MultiClientTest] requesting datafile: \(String(describing: sdkKey))")
            mockHandler.downloadDatafile(sdkKey: sdkKey,
                                         returnCacheIfNoChange: false,
                                         resourceTimeoutInterval: 10) { result in
                switch result {
                case .success(let data):
                    if let data = data {
                        recvSuccess.performAtomic{ $0 += 1 }

                        let str = String(data: data, encoding: .utf8)
                        print("[MultiClientTest] got datafile: \(String(describing: str))")
                        XCTAssert(str == sdkKey)
                    } else if statusCode == 304 {
                        recv304.performAtomic{ $0 += 1 }
                        print("[MultiClientTest] got 304 for \(String(describing: sdkKey))")
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
    
}

// MARK: - Utils
    
extension MultiClientsTests_DatafileHandler {
    
    func runConcurrent(for items: [String], timeoutInSecs: Int = 10, task: @escaping (String, Int) -> Void) -> Bool {
        let group = DispatchGroup()
        
        for (idx, item) in items.enumerated() {
            group.enter()
            DispatchQueue.global().async {
                //print("[MultiClientsTest] starting for \(sdkKey)")
                task(item, idx)
                //print("[MultiClientsTest] ending for \(sdkKey)")
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
    
    class MockDatafileHandler: DefaultDatafileHandler {
        let failureCode: Int
        let passError: Bool
        let sdkKey: String
        let localUrl: URL?

        init(failureCode: Int = 0, passError: Bool = false, sdkKey: String, strData: String = "{}") {
            self.failureCode = failureCode
            self.passError = passError
            self.sdkKey = sdkKey
            self.localUrl = OTUtils.saveAFile(name: sdkKey, data: strData.data(using: .utf8)!)
        }
        
        public required init() {
            fatalError("init() has not been implemented")
        }
        
        override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
            return MockUrlSession(failureCode: failureCode, withError: passError, localUrl: localUrl)
        }
    }
    
}

