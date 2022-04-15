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

// ODP GraphQL API
// - https://api.zaius.com/v3/graphql

/* GraphQL Request
 
curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"query":"query {customer(vuid: \"d66a9d81923d4d2f99d8f64338976322\") {audiences {edges {node {name is_ready state}}}}}"}' https://api.zaius.com/v3/graphql
 
query MyQuery {
  customer(vuid: "d66a9d81923d4d2f99d8f64338976322") {
    audiences {
      edges {
        node {
          name
          is_ready
          state
          description
        }
      }
    }
  }
}
*/

/* GraphQL Response
 
 {
   "data": {
     "customer": {
       "audiences": {
         "edges": [
           {
             "node": {
               "name": "has_email",
               "is_ready": true,
               "state": "qualified",
               "description": "Customers who have an email address (regardless of consent/reachability status)"
             }
           },
           {
             "node": {
               "name": "has_email_opted_in",
               "is_ready": true,
               "state": "qualified",
               "description": "Customers who have an email address, and it is opted-in"
             }
           },
            ...
         ]
       }
     }
   }
 }
 */

class ZaiusApiManager {
    let logger = OPTLoggerFactory.getLogger()

    let apiHost = "https://api.zaius.com/v3/graphql"
    
    func fetch(apiKey: String,
               userKey: String,
               userValue: String,
               segmentsToCheck: [String]?,
               completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        if userKey != "vuid" {
            completionHandler([], .fetchSegmentsFailed("userKeys other than 'vuid' not supported yet"))
            return
        }
        
        if (segmentsToCheck?.count ?? 0) > 0 {
            self.logger.w("Selective segments fetching is not supported yet.")
        }
        
        let body = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences {edges {node {name is_ready state}}}}}"
        ]
        guard let httpBody = try? JSONEncoder().encode(body) else {
            completionHandler([], .fetchSegmentsFailed("invalid query."))
            return
        }

        let url = URL(string: apiHost)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = httpBody
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let session = self.getSession()
        // without this the URLSession will leak, see docs on URLSession and https://stackoverflow.com/questions/67318867
        defer { session.finishTasksAndInvalidate() }

        let task = session.dataTask(with: urlRequest) { data, _, error in
            if let error = error {
                self.logger.d {
                    "GraphQL download failed: \(error)"
                }
                completionHandler([], .fetchSegmentsFailed("download failed"))
                return
            }
            
            guard let data = data else {
                completionHandler([], .fetchSegmentsFailed("response data empty"))
                return
            }
            
            guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let audDict: [[String: Any]] = dict.extractComponent(keyPath: "data.customer.audiences.edges")
            else {
                self.logger.d {
                    "GraphQL decode failed: " + String(bytes: data, encoding: .utf8)!
                }
                completionHandler([], .fetchSegmentsFailed("decode error"))
                return
            }
                    
            let audiences = audDict.compactMap { ODPAudience($0["node"] as? [String: Any]) }
            let segments = audiences.filter { $0.isQualified }.map { $0.name }
            completionHandler(segments, nil)
        }
        
        task.resume()
    }
    
    func getSession() -> URLSession {
        return URLSession(configuration: .ephemeral)
    }
    
}

struct ODPAudience: Decodable {
    let name: String
    let isReady: Bool
    let state: String
    let description: String
    
    var isQualified: Bool {
        isReady && state == "qualified"
    }
    
    init?(_ dict: [String: Any]?) {
        guard let dict = dict,
                let name = dict["name"] as? String,
                let isReady = dict["is_ready"] as? Bool,
                let state = dict["state"] as? String,
              let description = dict["description"] as? String else { return nil }
        
        self.name = name
        self.isReady = isReady
        self.state = state
        self.description = description
    }
}

// Extract deep-json contents with keypath "a.b.c"
// { "a": { "b": { "c": "contents" } } }

extension Dictionary {
    
    func extractComponent<T>(keyPath: String) -> T? {
        var current: Any? = self
        
        for component in keyPath.split(separator: ".") {
            if let dictionary = current as? [String: Any] {
                current = dictionary[String(component)]
            } else {
                return nil
            }
        }
        
        return current == nil ? nil : (current as? T)
    }
    
}
