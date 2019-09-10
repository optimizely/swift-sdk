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

class OptimizelyClientTests_DatafileHandler_Exceptions: XCTestCase {
    let cachedDatafileName = "api_datafile"
    let cachedDatafileProjectId = "10431130345"
    
    let downloadedDatafileName = "empty_datafile"
    let downloadedDatafileProjectId = "100000111"

    let invalidSdkKey = "invalidKey"
    var optimizely: OptimizelyClient!

    override func setUp() {
    }
    
    override func tearDown() {
        HandlerRegistryService.shared.binders.property?.removeAll()
    }
    
    func testOptimizelyInitWith200() {
        setDatafileManagerWithCachedDatafile(testConfig: .network200_CacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .success(data) = result {
                XCTAssert(!data.isEmpty)
                XCTAssertEqual(self.optimizely.config?.project!.projectId, self.downloadedDatafileProjectId)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

    func testOptimizelyInitWith304_CacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .network304_CacheFound)

        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .success(data) = result {
                XCTAssert(!data.isEmpty)
                XCTAssertEqual(self.optimizely.config?.project!.projectId, self.cachedDatafileProjectId)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testOptimizelyInitWith304_NoCacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .network304_NoCacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileLoadingFailed = error {
                // 304 received, but failed to load cached file. expect loadFail error
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testOptimizelyInitWith400_CacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .network400_CacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileDownloadFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testOptimizelyInitWith400_NoCacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .network400_NoCacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileDownloadFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

    func testOptimizelyInitWith500_CacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .network500_CacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileDownloadFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testOptimizelyInitWith500_NoCacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .network500_NoCacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileDownloadFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testOptimizelyInitWithDown_CacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .networkDown_CacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileDownloadFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

    func testOptimizelyInitWithDown_NoCacheFound() {
        setDatafileManagerWithCachedDatafile(testConfig: .networkDown_NoCacheFound)
        
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileDownloadFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
}

// MARK: - Utils

extension OptimizelyClientTests_DatafileHandler_Exceptions {
    
    enum TestConfig {
        case network200_CacheFound
        case network200_NoCacheFound
        case network304_CacheFound
        case network304_NoCacheFound
        case network400_CacheFound
        case network400_NoCacheFound
        case network500_CacheFound
        case network500_NoCacheFound
        case networkDown_CacheFound
        case networkDown_NoCacheFound
    }

    func setDatafileManagerWithCachedDatafile(testConfig: TestConfig) {
        // create test datafile handler
        let handler = InnerDatafileHandler(sdkKey: invalidSdkKey, testConfig: testConfig)
        
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).using(instance: handler).singetlon().sdkKey(key: invalidSdkKey).reInitializeStrategy(strategy: .reUse))
        
        optimizely = OptimizelyClient(sdkKey: invalidSdkKey)
    }
    
    // default datafile handler
    class InnerDatafileHandler : DefaultDatafileHandler {
        var tempUrlForNetworkData: URL?
        let sdkKey: String
        var testConfig: TestConfig

        init(sdkKey: String, testConfig: TestConfig) {
            //  data holder for network download response emulation
            self.tempUrlForNetworkData = OTUtils.saveAFile(name: "cached", data: OTUtils.loadJSONDatafile("empty_datafile")!)
            self.sdkKey = sdkKey
            self.testConfig = testConfig
            
            super.init()
            
            switch testConfig {
            case .network200_CacheFound,
                 .network304_CacheFound,
                 .network400_CacheFound,
                 .network500_CacheFound,
                 .networkDown_CacheFound:
                
                // set a cached datafile.
                let data = OTUtils.loadJSONDatafile("api_datafile")
                self.saveDatafile(sdkKey: sdkKey, dataFile: data!)
                self.dataStore.setLastModified(sdkKey: sdkKey, lastModified: "1234")
                
            default:
                print("Testing no-cached-datafile")
            }
        }
        
        required init() {
            fatalError("init() has not been implemented")
        }
        
        deinit {
            if let temp = tempUrlForNetworkData {
                try? FileManager.default.removeItem(at: temp)
            }
            
            self.removeSavedDatafile(sdkKey: sdkKey)
            
            stopAllUpdates()
        }
        
        // override getSession to return our own session.
        override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
            
            let session = TestUrlSession(testConfig: testConfig)
            session.downloadCacheUrl = tempUrlForNetworkData
            
            return session
        }
    }
    
    class TestUrlSession : URLSession {
        var downloadCacheUrl:URL?
        let testConfig: TestConfig
        
        init(testConfig: TestConfig) {
            self.testConfig = testConfig
        }
        
        override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
            
            var statusCode: Int

            switch testConfig {
            case .network200_CacheFound,
                 .network200_NoCacheFound:
                statusCode = 200
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(downloadCacheUrl!, response, nil)
            case .network304_CacheFound,
                 .network304_NoCacheFound:
                statusCode = 304
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(nil, response, nil)
            case .network400_CacheFound,
                 .network400_NoCacheFound:
                statusCode = 400
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(nil, response, nil)
            case .network500_CacheFound,
                 .network500_NoCacheFound:
                statusCode = 500
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(nil, response, nil)
            case .networkDown_CacheFound,
                .networkDown_NoCacheFound:
                
                completionHandler(nil, nil, NSError(domain: "test.domain", code: 1, userInfo: nil))
            }
            
            return TestDownloadTask()
        }
        
        class TestDownloadTask : URLSessionDownloadTask {
            override func resume() {}
        }
    }

}
