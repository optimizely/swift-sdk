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
    let keyForVuid = "vuid"
    let keyForVuidUsers = "vuid-users"

    var odpPublicKey: String {
        return "W4WzcEs-ABgXorzY7h1LCQ"
    }
    var odpHost: String {
        return "https://api.zaius.com"
    }
    
    public let vuid: String
    var usersRegistered: Set<String>
    
    init() {
        if let vuid = UserDefaults.standard.string(forKey: keyForVuid) {
            self.vuid = vuid
        } else {
            let vuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            print("vuid generated: \(vuid)")
            UserDefaults.standard.set(vuid, forKey: keyForVuid)
            self.vuid = vuid
        }

        if let users = UserDefaults.standard.object(forKey: keyForVuidUsers) as? [String] {
            self.usersRegistered = Set(users)
        } else {
            self.usersRegistered = []
        }
    }
    
    public func isUserRegistered(userId: String) -> Bool {
        return usersRegistered.contains(userId)
    }
    
    private func updateRegisteredUsers(userId: String) {
        if usersRegistered.count > 10 {
            usersRegistered = usersRegistered.filter { _ in Bool.random() }
        }
              
        usersRegistered.insert(userId)
        UserDefaults.standard.set(Array(usersRegistered), forKey: keyForVuidUsers)
        UserDefaults.standard.synchronize()
        print("saved users: \(usersRegistered)")
    }
    
    public func register(completion: ((Bool) -> Void)? = nil) {
        odpEvent(userId: nil, kind: "experimentation:client_initialized") { success in
            if !success {
                print("[ODP] register failed")
            }
            completion?(success)
        }
    }
    
    public func identify(userId: String, completion: ((Bool) -> Void)? = nil) {
        odpEvent(userId: userId, kind: "experimentation:identified") { success in
            if success {
                print("[ODP] add idenfier (\(userId)) successfully")
                
                self.updateRegisteredUsers(userId: userId)
            }
            completion?(success)
        }
    }
    
    public func odpEvent(userId: String?, kind: String, data: [String: Any] = [:], completion: @escaping (Bool) -> Void) {
        var identifiers = [
            "vuid": vuid
        ]
        
        if let userId = userId {
            identifiers["fs_user_id"] = userId
        }
        
        let kinds = kind.split(separator: ":")
        guard kinds.count == 2 else {
            print("[ODP Event] invalid format for kind")
            completion(false)
            return
        }
        
        guard let url = URL(string: "https://api.zaius.com/v3/events") else {
            print("[ODP Event] invalid url")
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let combinedData: [String: Any] = [
            "type": kinds[0],
            "action": kinds[1],
            "data_source": "fullstack:swift-sdk",
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

//        let task = URLSession.shared.dataTask(with: url) { data, response, error in
//            if let error = error {
//                print("[ODP Event] API error: \(error)")
//                completion(false)
//                return
//            }
//
//            completion(true)
//        }
//        task.resume()
        
        completion(true)
    }
    
}
