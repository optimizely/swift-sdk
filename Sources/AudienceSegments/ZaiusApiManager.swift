//
//  GraphQL.swift
//  SwiftGraphQL
//
//  Created by Jae Kim on 1/10/22.
//

import Foundation

// ODP GraphQL API
// - https://api.zaius.com/v3/graphql

/* GraphQL Request
 
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
    vuid
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
    
    /*
     curl -i -H 'Content-Type: application/json' -H 'x-api-key: W4WzcEs-ABgXorzY7h1LCQ' -X POST -d '{"query":"query {customer(vuid: \"d66a9d81923d4d2f99d8f64338976322\") {audiences {edges {node {name is_ready state description}}} vuid}}"}' https://api.zaius.com/v3/graphql
     */
    
    func fetch(apiKey: String,
               userKey: String,
               userValue: String,
               segments: [String]?,
               completionHandler: @escaping ([String]?, Error?) -> Void) {
        if userKey != "vuid" {
            self.logger.e("Currently userKeys other than 'vuid' are not supported yet.")
            return
        }
        
        if (segments?.count ?? 0) > 0 {
            self.logger.w("Selective segments fetching is not supported yet.")
        }
        
        let body = [
            "query": "query {customer(\(userKey): \"\(userValue)\") {audiences {edges {node {name is_ready state description}}}}}"
        ]
        guard let httpBody = try? JSONEncoder().encode(body) else { return }

        let url = URL(string: apiHost)!
        var urlRequest = URLRequest(url: url)
        
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = httpBody
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let task = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            if let error = error {
                self.logger.e("GraphQL download failed: \(error)")
                return
            }
            
            if let data = data {
                if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let audDict: [[String: Any]] = dict.extractComponent(keyPath: "data.customer.audiences.edges") {
                        let audiences = audDict.compactMap { ODPAudience($0["node"] as? [String: Any]) }
                        //print("[GraphQL Response] \(audiences)")
                        
                        let segments = audiences.filter { $0.isQualified }.map { $0.name }
                        //print("[GraphQL Audience Segments] \(segments)")
                        
                        completionHandler(segments, nil)
                        return
                    }
                } else {
                    self.logger.e("GraphQL decode failed: " + String(bytes: data, encoding: .utf8)!)
                }
            } else {
                self.logger.e("GraphQL data empty")
            }
            
            completionHandler([], OptimizelyError.generic)
        }
        
        task.resume()
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
        
        return current as? T
    }
}

