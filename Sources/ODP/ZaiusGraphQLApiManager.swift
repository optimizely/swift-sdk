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
// - test ODP public API key = "W4WzcEs-ABgXorzY7h1LCQ"

/*
 
 [GraphQL Request]
 
 // fetch all segments
 curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"query":"query {customer(vuid: \"d66a9d81923d4d2f99d8f64338976322\") {audiences {edges {node {name state}}}}}"}' https://api.zaius.com/v3/graphql

 // fetch info for ["has_email", "has_email_opted_in", "push_on_sale"] segments
 curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"query":"query {customer(vuid: \"d66a9d81923d4d2f99d8f64338976322\") {audiences(subset:["has_email", "has_email_opted_in", "push_on_sale"]) {edges {node {name state}}}}}"}' https://api.zaius.com/v3/graphql

 query MyQuery {
   customer(vuid: "d66a9d81923d4d2f99d8f64338976322") {
     audiences {
       edges {
         node {
           name
           state
           description
         }
       }
     }
   }
 }

 [GraphQL Response]
 
 {
   "data": {
     "customer": {
       "audiences": {
         "edges": [
           {
             "node": {
               "name": "has_email",
               "state": "qualified",
               "description": "Customers who have an email address (regardless of consent/reachability status)"
             }
           },
           {
             "node": {
               "name": "has_email_opted_in",
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
 
 [GraphQL Error Response]

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
*/

class ZaiusGraphQLApiManager {
    let logger = OPTLoggerFactory.getLogger()

    func fetchSegments(apiKey: String,
                       apiHost: String,
                       userKey: String,
                       userValue: String,
                       segmentsToCheck: [String],
                       completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        let subsetFilter = makeSubsetFilter(segments: segmentsToCheck)
        
        let body = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences\(subsetFilter) {edges {node {name state}}}}}"
        ]
        guard let httpBody = try? JSONEncoder().encode(body) else {
            completionHandler(nil, .fetchSegmentsFailed("invalid query."))
            return
        }

        let apiEndpoint = apiHost + "/v3/graphql"
        let url = URL(string: apiEndpoint)!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = httpBody
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let session = self.getSession()
        // without this the URLSession will leak, see docs on URLSession and https://stackoverflow.com/questions/67318867
        defer { session.finishTasksAndInvalidate() }

        let task = session.dataTask(with: urlRequest) { data, response, error in
            var returnError: OptimizelyError?
            var returnSegments: [String]?
            
            defer {
                completionHandler(returnSegments, returnError)
            }

            guard error == nil, let data = data, let response = response as? HTTPURLResponse else {
                let msg = error?.localizedDescription ?? "invalid response"
                self.logger.d {
                    "GraphQL download failed: \(msg)"
                }
                returnError = .fetchSegmentsFailed("network error")
                return
            }
            
            let status = response.statusCode
            guard status < 400 else {
                returnError = .fetchSegmentsFailed("\(status)")
                return
            }
            
            guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                returnError = .fetchSegmentsFailed("decode error")
                return
            }
            
            // most meaningful ODP errors are returned in 200 success JSON under {"errors": ...}
            if let odpErrors: [[String: Any]] = dict.extractComponent(keyPath: "errors") {
                if let odpError = odpErrors.first, let errorClass: String = odpError.extractComponent(keyPath: "extensions.classification") {
                    if errorClass == "InvalidIdentifierException" {
                        returnError = .invalidSegmentIdentifier
                    } else {
                        returnError = .fetchSegmentsFailed(errorClass)
                    }
                    return
                }
            }
            
            guard let audDict: [[String: Any]] = dict.extractComponent(keyPath: "data.customer.audiences.edges") else {
                returnError = .fetchSegmentsFailed("decode error")
                return
            }
                    
            let audiences = audDict.compactMap { OdpAudience($0["node"] as? [String: Any]) }
            returnSegments = audiences.filter { $0.isQualified }.map { $0.name }
        }
        
        task.resume()
    }
    
    func getSession() -> URLSession {
        return URLSession(configuration: .ephemeral)
    }
    
    func makeSubsetFilter(segments: [String]) -> String {
        // segments = []: (fetch none)
        //   --> subsetFilter = "(subset:[])"
        // segments = ["a"]: (fetch one segment)
        //   --> subsetFilter = "(subset:[\"a\"])"

        let serial = segments.map { "\"\($0)\""}.joined(separator: ",")
        return "(subset:[\(serial)])"
    }
    
}

// MARK: - Utils

struct OdpAudience: Decodable {
    let name: String
    let state: String
    let description: String?     // optional so we can add for debugging
    
    var isQualified: Bool {
        return (state == "qualified")
    }
    
    init?(_ dict: [String: Any]?) {
        guard let dict = dict,
                let name = dict["name"] as? String,
                let state = dict["state"] as? String else { return nil }
        
        self.name = name
        self.state = state
        self.description = dict["description"] as? String
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
