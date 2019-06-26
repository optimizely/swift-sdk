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

class DatafileHandlerTests: XCTestCase {

    override func setUp() {
        
        HandlerRegistryService.shared.binders.property?.removeAll()
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
        HandlerRegistryService.shared.binders.property?.removeAll()
    }

    func testDatafileHandler() {
        
        let handler = DefaultDatafileHandler()
        
        let data = handler.downloadDatafile(sdkKey: "fakeSDKKey")
        XCTAssertNil(data)
        
        let notLoaded = handler.loadSavedDatafile(sdkKey: "asdfdasfafafsafdsadf")
        
        XCTAssertNil(notLoaded)
        
        var saved = handler.isDatafileSaved(sdkKey: "fakeSDKKey")
        
        XCTAssertFalse(saved)
        
        handler.saveDatafile(sdkKey: "fakeSDKKey", dataFile: "{}".data(using: .utf8)!)
        
        saved = handler.isDatafileSaved(sdkKey: "fakeSDKKey")
        
        XCTAssertTrue(saved)
        
        let loaded = handler.loadSavedDatafile(sdkKey: "fakeSDKKey")
        
        let empty = String(data: loaded!, encoding: .utf8)
        
        XCTAssertEqual(empty, "{}")
        
        handler.removeSavedDatafile(sdkKey: "fakeSDKKey")
        
        saved = handler.isDatafileSaved(sdkKey: "fakeSDKKey")
        
        XCTAssertFalse(saved)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testDatafileDownload304NoCache() {
        
        var localUrl:URL?
        
        // create a dummy file at a url to use as or datafile cdn location
        localUrl = OTUtils.saveAFile(name: "localcdn", data: Data())

        // default datafile handler
        class InnerDatafileHandler : DefaultDatafileHandler {
            var localFileUrl:URL?
            // override getSession to return our own session.
            override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
            
                let session = MockUrlSession()
                session.downloadCacheUrl = localFileUrl
                
                return session
            }
        }
        
        // create test datafile handler
        let handler = InnerDatafileHandler()
        //remove any cached datafile..
        handler.removeSavedDatafile(sdkKey: "localcdnTestSDKKey")
        // set the url to use as our datafile download url
        handler.localFileUrl = localUrl
        
        let expectation = XCTestExpectation(description: "wait to get no-nil data")
        
        // initiate download task which should pass back a 304 but still return non nil
        // since the datafile was not in cache.
        handler.downloadDatafile(sdkKey: "localcdnTestSDKKey") { (result) in
            switch result {
            case .success(let data):
                XCTAssert(data != nil)
                expectation.fulfill()
            case .failure(let error):
                XCTAssert(error.errorDescription != nil)
            }
        }
        
        wait(for: [expectation], timeout: 3)
        // finally remove the datafile when complete.
        try? FileManager.default.removeItem(at: localUrl!)
    }

    func testDatafileDownload304WithCache() {
        
        var fileUrl:URL?
        
        // create a dummy file at a url to use as our datafile local download location
        fileUrl = OTUtils.saveAFile(name: "localcdn", data: Data())
        
        // default datafile handler
        class InnerDatafileHandler : DefaultDatafileHandler {
            var localFileUrl:URL?
            // override getSession to return our own session.
            override func getSession(resourceTimeoutInterval: Double?) -> URLSession {

                let session = MockUrlSession()
                session.downloadCacheUrl = localFileUrl
                
                return session
            }
        }
        
        // create test datafile handler
        let handler = InnerDatafileHandler()
        //save the cached datafile..
        handler.saveDatafile(sdkKey: "localcdnTestSDKKey", dataFile: "{}".data(using: .utf8)!)
        handler.dataStore.setLastModified(sdkKey: "localcdnTestSDKKey", lastModified: "1234")
        // set the url to use as our datafile download url
        handler.localFileUrl = fileUrl
        
        let expectation = XCTestExpectation(description: "wait to get no-nil data")
        
        // initiate download task which should pass back a 304 but still return non nil
        // since the datafile was not in cache.
        handler.downloadDatafile(sdkKey: "localcdnTestSDKKey") { (result) in
            switch result {
            case .success(let data):
                // should come back as nil since got 304 and datafile in cache.
                XCTAssert(data == nil)
                expectation.fulfill()
            case .failure(let error):
                XCTAssert(error.errorDescription != nil)
            }
        }
        
        wait(for: [expectation], timeout: 3)
        // finally remove the datafile when complete.
        try? FileManager.default.removeItem(at: fileUrl!)
    }

