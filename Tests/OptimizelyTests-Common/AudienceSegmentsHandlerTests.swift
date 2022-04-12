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

class AudienceSegmentsHandlerTests: XCTestCase {
    var handler = DefaultAudienceSegmentsHandler()
    
    // TODO: currently "vuid" only supported
    //var userKey = "test-user-key"
    var userKey = "vuid"
    
    var userValue = "test-user-value"
    var apiKey = "test-api-key"
    
    override func setUp() {
    }

    func testFetchQualifiedSegments_success() {
        handler.zaiusMgr = MockZaiusApiManager(statusCode: 200)
        
        let sem = DispatchSemaphore(value: 0)
        handler.fetchQualifiedSegments(apiKey: apiKey, userKey: userKey, userValue: userValue,
                                       segmentsToCheck: nil, options: []) { segments, error in
            XCTAssertNil(error)
            XCTAssertEqual(segments, ["qualified-and-ready"])
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_networkError() {
        handler.zaiusMgr = MockZaiusApiManager(withError: true)
        
        let sem = DispatchSemaphore(value: 0)
        handler.fetchQualifiedSegments(apiKey: apiKey, userKey: userKey, userValue: userValue,
                                       segmentsToCheck: nil, options: []) { _, error in
            if case .fetchSegmentsFailed("download failed") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
    func testFetchQualifiedSegments_decodeError() {
        handler.zaiusMgr = MockZaiusApiManager(statusCode: 200, responseData: "invalid-json")

        let sem = DispatchSemaphore(value: 0)
        handler.fetchQualifiedSegments(apiKey: apiKey, userKey: userKey, userValue: userValue,
                                       segmentsToCheck: nil, options: []) { _, error in
            if case .fetchSegmentsFailed("decode error") = error {
                XCTAssert(true)
            } else {
                XCTFail()
            }
            sem.signal()
        }
        XCTAssertEqual(.success, sem.wait(timeout: .now() + .seconds(1)))
    }
    
}

// MARK: - MockZaiusApiManager

class MockZaiusApiManager: ZaiusApiManager {
    let mockUrlSession: MockZaiusUrlSession

    init(statusCode: Int = 0, withError: Bool = false, responseData: String? = nil) {
        mockUrlSession = MockZaiusUrlSession(statusCode: statusCode, withError: withError, responseData: responseData)
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
    
    init(statusCode: Int, withError: Bool, responseData: String?) {
        Self.validSessions += 1
        self.statusCode = statusCode
        self.withError = withError
        self.responseData = responseData ?? MockZaiusUrlSession.goodResponseData
    }
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        let headers = [String: String]()
        
        return MockDataTask() {
            let statusCode = self.statusCode != 0 ? self.statusCode : 200
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: statusCode,
                                           httpVersion: nil,
                                           headerFields: headers)
            
            let data = self.responseData?.data(using: .utf8)
            let error = self.withError ? OptimizelyError.generic : nil
            
            completionHandler(data, response, error)
        }
    }
    
    override func finishTasksAndInvalidate() {
        Self.validSessions -= 1
    }
    
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
}
