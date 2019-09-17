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
    let invalidSdkKey = "invalidKey"
    var optimizely: OptimizelyClient!

    override func setUp() {
    }
    
    override func tearDown() {
        HandlerRegistryService.shared.binders.property?.removeAll()
    }
    
    func testOptimizelyInitWith200() {
        setDatafileManager(test: .network200(cacheFound: true))
        checkOptimizelyReturnsDatafile_Downloaded()
    }

    func testOptimizelyInitWith304_CacheFound() {
        setDatafileManager(test: .network304(cacheFound: true))
        checkOptimizelyReturnsDatafile_Cached()
    }
    
    func testOptimizelyInitWith304_NoCacheFound() {
        setDatafileManager(test: .network304(cacheFound: false))
        checkOptimizelyReturnsError_LoadingFailed()
    }
    
    func testOptimizelyInitWith400_CacheFound() {
        setDatafileManager(test: .network400(cacheFound: true))
        checkOptimizelyReturnsError_DownloadFailed()
    }
    
    func testOptimizelyInitWith400_NoCacheFound() {
        setDatafileManager(test: .network400(cacheFound: false))
        checkOptimizelyReturnsError_DownloadFailed()
    }

    func testOptimizelyInitWith500_CacheFound() {
        setDatafileManager(test: .network500(cacheFound: true))
        checkOptimizelyReturnsError_DownloadFailed()
    }
    
    func testOptimizelyInitWith500_NoCacheFound() {
        setDatafileManager(test: .network500(cacheFound: false))
        checkOptimizelyReturnsError_DownloadFailed()
    }
    
    func testOptimizelyInitWithDown_CacheFound() {
        // when network interface is down, Optimizely returns immediately with cached datafile
        setDatafileManager(test: .networkDown(cacheFound: true))
        checkOptimizelyReturnsDatafile_Cached()
    }

    func testOptimizelyInitWithDown_NoCacheFound() {
        setDatafileManager(test: .networkDown(cacheFound: false))
        checkOptimizelyReturnsError_LoadingFailed()
    }
}

// MARK: - Utils

fileprivate let cachedDatafileName = "api_datafile"
fileprivate let cachedDatafileProjectId = "10431130345"

fileprivate let downloadedDatafileName = "empty_datafile"
fileprivate let downloadedDatafileProjectId = "100000111"

extension OptimizelyClientTests_DatafileHandler_Exceptions {
    
    enum TestConfig {
        case network200(cacheFound: Bool)
        case network304(cacheFound: Bool)
        case network400(cacheFound: Bool)
        case network500(cacheFound: Bool)
        case networkDown(cacheFound: Bool)
    }
    
    func setDatafileManager(test: TestConfig) {
        // create test datafile handler
        let handler = DMTestDatafileHandler(sdkKey: invalidSdkKey, test: test)
        
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).using(instance: handler).singetlon().sdkKey(key: invalidSdkKey).reInitializeStrategy(strategy: .reUse))
        
        optimizely = OptimizelyClient(sdkKey: invalidSdkKey)
    }
    
    func checkOptimizelyReturnsDatafile_Downloaded() {
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .success(data) = result {
                XCTAssert(!data.isEmpty)
                XCTAssertEqual(self.optimizely.config?.project!.projectId, downloadedDatafileProjectId)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)

    }

    func checkOptimizelyReturnsDatafile_Cached() {
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .success(data) = result {
                XCTAssert(!data.isEmpty)
                XCTAssertEqual(self.optimizely.config?.project!.projectId, cachedDatafileProjectId)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func checkOptimizelyReturnsError_DownloadFailed() {
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
    
    func checkOptimizelyReturnsError_LoadingFailed() {
        let expectation = XCTestExpectation(description: "x")
        
        optimizely.start() { (result) in
            if case let .failure(error) = result, case .datafileLoadingFailed = error {
                // download failed - expect error (instead of loading cached datatfile)
                expectation.fulfill()
            } else {
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

}

// MARK: - Mock

extension OptimizelyClientTests_DatafileHandler_Exceptions {
    
    // default datafile handler
    class DMTestDatafileHandler : DefaultDatafileHandler {
        var tempUrlForNetworkData: URL?
        let sdkKey: String
        var testConfig: TestConfig

        init(sdkKey: String, test: TestConfig) {
            //  data holder for network download response emulation
            self.tempUrlForNetworkData = OTUtils.saveAFile(name: "cached", data: OTUtils.loadJSONDatafile(downloadedDatafileName)!)
            self.sdkKey = sdkKey
            self.testConfig = test
            
            super.init()
            
            switch testConfig {
            case .network200(let cacheFound),
                 .network304(let cacheFound),
                 .network400(let cacheFound),
                 .network500(let cacheFound),
                 .networkDown(let cacheFound):
                
                if cacheFound {
                    // set a cached datafile.
                    let data = OTUtils.loadJSONDatafile(cachedDatafileName)
                    self.saveDatafile(sdkKey: sdkKey, dataFile: data!)
                    self.dataStore.setLastModified(sdkKey: sdkKey, lastModified: "1234")
                }
                
                if case .networkDown = testConfig {
                    NetworkReachability.shared.reachable = false
                }
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
            return DMTestUrlSession(testConfig: testConfig, downloadCacheUrl: tempUrlForNetworkData)
        }
    }
    
    class DMTestUrlSession : URLSession {
        let downloadCacheUrl:URL?
        let testConfig: TestConfig
        
        init(testConfig: TestConfig, downloadCacheUrl: URL?) {
            self.testConfig = testConfig
            self.downloadCacheUrl = downloadCacheUrl
        }
        
        override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
            
            switch testConfig {
            case .network200:
                let statusCode = 200
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(downloadCacheUrl!, response, nil)
            case .network304:
                let statusCode = 304
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(nil, response, nil)
            case .network400:
                let statusCode = 400
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(nil, response, nil)
            case .network500:
                let statusCode = 500
                let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)
                completionHandler(nil, response, nil)
            case .networkDown:
                completionHandler(nil, nil, NSError(domain: "test.domain", code: 1, userInfo: nil))
            }
            
            class SilentDownloadTask : URLSessionDownloadTask {
                override func resume() {}
            }
            return SilentDownloadTask()
        }
    }

}
