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

import Foundation

// MARK: - REST API

class ZaiusRestApiManager {
    
    func sendODPEvent(apiKey: String,
                      apiHost: String,
                      identifiers: [String: Any],
                      kind: String,
                      data: [String: Any] = [:],
                      completionHandler: @escaping (OptimizelyError?) -> Void) {
        let kinds = kind.split(separator: ":")
        guard kinds.count == 2 else {
            completionHandler(.odpEventFailed("Invalid format for kind"))
            return
        }
                
        guard let url = URL(string: "\(apiHost)/v3/events") else {
            completionHandler(.odpEventFailed("Invalid url"))
            return
        }
        
        let combinedData: [String: Any] = [
            "type": kinds[0],
            "action": kinds[1],
            //"data_source": "fullstack:swift-sdk",
            "identifiers": identifiers,
            "data": data
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: combinedData) else {
            completionHandler(.odpEventFailed("Invalid JSON"))
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = body
        urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.addValue("application/json", forHTTPHeaderField: "content-type")

        print("[ODP] request body: \(combinedData)")
        
        let session = self.getSession()
        // without this the URLSession will leak, see docs on URLSession and https://stackoverflow.com/questions/67318867
        defer { session.finishTasksAndInvalidate() }

        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completionHandler(.odpEventFailed(error.localizedDescription))
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 400 {
                    var message = "UNKNOWN"
                    if let data = data, let msg = String(bytes: data, encoding: .utf8) {
                        message = msg
                    }
                    completionHandler(.odpEventFailed(message))
                    return
                }
            }

            completionHandler(nil)
        }
        
        task.resume()
    }

    func getSession() -> URLSession {
        return URLSession(configuration: .ephemeral)
    }
    
}
