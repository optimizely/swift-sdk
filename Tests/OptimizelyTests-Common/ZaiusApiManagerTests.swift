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

class ZaiusApiManagerTests: XCTestCase {
    
    // TODO: currently "vuid" only supported
    //var userKey = "test-user-key"
    let userKey = "vuid"
    
    let userValue = "test-user-value"
    let apiKey = "test-api-key"
    
    static var createdApiRequest: URLRequest?
    
    func testFetchQualifiedSegments_success() {
        let manager = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: apiKey, userKey: userKey, userValue: userValue, segmentsToCheck: nil) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, ["qualified-and-ready"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_successWithEmptySegments() {
        let manager = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.goodEmptyResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: apiKey, userKey: userKey, userValue: userValue, segmentsToCheck: nil) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, [])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_badResponse() {
        let manager = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200, responseData: MockZaiusUrlSession.badResponseData))
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: apiKey, userKey: userKey, userValue: userValue, segmentsToCheck: nil) { segments, error in
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
        let manager = MockZaiusApiManager(MockZaiusUrlSession(withError: true))
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: apiKey, userKey: userKey, userValue: userValue, segmentsToCheck: nil) { segments, error in
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
            
    func testGraphQLRequest_allSegments() {
        let manager = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200))

        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: apiKey, userKey: userKey, userValue: userValue, segmentsToCheck: nil) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))

        guard let request = ZaiusApiManagerTests.createdApiRequest else {
            XCTFail()
            return
        }
        
        let expectedBody = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences {edges {node {name is_ready state}}}}}"
        ]
        
        XCTAssertEqual("POST", request.httpMethod)
        XCTAssertEqual(expectedBody, try! JSONDecoder().decode([String: String].self, from: request.httpBody!))
        XCTAssertEqual("application/json", request.value(forHTTPHeaderField: "Content-Type"))
        XCTAssertEqual(apiKey, request.value(forHTTPHeaderField: "x-api-key"))
    }
    
    func testGraphQLRequest_subsetSegments() {
        let manager = MockZaiusApiManager(MockZaiusUrlSession(statusCode: 200))

        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: apiKey, userKey: userKey, userValue: userValue, segmentsToCheck: ["a", "b"]) { _, _ in
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))

        guard let request = ZaiusApiManagerTests.createdApiRequest else {
            XCTFail()
            return
        }
        
        let expectedBody = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences(subset:[\"a\",\"b\"]) {edges {node {name is_ready state}}}}}"
        ]
        
        XCTAssertEqual(expectedBody, try! JSONDecoder().decode([String: String].self, from: request.httpBody!))
    }

    func testMakeSubsetFilter() {
        let manager = ZaiusApiManager()

        XCTAssertEqual("", manager.makeSubsetFilter(segments: nil))
        XCTAssertEqual("(subset:[])", manager.makeSubsetFilter(segments: []))
        XCTAssertEqual("(subset:[\"a\"])", manager.makeSubsetFilter(segments: ["a"]))
        XCTAssertEqual("(subset:[\"a\",\"b\",\"c\"])",manager.makeSubsetFilter(segments: ["a", "b", "c"]))
    }
    
    func testExtractComponent() {
        let dict = ["a": ["b": ["c": "v"]]]
        XCTAssertEqual(["b": ["c": "v"]], dict.extractComponent(keyPath: "a"))
        XCTAssertEqual(["c": "v"], dict.extractComponent(keyPath: "a.b"))
        XCTAssertEqual("v", dict.extractComponent(keyPath: "a.b.c"))
        XCTAssertNil(dict.extractComponent(keyPath: "a.b.c.d"))
        XCTAssertNil(dict.extractComponent(keyPath: "d"))
    }
    
    // MARK: - Tests with real ODP server
    
    // TODO: this test can be flaky. replace it with a good test account or remove it later.
    
    func testLiveODPGraphQL() {
        let testODPApiKeyForAudienceSegments = "W4WzcEs-ABgXorzY7h1LCQ"
        let testODPUserIdForAudienceSegments = "d66a9d81923d4d2f99d8f64338976322"

        let manager = ZaiusApiManager()
        
        let sem = DispatchSemaphore(value: 0)
        manager.fetch(apiKey: testODPApiKeyForAudienceSegments,
                      userKey: "vuid",
                      userValue: testODPUserIdForAudienceSegments,
                      segmentsToCheck: ["has_email", "has_email_opted_in", "invalid-segment"]) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(Set(["has_email", "has_email_opted_in"]), Set(segments!))
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(30)))
    }
    
    // MARK: - MockZaiusApiManager
    
    class MockZaiusApiManager: ZaiusApiManager {
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
            ZaiusApiManagerTests.createdApiRequest = request
            
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
                                    "name": "qualified-and-ready",
                                    "is_ready": true,
                                    "state": "qualified",
                                    "description": "qualifed and ready"
                                }
                            },
                            {
                                "node": {
                                    "name": "qualified-and-not-ready",
                                    "is_ready": false,
                                    "state": "qualified",
                                    "description": "qualified and not-ready"
                                }
                            },
                            {
                                "node": {
                                    "name": "not-qualified-and-ready",
                                    "is_ready": false,
                                    "state": "qualified",
                                    "description": "not-qualified and ready"
                                }
                            },
                            {
                                "node": {
                                    "name": "not-qualified-and-not-ready",
                                    "is_ready": false,
                                    "state": "qualified",
                                    "description": "not-qualified and not-ready"
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
        
        static let badResponseData: String = """
        {
            "data": {}
        }
        """
        
    }
    
}