    func testPeriodicDownload() {
        class FakeDatafileHandler: DefaultDatafileHandler {
            let data = Data()
            override func downloadDatafile(sdkKey: String, resourceTimeoutInterval: Double?, completionHandler: @escaping DatafileDownloadCompletionHandler) {
                completionHandler(.success(data))
            }
        }
        let expection = XCTestExpectation(description: "Expect 10 periodic downloads")
        let handler = FakeDatafileHandler()
        let now = Date()
        var count = 0
        var seconds = 0
        handler.startPeriodicUpdates(sdkKey: "notrealkey", updateInterval: 1) { (_) in
            count += 1
            if count == 10 {
                handler.stopPeriodicUpdates()
                expection.fulfill()
                seconds = Int(abs(now.timeIntervalSinceNow))
            }
        }
        
        wait(for: [expection], timeout: 20)
        
        XCTAssert(count == 10)
        XCTAssert(seconds == 10)
        
    }
    
    func testPeriodicDownloadWithOptimizlyClient() {
        class FakeDatafileHandler: DefaultDatafileHandler {
            let data = OTUtils.loadJSONDatafile("typed_audience_datafile")
            override func downloadDatafile(sdkKey: String, resourceTimeoutInterval: Double?, completionHandler: @escaping DatafileDownloadCompletionHandler) {
                completionHandler(.success(data))
            }
        }
        let expection = XCTestExpectation(description: "Expect 10 periodic downloads")
        let handler = FakeDatafileHandler()

        HandlerRegistryService.shared.registerBinding(binder: Binder(service: OPTDatafileHandler.self).sdkKey(key: "notrealkey123").using(instance: handler).to(factory: FakeDatafileHandler.init).reInitializeStrategy(strategy: .reUse).singetlon())
        
        let optimizely = OptimizelyClient(sdkKey: "notrealkey123", periodicDownloadInterval: 1)

        var count = 0
        
        _ = optimizely.notificationCenter.addDatafileChangeNotificationListener { (_) in
            count += 1
            if count == 9 {
                optimizely.datafileHandler.stopAllUpdates()
                expection.fulfill()
            }
        }
        optimizely.start { (_) in
            XCTAssert(true)
        }
        wait(for: [expection], timeout: 10)
        
        XCTAssert(count == 9)
        
    }

    func testDownloadTimeout() {
        let handler = DefaultDatafileHandler()
        handler.endPointStringFormat = "https://httpstat.us/200?sleep=5000&datafile=%@"
        
        let expectation = XCTestExpectation(description: "should fail before 10")
        handler.downloadDatafile(sdkKey: "invalidKey1212121", resourceTimeoutInterval: 3) { (result) in
            switch result {
            case .failure(let error):
                print(error)
                XCTAssert(true)
                expectation.fulfill()
            case .success(_):
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
        
    }
    
    func testDownloadWithoutTimeout() {
        let handler = DefaultDatafileHandler()
        handler.endPointStringFormat = "https://httpstat.us/200?sleep=3000&datafile=%@"
        
        let expectation = XCTestExpectation(description: "will wait for response.")
        handler.downloadDatafile(sdkKey: "invalidKeyXXXXX") { (result) in
            switch result {
            case .failure(let error):
                print(error)
                XCTAssert(false)
            case .success(let data):
                print(data ?? "")
                XCTAssert(true)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 10.0)
        
    }
}
