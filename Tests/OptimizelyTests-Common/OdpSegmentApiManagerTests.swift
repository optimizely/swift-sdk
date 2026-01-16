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

class OdpSegmentApiManagerTests: XCTestCase {
    let userKey = "vuid"
    let userValue = "test-user-value"
    let apiKey = "test-api-key"
    let apiHost = "test-host"
    
    static var createdApiRequest: URLRequest?
    
    // MARK: - Request

    func testFetchQualifiedSegments_validRequest() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.goodResponseData))
        
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: ["a", "b", "c"]) {_,_ in }
        
        let request = OdpSegmentApiManagerTests.createdApiRequest!
        let expectedBody: [String: Any] = [
            "query": "query($userId: String, $audiences: [String]) {customer(\(userKey): $userId) {audiences(subset: $audiences) {edges {node {name state}}}}}",
            "variables": [
                "userId": userValue,
                "audiences": ["a", "b", "c"]
            ]
        ]

        XCTAssertEqual(apiHost + "/v3/graphql", request.url?.absoluteString)
        XCTAssertEqual("POST", request.httpMethod)
        XCTAssertEqual("application/json", request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(apiKey, request.value(forHTTPHeaderField: "x-api-key"))
        
        let requestDict = try? JSONSerialization.jsonObject(with: request.httpBody!) as? [String: Any]
        XCTAssert(OTUtils.compareDictionaries(expectedBody, requestDict!))
    }

    // MARK: - Success

    func testFetchQualifiedSegments_success() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.goodResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: ["a", "b", "c"]) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, ["a"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_successWithEmptySegments() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.goodEmptyResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: ["a", "b", "c"]) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, [])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    // MARK: - Failure
    
    func testFetchQualifiedSegments_invalidIdentifier() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.invalidIdentifierResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            if case .invalidSegmentIdentifier = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }

    func testFetchQualifiedSegments_otherException() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.otherExceptionResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            if case .fetchSegmentsFailed("TestExceptionClass") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }

    func testFetchQualifiedSegments_badResponse() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 200, responseData: MockOdpUrlSession.badResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            if case .fetchSegmentsFailed("decode error") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_networkError() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(withError: true))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            if case .fetchSegmentsFailed("network error") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_400() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 403, responseData: "Bad Request"))

        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            if case .fetchSegmentsFailed("403") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }

    func testFetchQualifiedSegments_500() {
        let api = MockOdpSegmentApiManager(MockOdpUrlSession(statusCode: 500, responseData: "Server Error"))

        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            if case .fetchSegmentsFailed("500") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    // MARK: - timeout
    
    func testTimeout() {
        let api = OdpSegmentApiManager(timeout: 3)
        XCTAssertEqual(3, api.getSession().configuration.timeoutIntervalForResource)
    }
    
    func testTimeout_useOSDefaultIfTimeoutIsNotProvided() {
        let api = OdpSegmentApiManager()
        XCTAssertEqual(604800, api.getSession().configuration.timeoutIntervalForResource)
    }

    // MARK: - Others
    
    func testMakeQuery() {
        let api = OdpSegmentApiManager()
        
        let inputsForSegmentsToCheck = [
            [],
            ["a", "b"]
        ]
        
        let template = "query($userId: String, $audiences: [String]) {customer(key-1: $userId) {audiences(subset: $audiences) {edges {node {name state}}}}}"
        let expectedBody = [
            [
                "query": template,
                "variables":[ "audiences": [], "userId":"value-1"]
            ],
            [
                "query": template,
                "variables":[ "audiences": ["a", "b"], "userId":"value-1"]
            ]
        ]
        
        for i in inputsForSegmentsToCheck.indices {
            let query = api.makeQuery(userKey: "key-1", userValue: "value-1", segmentsToCheck: inputsForSegmentsToCheck[i])
            XCTAssert(OTUtils.compareDictionaries(expectedBody[i], query))
        }
    }
    
    func testExtractComponent() {
        let dict = ["a": ["b": ["c": "v"]]]
        XCTAssertEqual(["b": ["c": "v"]], dict.extractComponent(keyPath: "a"))
        XCTAssertEqual(["c": "v"], dict.extractComponent(keyPath: "a.b"))
        XCTAssertEqual("v", dict.extractComponent(keyPath: "a.b.c"))
        XCTAssertNil(dict.extractComponent(keyPath: "a.b.c.d"))
        XCTAssertNil(dict.extractComponent(keyPath: "d"))
    }
    
}

