//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class DatafileHandlerTests: XCTestCase {
    
    let sdkKey = "localcdnTestSDKKey"

    override func setUp() {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
    }

    override func tearDown() {
        OTUtils.clearAllBinders()
        OTUtils.clearAllTestStorage(including: sdkKey)
        XCTAssertEqual(MockUrlSession.validSessions, 0, "all MockUrlSession must be invalidated")
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

    func testDatafileDownload500() {
        OTUtils.createDatafileCache(sdkKey: sdkKey)

        let handler = MockDatafileHandler(statusCode: 500)
        let expectation = XCTestExpectation(description: "wait to get no-nil data")
        
        handler.downloadDatafile(sdkKey: sdkKey) { (result) in
            if case let .success(data) = result  {
                XCTAssert(data != nil)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

    func testDatafileDownloadFailureWithCache() {
        OTUtils.createDatafileCache(sdkKey: sdkKey)

        let handler = MockDatafileHandler(withError: true)
        let expectation = XCTestExpectation(description: "wait to get no-nil data")
        
        handler.downloadDatafile(sdkKey: sdkKey) { (result) in
            if case let .success(data) = result  {
                XCTAssert(data != nil)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

    func testDatafileDownloadFailureWithNoCache() {        
        OTUtils.removeDatafileCache(sdkKey: sdkKey)

        let handler = MockDatafileHandler(withError: true)
        let expectation = XCTestExpectation(description: "wait to get nil data")
        
        handler.downloadDatafile(sdkKey: sdkKey) { (result) in
            if case .success(_) = result  {
                XCTFail()
            }
            if case .failure(_) = result  {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }

    func testDatafileDownload304NoCache() {
        OTUtils.removeDatafileCache(sdkKey: sdkKey)

        let handler = MockDatafileHandler(statusCode: 304)
        let expectation = XCTestExpectation(description: "wait to get no-nil data")
        
        handler.downloadDatafile(sdkKey: sdkKey) { result in
            if case let .success(data) = result  {
                XCTAssert(data == nil)
                expectation.fulfill()
            }
        }
        let expectation2 = XCTestExpectation(description: "wait to get data")
        
        handler.downloadDatafile(sdkKey: sdkKey, returnCacheIfNoChange: true) { result in
            // should come back with error since got 304 and datafile is not available in cache.
            if case .failure = result  {
                expectation2.fulfill()
            }
        }

        wait(for: [expectation, expectation2], timeout: 3)
    }

    func testDatafileDownload304WithCache() {
        OTUtils.createDatafileCache(sdkKey: sdkKey)

        let handler = MockDatafileHandler(statusCode: 304)
        let expectation = XCTestExpectation(description: "wait to get no-nil data")
        
        handler.downloadDatafile(sdkKey: sdkKey) { result in
            if case let .success(data) = result  {
                // should come back as nil since got 304 and datafile in cache.
                XCTAssert(data == nil)
                expectation.fulfill()
            }
        }
        let expectation2 = XCTestExpectation(description: "wait to get data")
        
        handler.downloadDatafile(sdkKey: sdkKey, returnCacheIfNoChange: true) { result in
            if case let .success(data) = result  {
                // should come back with data since got 304 and datafile in cache.
                XCTAssert(data != nil)
                expectation2.fulfill()
            }
        }

        wait(for: [expectation, expectation2], timeout: 3)
    }
    
    func testSetPeriodicInterval() {
        let handler = DefaultDatafileHandler()
        XCTAssert(handler.timers.property!.keys.isEmpty)
        
        handler.setPeriodicInterval(sdkKey: "abc", interval: 123)
        XCTAssert(handler.timers.property!.keys.contains("abc"))
        XCTAssert(handler.timers.property!["abc"]!.interval == 123)
    }
    
    func testHasPeriodicInterval() {
        let handler = DefaultDatafileHandler()
        handler.setPeriodicInterval(sdkKey: "abc", interval: 123)
        XCTAssertFalse(handler.hasPeriodicInterval(sdkKey: "x"))
        XCTAssertTrue(handler.hasPeriodicInterval(sdkKey: "abc"))
    }

    func testPeriodicDownload() {
        let expection = XCTestExpectation(description: "Expect 10 periodic downloads")
        let handler = MockDatafileHandler(statusCode: 200)
        let now = Date()
        var count = 0
        var seconds = 0
        handler.startPeriodicUpdates(sdkKey: "testPeriodicDownload", updateInterval: 1) { (_) in
            count += 1
            if count == 10 {
                handler.stopPeriodicUpdates()
                seconds = Int(abs(now.timeIntervalSinceNow))
                expection.fulfill()
            }
        }
        
        wait(for: [expection], timeout: 20)
        
        XCTAssert(count == 10)
        XCTAssert(seconds > 5 && seconds < 20)
    }
    
    func testPeriodicDownload_PollingShouldNotBeAccumulatedWhileInBackground() {
        let expectation = XCTestExpectation(description: "polling")
        let handler = MockDatafileHandler(statusCode: 200)
        let now = Date()
        
        let updateInterval = 1
        let idleTime = 5
        var count = 0
        var seconds = 0
        handler.startPeriodicUpdates(sdkKey: "testPeriodicDownload_PollingShouldNotBeAccumulatedWhileInBackground", updateInterval: updateInterval) { _ in
            // simulate going to background and coming back to foreground after 5secs
            if count == 0 {
                sleep(UInt32(idleTime))
            }
            
            count += 1
            
            // check if delayed polling not accumulated and completed back-to-back
            if count == 5 {
                handler.stopPeriodicUpdates()
                expectation.fulfill()
                seconds = Int(abs(now.timeIntervalSinceNow))
            }
        }
        
        wait(for: [expectation], timeout: 30)

        XCTAssert(seconds >= idleTime + 3)   // 3 instead of 5 for tolerating timer inaccuracy
    }
    
    func testPeriodicDownload_PollingPeriodAdjustedByDelay() {
        class LocalDatafileHandler: DefaultDatafileHandler {
            let data = Data()
            override func downloadDatafile(sdkKey: String,
                                           returnCacheIfNoChange: Bool,
                                           resourceTimeoutInterval: Double?,
                                           completionHandler: @escaping DatafileDownloadCompletionHandler) {
                sleep(1)
                completionHandler(.success(data))
            }
        }
        
        let expectation = XCTestExpectation(description: "polling")
        let handler = LocalDatafileHandler()
        let now = Date()
        
        let updateInterval = 2
        let maxCount = 5
        var count = 0
        var seconds = 0
        handler.startPeriodicUpdates(sdkKey: "testPeriodicDownload_PollingPeriodAdjustedByDelay", updateInterval: updateInterval) { _ in
            count += 1
            
            if count == maxCount {
                handler.stopPeriodicUpdates()
                expectation.fulfill()
                seconds = Int(abs(now.timeIntervalSinceNow))
            }
        }
        
        wait(for: [expectation], timeout: 30)
        XCTAssert(seconds <= updateInterval * (maxCount + 1))
    }

    func testPeriodicDownloadWithOptimizlyClient_SameRevision() {
        let expection = XCTestExpectation(description: "Expect no notification")
        expection.isInverted = true
        
        let handler = MockDatafileHandler(statusCode: 200,
                                          localResponseData: OTUtils.loadJSONDatafileString("typed_audience_datafile"))
        let optimizely = OptimizelyClient(sdkKey: "testPeriodicDownloadWithOptimizlyClient_SameRevision",
                                          datafileHandler: handler,
                                          periodicDownloadInterval: 1)
        
        _ = optimizely.notificationCenter!.addDatafileChangeNotificationListener { _ in
            optimizely.datafileHandler?.stopAllUpdates()
            expection.fulfill()
        }
        optimizely.start { (_) in
            XCTAssert(true)
        }
        
        // notification should not be called. timeout expected here.
        wait(for: [expection], timeout: 3)
    }
    
    func testPeriodicDownloadWithOptimizlyClient_DifferentRevision() {
        class LocalDatafileHandler: DefaultDatafileHandler {
            let data1 = OTUtils.loadJSONDatafile("typed_audience_datafile")
            let data2 = OTUtils.loadJSONDatafile("api_datafile")
            var flag = false

            override func downloadDatafile(sdkKey: String,
                                           returnCacheIfNoChange: Bool,
                                           resourceTimeoutInterval: Double?,
                                           completionHandler: @escaping DatafileDownloadCompletionHandler) {
                // alternate return datafile to change revisionId everytime
                completionHandler(.success(flag ? data1 : data2))
                flag.toggle()
            }
        }
        
        let expection = XCTestExpectation(description: "Expect 10 periodic downloads")
        let handler = LocalDatafileHandler()
        let optimizely = OptimizelyClient(sdkKey: "testPeriodicDownloadWithOptimizlyClient_DifferentRevision",
                                          datafileHandler: handler,
                                          periodicDownloadInterval: 1)
        
        var count = 0

        _ = optimizely.notificationCenter!.addDatafileChangeNotificationListener { _ in
            count += 1
            if count == 9 {
                optimizely.datafileHandler?.stopAllUpdates()
                expection.fulfill()
            }
        }
        optimizely.start { (_) in
            XCTAssert(true)
        }
        wait(for: [expection], timeout: 10)
        
        XCTAssert(count == 9)
    }

    class TimoutDatafileHandler : DefaultDatafileHandler {
        var localFileUrl:URL?
        // override getSession to return our own session.
        override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
            if let _ = resourceTimeoutInterval {
                // will return 500
                return MockUrlSession(withError: true)
            } else {
                return MockUrlSession(statusCode: 200)
            }
        }
    }

    func testDownloadTimeout() {
        let handler = TimoutDatafileHandler()
        
        let expectation = XCTestExpectation(description: "should fail before 10")
        handler.downloadDatafile(sdkKey: "invalidKey1212121", resourceTimeoutInterval: 3) { (result) in
            if case let .failure(error) = result  {
                print(error)
                XCTAssert(true)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testDownloadWithoutTimeout() {
        let handler = TimoutDatafileHandler()
        // create a dummy file at a url to use as or datafile cdn location
        let localUrl = OTUtils.saveAFile(name: "invalidKeyXXXXX", data: "{}".data(using: .utf8)!)
        handler.localFileUrl = localUrl

        let expectation = XCTestExpectation(description: "will wait for response.")
        handler.downloadDatafile(sdkKey: "invalidKeyXXXXX") { (result) in
            if case let .success(data) = result  {
                print(data ?? "")
                XCTAssert(true)
                expectation.fulfill()
                OTUtils.removeAFile(name: "invalidKeyXXXXX")
            }
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func testDatafileCacheFormatCompatibilty() {
        
        // pre-store a datafile in a cache

        let testSDKKey = "testSDKKey"
        let datafileString = OTUtils.emptyDatafile
        let datafileData = datafileString.data(using: .utf8)!

        #if os(tvOS)
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        #else
        var url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #endif
        url = url.appendingPathComponent(testSDKKey, isDirectory: false)
        try! datafileData.write(to: url, options: .atomic)
        
        // verify that a new datafileHandler can read an existing datafile cache

        let datafileFromCache = DefaultDatafileHandler().loadSavedDatafile(sdkKey: testSDKKey)
        XCTAssert(datafileFromCache == datafileData, "failed to support old datafile cached data format")
        
        let project = try! JSONDecoder().decode(Project.self, from: datafileFromCache!)
        XCTAssert(project.revision == "241")
    }

}
