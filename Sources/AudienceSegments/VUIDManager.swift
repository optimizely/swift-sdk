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

// MARK: - ODP

extension VUIDManager {
    
    public func registerVUID() {
        if isVUIDRegistered {
            logger.d("ODP: vuid is registered already.")
            completionHandler(nil)
            return
        }

        guard let odpApiKey = apiKey ?? odpConfig.apiKey else {
            completionHandler(.odpEventFailed("apiKey not defined"))
            return
        }
        
        guard let odpApiHost = apiHost ?? odpConfig.apiHost else {
            completionHandler(.odpEventFailed("apiHost not defined"))
            return
        }

        let vuid = self.vuidManager.newVuid

        let identifiers = [
            "vuid": vuid
        ]
        
        zaiusMgr.sendODPEvent(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              identifiers: identifiers,
                              kind: "experimentation:client_initialized") { error in
            if error == nil {
                self.logger.d("ODP: vuid registered (\(vuid)) successfully")
                self.vuidManager.updateRegisteredVUID(vuid)
            }
            completionHandler(error)
        }
    }
    
    public func identifyUser(userId: String) {
        if isUserRegistered(userId: userId) {
            logger.d("ODP: user (\(userId)) is registered already.")
            completionHandler(nil)
            return
        }

        guard let odpApiKey = apiKey ?? odpConfig.apiKey else {
            completionHandler(.odpEventFailed("apiKey not defined"))
            return
        }
        
        guard let odpApiHost = apiHost ?? odpConfig.apiHost else {
            completionHandler(.odpEventFailed("apiHost not defined"))
            return
        }

        guard let vuid = vuidManager.vuid else {
            completionHandler(.odpEventFailed("invalid vuid for identify"))
            return
        }
        
        let identifiers = [
            "vuid": vuid,
            "fs_user_id": userId
        ]

        zaiusMgr.sendODPEvent(apiKey: odpApiKey,
                              apiHost: odpApiHost,
                              identifiers: identifiers,
                              kind: "experimentation:identified") { error in
            if error == nil {
                self.logger.d("ODP: idenfier (\(userId)) added successfully")
                self.vuidManager.updateRegisteredUsers(userId: userId)
            }
            completionHandler(error)
        }
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
            self.vuid = "VUID-" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
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
