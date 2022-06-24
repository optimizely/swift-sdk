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
    
    var vuidMap: VUIDMap
    let queue: DispatchQueue
    let logger = OPTLoggerFactory.getLogger()

    init() {
        self.queue = DispatchQueue(label: "vuid")
        self.vuidMap = VUIDMap()
    }
    
    var vuid: String {
        var vuid = ""
        queue.sync {
            vuid = self.vuidMap.vuid
        }
        return vuid
    }
    
    var isVUIDRegistered: Bool {
        var registered = false
        queue.sync {
            registered = self.vuidMap.registered
        }
        return registered
    }
    
    func setVUIDRegistered() {
        queue.async {
            self.vuidMap.registered = true
            self.vuidMap.save()
        }
    }

    func isUserRegistered(userId: String) -> Bool {
        var registered = false
        queue.sync {
            registered = self.vuidMap.usersSet.contains(userId)
        }
        return registered
    }
    
    func addRegisteredUser(userId: String) {
        queue.async {
            self.vuidMap.addUser(userId)
            self.vuidMap.save()
        }
    }
}

// MAKR: - VUID format

extension VUIDManager {
    static func makeVuid() -> String {
        return "VUID_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    func isVuid(visitorId: String) -> Bool {
        return visitorId.starts(with: "VUID")
    }
}

// MARK: - VUIDMap

struct VUIDMap {
    var vuid: String = ""
    var registered: Bool = false
    var users = [String]()
    var usersSet = Set<String>()
    
    let maxUsersRegistered = 10
    
    init() {
        self.load()
    }
    
    mutating func addUser(_ userId: String) {
        if self.usersSet.contains(userId) {
            return
        }

        if users.count > maxUsersRegistered {
            users.removeFirst()
        }
        users.append(userId)
        
        usersSet = Set(users)
        save()
    }
    
    // MARK: - UserDefaults
    
    // UserDefaults format: (keep the most recent vuid info only)
    //      "optimizely-vuids": {
    //          "vuid": "vuid1",
    //          "registered": true,
    //          "users": ["userId1", "userId2"]
    //      }
    
    var keyForVuidMap = "optimizely-vuid-map"
    var keyForVuid = "vuid"
    var keyForRegistered = "registered"
    var keyForUsers = "users"

    mutating func load() {
        guard let vuids = UserDefaults.standard.dictionary(forKey: keyForVuidMap),
              let oldVuid = vuids[keyForVuid] as? String
        else {
            self.vuid = VUIDManager.makeVuid()
            self.registered = false
            self.users = []
            self.usersSet = Set(users)
            save()
            return
        }
        
        self.vuid = oldVuid
        self.registered = (vuids[keyForRegistered] as? Bool) ?? false
        self.users = (vuids[keyForUsers] as? [String]) ?? []
        self.usersSet = Set(users)
    }

    func save() {
        let dict: [String: Any] = [keyForVuid: vuid, keyForRegistered: registered, keyForUsers: users]
        UserDefaults.standard.set(dict, forKey: keyForVuidMap)
        print("saved vuidMap: \(dict)")
        UserDefaults.standard.synchronize()
    }
}

