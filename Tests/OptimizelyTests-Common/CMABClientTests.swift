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

class DefaultCmabClientTests: XCTestCase {
    var client: DefaultCmabClient!
    var mockSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        client = DefaultCmabClient(session: mockSession)
    }
    
    override func tearDown() {
        client = nil
        mockSession = nil
        super.tearDown()
    }
    
    func testFetchDecisionSuccess() {
        let expectedVariationId = "variation-123"
        let responseJSON: [String: Any] = [
            "predictions": [
                ["variation_id": expectedVariationId]
            ]
        ]
        let responseData = try! JSONSerialization.data(withJSONObject: responseJSON, options: [])
        mockSession.nextData = responseData
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                   statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.nextError = nil
        
        let expectation = self.expectation(description: "Completion called")
        
        client.fetchDecision(
            ruleId: "abc",
            userId: "user1",
            attributes: ["foo": "bar"],
            cmabUUID: "uuid"
        ) { result in
            switch result {
                case .success(let variationId):
                    XCTAssertEqual(variationId, expectedVariationId)
                case .failure(let error):
                    XCTFail("Expected success, got failure: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFetchDecisionHttpError() {
        mockSession.nextData = Data()
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                   statusCode: 500, httpVersion: nil, headerFields: nil)
        mockSession.nextError = nil
        
        let expectation = self.expectation(description: "Completion called")
        
        client.fetchDecision(
            ruleId: "abc",
            userId: "user1",
            attributes: ["foo": "bar"],
            cmabUUID: "uuid"
        ) { result in
            switch result {
                case .success(_):
                    XCTFail("Expected failure, got success")
                case .failure(let error):
                    XCTAssertTrue("\(error)".contains("HTTP error code"))
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFetchDecisionInvalidJson() {
        mockSession.nextData = Data("not a json".utf8)
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                   statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.nextError = nil
        
        let expectation = self.expectation(description: "Completion called")
        
        client.fetchDecision(
            ruleId: "abc",
            userId: "user1",
            attributes: ["foo": "bar"],
            cmabUUID: "uuid"
        ) { result in
            switch result {
                case .success(_):
                    XCTFail("Expected failure, got success")
                case .failure(let error):
                    XCTAssertTrue(error is CmabClientError)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFetchDecisionInvalidResponseStructure() {
        let responseJSON: [String: Any] = [
            "not_predictions": []
        ]
        let responseData = try! JSONSerialization.data(withJSONObject: responseJSON, options: [])
        mockSession.nextData = responseData
        mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                   statusCode: 200, httpVersion: nil, headerFields: nil)
        mockSession.nextError = nil
        
        let expectation = self.expectation(description: "Completion called")
        
        client.fetchDecision(
            ruleId: "abc",
            userId: "user1",
            attributes: ["foo": "bar"],
            cmabUUID: "uuid"
        ) { result in
            switch result {
                case .success(_):
                    XCTFail("Expected failure, got success")
                case .failure(let error):
                    XCTAssertEqual(error as? CmabClientError, .invalidResponse)
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testFetchDecisionRetriesOnFailure() {
        let expectedVariationId = "variation-retry"
        var callCount = 0
        
        let responseJSON: [String: Any] = [
            "predictions": [
                ["variation_id": expectedVariationId]
            ]
        ]
        let responseData = try! JSONSerialization.data(withJSONObject: responseJSON, options: [])
        
        mockSession.onRequest = { _ in
            callCount += 1
            if callCount == 1 {
                self.mockSession.nextData = Data()
                self.mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                                statusCode: 500, httpVersion: nil, headerFields: nil)
                self.mockSession.nextError = nil
            } else {
                self.mockSession.nextData = responseData
                self.mockSession.nextResponse = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                                statusCode: 200, httpVersion: nil, headerFields: nil)
                self.mockSession.nextError = nil
            }
        }
        
        let expectation = self.expectation(description: "Completion called")
        
        client.fetchDecision(
            ruleId: "abc",
            userId: "user1",
            attributes: ["foo": "bar"],
            cmabUUID: "uuid"
        ) { result in
            switch result {
                case .success(let variationId):
                    XCTAssertEqual(variationId, expectedVariationId)
                    XCTAssertTrue(callCount >= 2)
                case .failure(let error):
                    XCTFail("Expected success, got failure: \(error)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3, handler: nil)
    }
}

extension DefaultCmabClientTests {
    class MockURLSessionDataTask: URLSessionDataTask {
        private let closure: () -> Void
        override var state: URLSessionTask.State { .completed }
        init(closure: @escaping () -> Void) {
            self.closure = closure
        }
        
        override func resume() {
            closure()
        }
    }
    
    class MockURLSession: URLSession {
        typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
        
        var nextData: Data?
        var nextResponse: URLResponse?
        var nextError: Error?
        var onRequest: ((URLRequest) -> Void)?
        
        override func dataTask(
            with request: URLRequest,
            completionHandler: @escaping CompletionHandler
        ) -> URLSessionDataTask {
            onRequest?(request)
            return MockURLSessionDataTask {
                completionHandler(self.nextData, self.nextResponse, self.nextError)
            }
        }
    }

}
