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

class VUIDManager {
    static let shared = VUIDManager()
    
    var vuid: String?
    var usersSet = Set<String>()
    var usersOrdered = [String]()
    
    let queue: DispatchQueue
    
    var newVuid: String {
        return "VUID-" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    init() {
        self.queue = DispatchQueue(label: "vuid")
        
        if let vuids = UserDefaults.standard.dictionary(forKey: keyForVuidMap) {
            self.vuid = vuids[keyForVuid] as? String
        
            if let usersOrdered = vuids[keyForUsers] as? [String] {
                self.usersOrdered = usersOrdered
                self.usersSet = Set(usersOrdered)
            }
        }
    }
    
    var isVUIDRegistered: Bool {
        var registered = false
        queue.sync {
            registered = (self.vuid != nil)
        }
        return registered
    }
    
    func updateRegisteredVUID(_ vuid: String) {
        queue.async {
            self.vuid = vuid
            self.clearUsers()
        }
    }

    func isUserRegistered(userId: String) -> Bool {
        var registered = false
        queue.sync {
            registered = usersSet.contains(userId)
        }
        return registered
    }
    
    func updateRegisteredUsers(userId: String) {
        queue.async {
            if self.usersSet.contains(userId) {
                return
            }
            
            self.addUser(userId)
        }
    }
    
    func clearUsers() {
        usersOrdered = [String]()
        usersSet = Set<String>()
        saveVuidMap()
    }
    
    func addUser(_ userId: String) {
        if usersOrdered.count > 10 {
            let first = usersOrdered.removeFirst()
            usersSet.remove(first)
        }
        
        usersSet.insert(userId)
        usersOrdered.append(userId)
        saveVuidMap()
    }
    
}

// MARK: - UserDefaults

extension VUIDManager {
    
    // UserDefaults format: (keep the most recent vuid info only)
    //      "optimizely-vuids": {
    //          "vuid": "vuid1",
    //          "users": ["userId1", "userId2"]
    //      }
    var keyForVuidMap: String { return "optimizely-vuid-map" }
    var keyForVuid: String { return "vuid" }
    var keyForUsers: String { return "users" }

    func saveVuidMap() {
        if let vuid = vuid {
            let dict: [String: Any] = [keyForVuid: vuid, keyForUsers: usersOrdered]
            UserDefaults.standard.set(dict, forKey: keyForVuidMap)
            print("saved vuidMap: \(dict)")
        } else {
            UserDefaults.standard.removeObject(forKey: keyForVuidMap)
            print("removed vuidMap")
        }
        UserDefaults.standard.synchronize()
    }
    
}