// MARK: - Tests with live ODP server
// tests below will be skipped in CI (travis/actions) since they use the live ODP server.
#if DEBUG

extension OdpSegmentApiManagerTests {
    
    var odpApiKey: String { return "W4WzcEs-ABgXorzY7h1LCQ" }
    var odpApiHost: String { return "https://api.zaius.com" }
    var odpValidUserId: String { return "tester-101"}

    func testLiveOdpGraphQL() {
        let manager = OdpSegmentApiManager()
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetchSegments(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              userKey: "fs_user_id",
                              userValue: odpValidUserId,
                              segmentsToCheck: ["segment-1"]) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual([], segments, "none of the test segments in the live ODP server")
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    func testLiveOdpGraphQL_defaultParameters_userNotRegistered() {
        let manager = OdpSegmentApiManager()

        let sem = DispatchSemaphore(value: 0)
        manager.fetchSegments(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              userKey: "fs_user_id",
                              userValue: "not-registered-user-1",
                              segmentsToCheck: ["segment-1"]) { segments, error in
            // API behavior has changed - now returns empty array instead of error for unregistered users
            // Accept both old error response and new empty array response
            if let error = error {
                if case .invalidSegmentIdentifier = error {
                    XCTAssert(true)

                // [TODO] ODP server will fix to add this "InvalidSegmentIdentifier" later.
                //        Until then, use the old error format ("DataFetchingException").

                } else if case .fetchSegmentsFailed("DataFetchingException") = error {
                    XCTAssert(true)
                } else {
                    XCTFail("Unexpected error type: \(error)")
                }
                XCTAssertNil(segments)
            } else {
                // New API behavior: returns empty array for unregistered users
                XCTAssertNotNil(segments)
                XCTAssertEqual(segments, [], "Expected empty array for unregistered user")
            }
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
}

#endif

// MARK: - MockOdpSegmentApiManager

extension OdpSegmentApiManagerTests {
    
    class MockOdpSegmentApiManager: OdpSegmentApiManager {
        let mockUrlSession: URLSession
        
        init(_ urlSession: URLSession) {
            mockUrlSession = urlSession
        }
        
        override func getSession() -> URLSession {
            return mockUrlSession
        }
    }
    
    // MARK: - MockOdpUrlSession
    
    class MockOdpUrlSession: URLSession {
        static var validSessions = 0
        var statusCode: Int
        var withError: Bool
        var responseData: String?
        
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
            self.responseData = responseData ?? MockOdpUrlSession.goodResponseData
        }
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            OdpSegmentApiManagerTests.createdApiRequest = request
            
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
        
        static let goodResponseData: String = """
    {
        "data": {
            "customer": {
                "audiences": {
                    "edges": [
                        {
                            "node": {
                                "name": "a",
                                "state": "qualified",
                                "description": "qualifed sample"
                            }
                        },
                        {
                            "node": {
                                "name": "b",
                                "state": "not_qualified",
                                "description": "not-qualified sample"
                            }
                        }
                    ]
                }
            }
        }
    }
    """
        
        static let goodEmptyResponseData: String = """
    {
        "data": {
            "customer": {
                "audiences": {
                    "edges": []
                }
            }
        }
    }
    """
        
        static let invalidIdentifierResponseData: String = """
    {
      "errors": [
        {
          "message": "Exception while fetching data (/customer) : java.lang.RuntimeException: could not resolve _fs_user_id = asdsdaddddd",
          "locations": [
            {
              "line": 2,
              "column": 3
            }
          ],
          "path": [
            "customer"
          ],
          "extensions": {
            "code": "INVALID_IDENTIFIER_EXCEPTION",
            "classification": "DataFetchingException"
          }
        }
      ],
      "data": {
        "customer": null
      }
    }
    """
        
        static let otherExceptionResponseData: String = """
    {
      "errors": [
        {
          "message": "Exception while fetching data (/customer) : java.lang.RuntimeException: could not resolve _fs_user_id = asdsdaddddd",
          "extensions": {
            "classification": "TestExceptionClass"
          }
        }
      ],
      "data": {
        "customer": null
      }
    }
    """
        
        static let badResponseData: String = """
    {
        "data": {}
    }
    """
    }
}
