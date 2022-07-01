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
    let apiHost = "https://test-host"
    
    static var createdApiRequest: URLRequest?
    
    func testFetchQualifiedSegments_success() {
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, ["a"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
        
        guard let request = ZaiusGraphQLApiManagerTests.createdApiRequest else {
            XCTFail()
            return
        }
        
        let expectedBody = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences {edges {node {name state}}}}}"
        ]
        
        XCTAssertEqual(apiHost + "/v3/graphql", request.url?.absoluteString)
        XCTAssertEqual("POST", request.httpMethod)
        XCTAssertEqual(expectedBody, try! JSONDecoder().decode([String: String].self, from: request.httpBody!))
        XCTAssertEqual("application/json", request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(apiKey, request.value(forHTTPHeaderField: "x-api-key"))
    }
    
    func testFetchQualifiedSegments_successWithEmptySegments() {
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodEmptyResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: []) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, [])
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
            if case .fetchSegmentsFailed("segments not in json") = error {
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
            if case .fetchSegmentsFailed("download failed") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            XCTAssertNil(segments)
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testGraphQLRequest_subsetSegments() {
        let api = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200))
        
        let sem = DispatchSemaphore(value: 0)
        api.fetchSegments(apiKey: apiKey,
                          apiHost: apiHost,
                          userKey: userKey,
                          userValue: userValue,
                          segmentsToCheck: ["a", "b"]) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
        
        guard let request = ZaiusGraphQLApiManagerTests.createdApiRequest else {
            XCTFail()
            return
        }
        
        let expectedBody = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences(subset:[\"a\",\"b\"]) {edges {node {name state}}}}}"
        ]
        
        XCTAssertEqual(expectedBody, try! JSONDecoder().decode([String: String].self, from: request.httpBody!))
    }
    
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
    
    // MARK: - MockZaiusApiManager
    
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
        
        static let goodErrorResponseData: String = """
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
        
        static let badResponseData: String = """
        {
            "data": {}
        }
        """
        
    }
    
}
