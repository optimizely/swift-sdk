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

public class ODPManager {
    let vuidManager: VUIDManager
    
    init(vuidManager: VUIDManager? = nil) {
        self.vuidManager = vuidManager ?? VUIDManager.shared
        
        if !self.vuidManager.isVUIDRegistered {
            self.register()
        }
    }
        
    public func register(apiKey: String? = nil,
                         apiHost: String? = nil,
                         completion: ((Bool) -> Void)? = nil) {
        let vuid = self.vuidManager.newVuid

        let identifiers = [
            "vuid": vuid
        ]

        odpEvent(identifiers: identifiers, kind: "experimentation:client_initialized") { success in
            if success {
                print("[ODP] vuid registered (\(vuid)) successfully")
                self.vuidManager.updateRegisteredVUID(vuid)
            }
            completion?(success)
        }
    }
    
    public func identify(apiKey: String? = nil,
                         apiHost: String? = nil,
                         userId: String, completion: ((Bool) -> Void)? = nil) {
        guard let vuid = vuidManager.vuid else {
            print("invalid vuid for identify")
            return
        }
        
        let identifiers = [
            "vuid": vuid,
            "fs_user_id": userId
        ]

        odpEvent(identifiers: identifiers, kind: "experimentation:identified") { success in
            if success {
                print("[ODP] add idenfier (\(userId)) successfully")
                self.vuidManager.updateRegisteredUsers(userId: userId)
            }
            completion?(success)
        }
    }
    
    public func odpEvent(identifiers: [String: Any], kind: String, data: [String: Any] = [:], completion: @escaping (Bool) -> Void) {
        let kinds = kind.split(separator: ":")
        guard kinds.count == 2 else {
            print("[ODP Event] invalid format for kind")
            completion(false)
            return
        }
        
        guard let url = URL(string: "\(odpHost)/v3/events") else {
            print("[ODP Event] invalid url")
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
        
        guard let odpApiKey = apiKey ?? config?.publicKeyForODP else {
            completionHandler(nil, .fetchSegmentsFailed("apiKey not defined"))
            return
        }
        
        guard let odpApiHost = apiHost ?? config?.hostForODP else {
            completionHandler(nil, .fetchSegmentsFailed("apiHost not defined"))
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
