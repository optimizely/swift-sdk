//
// Copyright 2025, Optimizely, Inc. and contributors 
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
    var shortRetryConfig: CmabRetryConfig!
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        shortRetryConfig = CmabRetryConfig(maxRetries: 2, initialBackoff: 0.01, maxBackoff: 0.05, backoffMultiplier: 1.0)
        client = DefaultCmabClient(session: mockSession, retryConfig: shortRetryConfig)
    }
    
    override func tearDown() {
        client = nil
        mockSession = nil
        shortRetryConfig = nil
        super.tearDown()
    }
    
    // MARK: - Helpers
    
    func makeSuccessResponse(variationId: String) -> (Data, URLResponse, Error?) {
        let json: [String: Any] = [
            "predictions": [
                ["variation_id": variationId]
            ]
        ]
        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        let response = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                       statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (data, response, nil)
    }
    
    func makeFailureResponse() -> (Data, URLResponse, Error?) {
        let response = HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                       statusCode: 500, httpVersion: nil, headerFields: nil)!
        return (Data(), response, nil)
    }
    
    // MARK: - Test Cases
    
    func testFetchDecision_SuccessOnFirstTry() {
        let (successData, successResponse, _) = makeSuccessResponse(variationId: "variation-123")
        mockSession.responses = [(successData, successResponse, nil)]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"], 
            cmabUUID: "uuid"
        ) { result in
            if case let .success(variationId) = result {
                XCTAssertEqual(variationId, "variation-123")
                XCTAssertEqual(self.mockSession.callCount, 1)
            } else {
                XCTFail("Expected success result")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testFetchDecision_SuccessOnSecondTry() {
        let (successData, successResponse, _) = makeSuccessResponse(variationId: "variation-retry")
        let fail = makeFailureResponse()
        mockSession.responses = [fail, (successData, successResponse, nil)]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"], 
            cmabUUID: "uuid"
        ) { result in
            if case let .success(variationId) = result {
                XCTAssertEqual(variationId, "variation-retry")
                XCTAssertEqual(self.mockSession.callCount, 2)
            } else {
                XCTFail("Expected success after retry")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testFetchDecision_SuccessOnThirdTry() {
        let (successData, successResponse, _) = makeSuccessResponse(variationId: "success-third")
        let fail = makeFailureResponse()
        mockSession.responses = [fail, fail, (successData, successResponse, nil)]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"], 
            cmabUUID: "uuid"
        ) { result in
            if case let .success(variationId) = result {
                XCTAssertEqual(variationId, "success-third")
                XCTAssertEqual(self.mockSession.callCount, 3)
            } else {
                XCTFail("Expected success after two retries")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testFetchDecision_ExhaustsAllRetries() {
        let fail = makeFailureResponse()
        mockSession.responses = [fail, fail, fail]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"], 
            cmabUUID: "uuid"
        ) { result in
            if case let .failure(error) = result {
                XCTAssertTrue("\(error)".contains("Exhausted all retries"))
                XCTAssertEqual(self.mockSession.callCount, 3)
            } else {
                XCTFail("Expected failure after all retries")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testFetchDecision_HttpError() {
        mockSession.responses = [
            (Data(), HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                     statusCode: 500, httpVersion: nil, headerFields: nil), nil)
        ]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"], 
            cmabUUID: "uuid"
        ) { result in
            if case let .failure(error) = result {
                XCTAssertTrue("\(error)".contains("HTTP error code"))
            } else {
                XCTFail("Expected failure on HTTP error")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testFetchDecision_InvalidJson() {
        mockSession.responses = [
            (Data("not a json".utf8), HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                                      statusCode: 200, httpVersion: nil, headerFields: nil), nil)
        ]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"], 
            cmabUUID: "uuid"
        ) { result in
            if case let .failure(error) = result {
                XCTAssertTrue(error is CmabClientError)
                XCTAssertEqual(self.mockSession.callCount, 1)
            } else {
                XCTFail("Expected failure on invalid JSON")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
    }
    
    func testFetchDecision_Invalid_Response_Structure() {
        let responseJSON: [String: Any] = [ "not_predictions": [] ]
        let responseData = try! JSONSerialization.data(withJSONObject: responseJSON, options: [])
        mockSession.responses = [
            (responseData, HTTPURLResponse(url: URL(string: "https://prediction.cmab.optimizely.com/predict/abc")!,
                                           statusCode: 200, httpVersion: nil, headerFields: nil), nil)
        ]
        
        let expectation = self.expectation(description: "Completion called")
        client.fetchDecision(
            ruleId: "abc", userId: "user1",
            attributes: ["foo": "bar"],
            cmabUUID: "uuid-1234"
        ) { result in
            if case let .failure(error) = result {
                XCTAssertEqual(error as? CmabClientError, .invalidResponse)
                XCTAssertEqual(self.mockSession.callCount, 1)
            } else {
                XCTFail("Expected failure on invalid response structure")
            }
            self.verifyRequest(ruleId: "abc", userId: "user1", attributes: ["foo": "bar"], cmabUUID: "uuid-1234")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)
        
    }
    
    private func verifyRequest(ruleId: String, userId: String, attributes: [String: Any], cmabUUID: String) {
        // Assert request body
        guard let request = mockSession.lastRequest else {
            XCTFail("No request was sent")
            return
        }
        guard let body = request.httpBody else {
            XCTFail("No HTTP body in request")
            return
        }
        
        let json = try! JSONSerialization.jsonObject(with: body, options: []) as! [String: Any]
        let instances = json["instances"] as? [[String: Any]]
        XCTAssertNotNil(instances)
        let instance = instances?.first
        XCTAssertEqual(instance?["visitorId"] as? String, userId)
        XCTAssertEqual(instance?["experimentId"] as? String, ruleId)
        XCTAssertEqual(instance?["cmabUUID"] as? String, cmabUUID)
        // You can add further assertions for the attributes, e.g.:
        let payloadAttributes = instance?["attributes"] as? [[String: Any]]
        XCTAssertEqual(payloadAttributes?.first?["id"] as? String, attributes.keys.first)
        XCTAssertEqual(payloadAttributes?.first?["value"] as? String, attributes.values.first as? String)
        XCTAssertEqual(payloadAttributes?.first?["type"] as? String, "custom_attribute")
    }
    
}

// MARK: - MockURLSession for ordered responses

extension DefaultCmabClientTests {
    class MockURLSessionDataTask: URLSessionDataTask {
        private let closure: () -> Void
        override var state: URLSessionTask.State { .completed }
        init(closure: @escaping () -> Void) { self.closure = closure }
        override func resume() { closure() }
    }
    
    class MockURLSession: URLSession {
        typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
        var responses: [(Data?, URLResponse?, Error?)] = []
        var callCount = 0
        var lastRequest: URLRequest?
       
        override func dataTask(
            with request: URLRequest,
            completionHandler: @escaping CompletionHandler
        ) -> URLSessionDataTask {
            self.lastRequest = request
            let idx = callCount
            callCount += 1
            let tuple = idx < responses.count ? responses[idx] : (nil, nil, nil)
            return MockURLSessionDataTask { completionHandler(tuple.0, tuple.1, tuple.2) }
        }
    }
}
