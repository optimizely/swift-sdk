//
// Copyright 2022-2023, Optimizely, Inc. and contributors
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

// ODP REST Events API
// - https://api.zaius.com/v3/events
// - test ODP public API key = "W4WzcEs-ABgXorzY7h1LCQ"

/*
 [Event Request]

 curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"type":"fullstack","action":"identified","identifiers":{"vuid": "123","fs_user_id": "abc"},"data":{"idempotence_id":"xyz","source":"swift-sdk"}}' https://api.zaius.com/v3/events

 [Event Response]

 {"title":"Accepted","status":202,"timestamp":"2022-06-30T20:59:52.046Z"}
*/

public class OdpEventApiManager {
    let resourceTimeoutInSecs: Int?

    /// OdpEventApiManager init
    /// - Parameters:
    ///   - timeout: timeout for segment fetch
    public init(timeout: Int? = nil) {
        self.resourceTimeoutInSecs = timeout
    }

    func sendOdpEvents(apiKey: String,
                       apiHost: String,
                       events: [OdpEvent],
                       completionHandler: @escaping (OptimizelyError?) -> Void) {
        guard let url = URL(string: "\(apiHost)/v3/events") else {
            let canRetry = false
            completionHandler(.odpEventFailed("Invalid url", canRetry))
            return
        }
        
        guard let body = try? JSONSerialization.data(withJSONObject: events.map { $0.dict }) else {
            let canRetry = false
            completionHandler(.odpEventFailed("Invalid JSON", canRetry))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let session = self.getSession()
        // without this the URLSession will leak, see docs on URLSession and https://stackoverflow.com/questions/67318867
        defer { session.finishTasksAndInvalidate() }

        let task = session.dataTask(with: urlRequest) { data, response, error in
            var errMessage: String?
            var canRetry: Bool = true
            
            defer {
                if let errMessage = errMessage {
                    completionHandler(.odpEventFailed(errMessage, canRetry))
                } else {
                    completionHandler(nil)
                }
            }
            
            if let error = error {
                errMessage = error.localizedDescription
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                errMessage = "invalid response"
                return
            }
            
            var dataStr: String?
            if let data = data, let str = String(bytes: data, encoding: .utf8) {
                dataStr = str
            }
            
            switch response.statusCode {
            case ..<400:
                errMessage = nil    // success
            case 400..<500:
                errMessage = dataStr ?? "\(response.statusCode)"
                canRetry = false   // no retry (client error)
            default:
                errMessage = "\(response.statusCode)"
            }
        }
        
        task.resume()
    }

    open func getSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        if let timeout = resourceTimeoutInSecs, timeout > 0 {
            config.timeoutIntervalForResource = TimeInterval(timeout)
        }
        return URLSession(configuration: config)
    }

}
