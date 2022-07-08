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

class ZaiusRestApiManagerTests: XCTestCase {
    let userKey = "vuid"
    let userValue = "test-user-value"
    let apiKey = "test-api-key"
    let apiHost = "test-host"
    
    let events: [OdpEvent] = [
        OdpEvent(type: "t1", action: "a1", identifiers: ["id-key-1": "id-value-1"], data: ["key-1": "value-1"]),
        OdpEvent(type: "t2", action: "a2", identifiers: ["id-key-2": "id-value-2"], data: ["key-2": "value-2"])
    ]
    
    func testSendOdpEvents_validRequest() {
        let session = MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.successResponseData)
        let api = MockZaiusApiManager(session)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { _ in }

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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200,
                                                          responseData: MockZaiusUrlSession.successResponseData))
        let sem = DispatchSemaphore(value: 0)
        api.sendOdpEvents(apiKey: apiKey, apiHost: apiHost, events: events) { error in
            XCTAssertNil(error)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testSendOdpEvents_networkError_retry() {
        let api = MockZaiusApiManager(MockZaiusUrlSession(withError: true))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 400, responseData: MockZaiusUrlSession.failureResponseData))

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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 500, responseData: "server error"))

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

    // MARK: - MockZaiusApiManager
    
    class MockZaiusApiManager: ZaiusRestApiManager {
        let mockUrlSession: URLSession
        
        init(_ urlSession: URLSession) {
            mockUrlSession = urlSession
        }
        
        override func getSession() -> URLSession {
            return mockUrlSession
        }
        
        override func sendOdpEvents(apiKey: String, apiHost: String, events: [OdpEvent], completionHandler: @escaping (OptimizelyError?) -> Void) {
        }
    }
    
    // MARK: - MockZaiusUrlSession
    
    class MockZaiusUrlSession: URLSession {
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
            self.responseData = responseData ?? MockZaiusUrlSession.successResponseData
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
