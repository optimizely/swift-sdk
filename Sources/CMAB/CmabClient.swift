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

import Foundation

enum CmabClientError: Error, Equatable {
    case fetchFailed(String)
    case invalidResponse
    
    var message: String {
        switch self {
            case .fetchFailed(let message):
                return message
            case .invalidResponse:
                return "Invalid response from CMA-B server"
            
        }
    }
}

struct CmabRetryConfig {
    var maxRetries: Int = 1
    var initialBackoff: TimeInterval = 0.1 // seconds
    var maxBackoff: TimeInterval = 10.0 // seconds
    var backoffMultiplier: Double = 2.0
}

protocol CmabClient {
    func fetchDecision(
        ruleId: String,
        userId: String,
        attributes: [String: Any?],
        cmabUUID: String,
        completion: @escaping (Result<String, Error>) -> Void
    )
}

class DefaultCmabClient: CmabClient {
    let session: URLSession
    let retryConfig: CmabRetryConfig
    let maxWaitTime: TimeInterval
    let cmabQueue = DispatchQueue(label: "com.optimizley.cmab")
    let logger = OPTLoggerFactory.getLogger()
    let predictionEndpoint: String
    
    init(session: URLSession = .shared,
         retryConfig: CmabRetryConfig = CmabRetryConfig(),
         maxWaitTime: TimeInterval = 10.0,
         predictionEndpoint: String? = nil
    ) {
        self.session = session
        self.retryConfig = retryConfig
        self.maxWaitTime = maxWaitTime
        self.predictionEndpoint = predictionEndpoint ?? CMAB_PREDICTION_END_POINT
    }
    
    func fetchDecision(
        ruleId: String,
        userId: String,
        attributes: [String: Any?],
        cmabUUID: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = getUrl(ruleId: ruleId) else {
            completion(.failure(CmabClientError.fetchFailed("Invalid CMAB prediction endpoint")))
            return
        }
        let attrType = "custom_attribute"
        let cmabAttributes = attributes.map { (key, value) in
            ["id": key, "value": value, "type": attrType]
        }
        
        let requestBody: [String: Any] = [
            "instances": [[
                "visitorId": userId,
                "experimentId": ruleId,
                "attributes": cmabAttributes,
                "cmabUUID": cmabUUID
            ]]
        ]
        
        doFetchWithRetry(
            url: url,
            requestBody: requestBody,
            timeout: maxWaitTime,
            completion: completion
        )
    }
    
    func getUrl(ruleId: String) -> URL? {
        let urlString = predictionEndpoint.hasSuffix("/") ? "predictionEndpoint\(ruleId)" : "\(predictionEndpoint)/\(ruleId)"
        guard let url = URL(string: urlString) else {
            self.logger.e("Invalid CMAB endpoint")
            return nil
        }
        return url
    }
    
    private func doFetchWithRetry(
        url: URL,
        requestBody: [String: Any],
        timeout: TimeInterval,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var attempt = 0
        var backoff = retryConfig.initialBackoff
        
        func attemptFetch() {
            doFetch(url: url, requestBody: requestBody, timeout: timeout) { result in
                switch result {
                    case .success(let variationId):
                        completion(.success(variationId))
                    case .failure(let error):
                        self.logger.e((error as? CmabClientError)?.message ?? "")
                        if let cmabError = error as? CmabClientError {
                            if case .invalidResponse = cmabError {
                                // Don't retry on invalid response
                                completion(.failure(cmabError))
                                return
                            }
                        }
                        if attempt < self.retryConfig.maxRetries {
                            attempt += 1
                            self.cmabQueue.asyncAfter(deadline: .now() + backoff) {
                                backoff = min(backoff * pow(self.retryConfig.backoffMultiplier, Double(attempt)), self.retryConfig.maxBackoff)
                                attemptFetch()
                            }
                        } else {
                            completion(.failure(CmabClientError.fetchFailed("Exhausted all retries for CMAB request. Last error: \(error)")))
                        }
                }
            }
        }
        attemptFetch()
    }
    
    private func doFetch(
        url: URL,
        requestBody: [String: Any],
        timeout: TimeInterval,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: []) else {
            completion(.failure(CmabClientError.fetchFailed("Failed to encode request body")))
            return
        }
        request.httpBody = httpBody
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(CmabClientError.fetchFailed(error.localizedDescription)))
                return
            }
            guard let httpResponse = response as? HTTPURLResponse, let data = data, (200...299).contains(httpResponse.statusCode) else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(CmabClientError.fetchFailed("HTTP error code: \(code)")))
                return
            }
            do {
                if
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    self.validateResponse(body: json),
                    let predictions = json["predictions"] as? [[String: Any]],
                    let variationId = predictions.first?["variation_id"] as? String
                {
                    completion(.success(variationId))
                } else {
                    completion(.failure(CmabClientError.invalidResponse))
                }
            } catch {
                completion(.failure(CmabClientError.invalidResponse))
            }
        }
        task.resume()
    }
    
    private func validateResponse(body: [String: Any]) -> Bool {
        if
            let predictions = body["predictions"] as? [[String: Any]],
            predictions.count > 0,
            predictions.first?["variation_id"] != nil
        {
            return true
        }
        return false
    }
}
