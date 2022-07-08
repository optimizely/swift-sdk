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

class ZaiusGraphQLApiManagerTests: XCTestCase {
    let userKey = "vuid"
    let userValue = "test-user-value"
    let apiKey = "test-api-key"
    let apiHost = "test-host"
    
    static var createdApiRequest: URLRequest?
    
    // MARK: - Request

    func testFetchQualifiedSegments_validRequest() {
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodResponseData))
        
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: ["a", "b", "c"]) {_,_ in }
        
        let request = ZaiusGraphQLApiManagerTests.createdApiRequest!
        let expectedBody = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences(subset:[\"a\",\"b\",\"c\"]) {edges {node {name state}}}}}"
        ]

        XCTAssertEqual(apiHost + "/v3/graphql", request.url?.absoluteString)
        XCTAssertEqual("POST", request.httpMethod)
        XCTAssertEqual(expectedBody, try! JSONDecoder().decode([String: String].self, from: request.httpBody!))
        XCTAssertEqual("application/json", request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(apiKey, request.value(forHTTPHeaderField: "x-api-key"))
    }

    // MARK: - Success

    func testFetchQualifiedSegments_success() {
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodResponseData))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodEmptyResponseData))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.invalidIdentifierResponseData))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.otherExceptionResponseData))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.badResponseData))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(withError: true))
        
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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 403, responseData: "Bad Request"))

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
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 500, responseData: "Server Error"))

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
    
    // MARK: - Others
    
    func testMakeSubsetFilter() {
        let api = ZaiusGraphQLApiManager()
        
        XCTAssertEqual("(subset:[])", api.makeSubsetFilter(segments: []))
        XCTAssertEqual("(subset:[\"a\"])", api.makeSubsetFilter(segments: ["a"]))
        XCTAssertEqual("(subset:[\"a\",\"b\",\"c\"])",api.makeSubsetFilter(segments: ["a", "b", "c"]))
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

extension ZaiusGraphQLApiManagerTests {
    
    var odpApiKey: String { return "W4WzcEs-ABgXorzY7h1LCQ" }
    var odpApiHost: String { return "https://api.zaius.com" }
    var odpValidUserId: String { return "tester-101"}

    func testLiveOdpGraphQL() {
        let manager = ZaiusGraphQLApiManager()
        
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
        let manager = ZaiusGraphQLApiManager()
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetchSegments(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              userKey: "fs_user_id",
                              userValue: "not-registered-user",
                              segmentsToCheck: ["segment-1"]) { segments, error in
            if case .invalidSegmentIdentifier = error {
                XCTAssert(true)
            
            // [TODO] ODP server will fix to add this "InvalidSegmentIdentifier" later.
            //        Until then, use the old error format ("DataFetchingException").
                
            } else if case .fetchSegmentsFailed("DataFetchingException") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
}

#endif

// MARK: - MockZaiusApiManager

extension ZaiusGraphQLApiManagerTests {
    
    class MockZaiusApiManager: ZaiusGraphQLApiManager {
        let mockUrlSession: URLSession
        
        init(_ urlSession: URLSession) {
            mockUrlSession = urlSession
        }
        
        override func getSession() -> URLSession {
            return mockUrlSession
        }
    }
    
    // MARK: - MockZaiusUrlSession
    
    class MockZaiusUrlSession: URLSession {
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
            self.responseData = responseData ?? MockZaiusUrlSession.goodResponseData
        }
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            ZaiusGraphQLApiManagerTests.createdApiRequest = request
            
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
            "classification": "InvalidIdentifierException"
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