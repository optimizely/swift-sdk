//
// Copyright 2022, Optimizely, Inc. and contributors 
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

class OdpEventApiManagerTests: XCTestCase {
    let userKey = "vuid"
    let userValue = "test-user-value"
    let apiKey = "test-api-key"
    let apiHost = "test-host"
    
    let events: [OdpEvent] = [
        OdpEvent(type: "t1", action: "a1", identifiers: ["id-key-1": "id-value-1"], data: ["key11": "value-1", "key12": true, "key13": 3.5]),
        OdpEvent(type: "t2", action: "a2", identifiers: ["id-key-2": "id-value-2"], data: ["key2": "value-2"])
    ]
    
    // MARK: - success
    
    func testSendOdpEvents_validRequest() {
        let session = MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.successResponseData)
        let api = MockOdpEventApiManager(session)
        
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
        
        let request = session.receivedApiRequest!
        
        XCTAssertEqual(apiHost + "/v3/events", request.url?.absoluteString)
        XCTAssertEqual("POST", request.httpMethod)
        XCTAssertEqual("application/json", request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(apiKey, request.value(forHTTPHeaderField: "x-api-key"))
        
        let bodyArray = try! JSONSerialization.jsonObject(with: request.httpBody!, options: []) as! [[String: Any]]
        let expectedArray = events.map { $0.dict }
        XCTAssertEqual(2, bodyArray.count)
        for i in 0..<bodyArray.count {
            XCTAssert(OTUtils.compareDictionaries(expectedArray[i], bodyArray[i]))
        }
    }
    
    func testSendOdpEvents_success() {
        let api = MockOdpEventApiManager(MockOdpUrlSession(statusCode: 200,
                                                           responseData: MockOdpUrlSession.successResponseData))
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { error in
            XCTAssertNil(error)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    // MARK: - errors
    
    func testSendOdpEvents_networkError_retry() {
        let api = MockOdpEventApiManager(MockOdpUrlSession(withError: true))
        
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { error in
            if case .odpEventFailed(_, let canRetry) = error {
                XCTAssertTrue(canRetry)
            } else {
                XCTFail()
            }
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testSendOdpEvents_400_noRetry() {
        let api = MockOdpEventApiManager(MockOdpUrlSession(statusCode: 400, responseData: MockOdpUrlSession.failureResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { error in
            if case .odpEventFailed(_, let canRetry) = error {
                XCTAssertFalse(canRetry)
            } else {
                XCTFail()
            }
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testSendOdpEvents_500_retry() {
        let api = MockOdpEventApiManager(MockOdpUrlSession(statusCode: 500, responseData: "server error"))
        
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { error in
            if case .odpEventFailed(_, let canRetry) = error {
                XCTAssertTrue(canRetry)
            } else {
                XCTFail()
            }
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    // MARK: - null values
    
    func testSendData_nullValuesPassThrough() {
        let events: [OdpEvent] = [
            // - <nil> data value is converted to NSNull (<null>) after saving into and retrieving from the event queue.
            // - validate both for nil and NSNull
            OdpEvent(type: "t1", action: "a1", identifiers: ["id1": "value1"], data: ["key1": "value1", "key2": nil, "key3": NSNull()]),
        ]
        
        let session = MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.successResponseData)
        let api = MockOdpEventApiManager(session)
        
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
        
        let request = session.receivedApiRequest!
        
        let jsonDispatched = String(bytes: request.httpBody!, encoding: .utf8)!
        // [{"data":{"key2":null,"key3":null,"key1":"value1"},"type":"t1","identifiers":{"id1":"value1"},"action":"a1"}]
        XCTAssert(jsonDispatched.contains("\"key2\":null"))
        XCTAssert(jsonDispatched.contains("\"key3\":null"))
    }
    
    // MARK: - timeout
    
    func testTimeout() {
        let api = OdpEventApiManager(timeout: 3)
        XCTAssertEqual(3, api.getSession().configuration.timeoutIntervalForResource)
    }
    
    func testTimeout_useOSDefaultIfTimeoutIsNotProvided() {
        let api = OdpEventApiManager()
        XCTAssertEqual(604800, api.getSession().configuration.timeoutIntervalForResource)
    }
    
}

// MARK: - Tests with live ODP server
// tests below will be skipped in CI (travis/actions) since they use the live ODP server.
#if DEBUG

extension OdpEventApiManagerTests {
    
    var odpApiKey: String { return "W4WzcEs-ABgXorzY7h1LCQ" }
    var odpApiHost: String { return "https://api.zaius.com" }
    var odpValidUserId: String { return "tester-101"}
    
    func testLiveOdpRest() {
        let manager = OdpEventApiManager()
        
        let sem = DispatchSemaphore(value: 0)
        manager.sendOdpEvents(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              events: [OdpEvent(type: "t1",
                                                action: "a1",
                                                identifiers: ["vuid": "idv1"],
                                                data: ["key1": "value1", "key2": 3.5, "key3": false, "key4": nil])]) { error in
            XCTAssertNil(error)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    func testLiveOdpRest_error() {
        let manager = OdpEventApiManager()
        
        let sem = DispatchSemaphore(value: 0)
        manager.sendOdpEvents(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              events: [OdpEvent(type: "t1",
                                                action: "a1",
                                                identifiers: [:],
                                                data: [:])]) { error in
            XCTAssertNotNil(error, "empty identifiers not allowed in ODP")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
}

#endif

// MARK: - MockOdpEventApiManager

extension OdpEventApiManagerTests {
    
    class MockOdpEventApiManager: OdpEventApiManager {
        let mockUrlSession: URLSession
        
        init(_ urlSession: URLSession) {
            mockUrlSession = urlSession
        }
        
        override func getSession() -> URLSession {
            return mockUrlSession
        }
    }
    
    class MockOdpUrlSession: URLSession {
        static var validSessions = 0
        var statusCode: Int
        var withError: Bool
        var responseData: String?
        var receivedApiRequest: URLRequest?
        
        class MockDataTask: URLSessionDataTask {
            var task: () -> Void
            
            init(_ task: @escaping () -> Void) {
                self.task = task
            }
            
            override func resume() {
                task()
            }
        }
        
        init(statusCode: Int = 0, withError: Bool = false, responseData: String? = nil) {
            Self.validSessions += 1
            self.statusCode = statusCode
            self.withError = withError
            self.responseData = responseData ?? MockOdpUrlSession.successResponseData
        }
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedApiRequest = request
            
            return MockDataTask() {
                let statusCode = self.statusCode != 0 ? self.statusCode : 200
                let response = HTTPURLResponse(url: request.url!,
                                               statusCode: statusCode,
                                               httpVersion: nil,
                                               headerFields: [String: String]())
                
                let data = self.responseData?.data(using: .utf8)
                let error = self.withError ? OptimizelyError.generic : nil
                
                completionHandler(data, response, error)
            }
        }
        
        override func finishTasksAndInvalidate() {
            Self.validSessions -= 1
        }
        
        // MARK: - Utils
        
        static let successResponseData: String = """
    {"title":"Accepted","status":202,"timestamp":"2022-07-01T16:04:06.786Z"}
    """
        
        static let failureResponseData: String = """
    {"title":"Bad Request","status":400,"timestamp":"2022-07-01T20:44:00.945Z","detail":{"invalids":[{"event":0,"message":"missing 'type' field"}]}}
    """
    }
}
