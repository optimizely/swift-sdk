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

// MARK: - GraphQL API

// ODP GraphQL API
// - https://api.zaius.com/v3/graphql

// testODPApiKeyForAudienceSegments = "W4WzcEs-ABgXorzY7h1LCQ"
// testODPUserIdForAudienceSegments = "d66a9d81923d4d2f99d8f64338976322"

/*
 
 [GraphQL Request]
 
 // fetch all segments
 curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"query":"query {customer(vuid: \"d66a9d81923d4d2f99d8f64338976322\") {audiences {edges {node {name state}}}}}"}' https://api.zaius.com/v3/graphql

 // fetch info for "has_email" segment only
 curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"query":"query {customer(vuid: \"d66a9d81923d4d2f99d8f64338976322\") {audiences(subset:["has_email"]) {edges {node {name state}}}}}"}' https://api.zaius.com/v3/graphql

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
*/

class ZaiusApiManager {
    let logger = OPTLoggerFactory.getLogger()

    func fetch(apiKey: String,
               apiHost: String,
               userKey: String,
               userValue: String,
               segmentsToCheck: [String]?,
               completionHandler: @escaping ([String]?, OptimizelyError?) -> Void) {
        if userKey != "vuid" {
            completionHandler(nil, .fetchSegmentsFailed("userKeys other than 'vuid' not supported yet"))
            return
        }
        
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

        let task = session.dataTask(with: urlRequest) { data, _, error in
            if let error = error {
                self.logger.d {
                    "GraphQL download failed: \(error)"
                }
                completionHandler(nil, .fetchSegmentsFailed("download failed"))
                return
            }
            
            guard let data = data else {
                completionHandler(nil, .fetchSegmentsFailed("response data empty"))
                return
            }
            
            guard let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let audDict: [[String: Any]] = dict.extractComponent(keyPath: "data.customer.audiences.edges")
            else {
                self.logger.d {
                    "GraphQL decode failed: " + String(bytes: data, encoding: .utf8)!
                }
                completionHandler(nil, .fetchSegmentsFailed("decode error"))
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
    
    func makeSubsetFilter(segments: [String]?) -> String {
        // segments = nil: (fetch all segments)
        //   --> subsetFilter = ""
        // segments = []: (fetch none)
        //   --> subsetFilter = "(subset:[])"
        // segments = ["a"]: (fetch one segment)
        //   --> subsetFilter = "(subset:[\"a\"])"

        var subsetFilter = ""
        
        if let segments = segments {
            let serial = segments.map { "\"\($0)\""}.joined(separator: ",")
            subsetFilter = "(subset:[\(serial)])"
        }
        
        return subsetFilter
    }
    
}

// MARK: - REST API

extension ZaiusApiManager {
    
    public func odpEvent(apiKey: String,
                         apiHost: String,
                         identifiers: [String: Any],
                         kind: String,
                         data: [String: Any] = [:],
                         completion: @escaping (Bool) -> Void) {
        let kinds = kind.split(separator: ":")
        guard kinds.count == 2 else {
            print("[ODP Event] invalid format for kind")
            completion(false)
            return
        }
        
        var vuid = self.vuidManager.vuid
        if vuid == nil {
            vuid = self.vuidManager.newVuid
            print("new vuid generated: \(vuid!)")
        }
                
        var identifiers = [
            "vuid": vuid
        ]
        
        if let userId = userId {
            identifiers["fs_user_id"] = userId
        }
        
        guard let url = URL(string: "\(apiHost)/v3/events") else {
            print("[ODP Event] invalid url")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let combinedData: [String: Any] = [
            "type": kinds[0],
            "action": kinds[1],
            //"data_source": "fullstack:swift-sdk",
            "identifiers": identifiers,
            "data": data
        ]
        
        guard let body = try? JSONSerialization.data(withJSONObject: combinedData) else {
            print("[ODP Event] invalid JSON")
            completion(false)
            return
        }
        
        request.httpBody = body
        request.addValue(odpPublicKey, forHTTPHeaderField: "x-api-key")
        request.addValue("application/json", forHTTPHeaderField: "content-type")

        print("[ODP] request body: \(combinedData)")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("[ODP Event] API error: \(error)")
                completion(false)
                return
            }
            
            if let response = response as? HTTPURLResponse {
                if response.statusCode >= 400 {
                    let message = data != nil ? String(bytes: data!, encoding: .utf8) : "UNKNOWN"
                    print("[ODP Event] API failed: \(message) \(self.odpPublicKey)")
                    completion(false)
                    return
                }
            }

            completion(true)
        }
        task.resume()
        
        completion(true)
    }

}

// MARK: - Utils

struct ODPAudience: Decodable {
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
