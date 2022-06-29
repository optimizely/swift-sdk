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
    var vuid: String = ""
    let logger = OPTLoggerFactory.getLogger()

    // a single vuid should be shared for all SDK instances
    static let shared = VUIDManager()
    
    init() {
        self.vuid = load()
    }
    
    func makeVuid() -> String {
        return "VUID_" + UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
    
    func isVuid(visitorId: String) -> Bool {
        return visitorId.starts(with: "VUID")
    }
}

// MARK: - VUID Store

extension VUIDManager {
    
    // UserDefaults format: (keep the most recent vuid info only)
    //      "optimizely-odp": {
    //          "vuid": "vuid1"
    //      }

    private var keyForVuidMap: String {
        return "optimizely-odp"
    }
    private var keyForVuid: String {
        "vuid"
    }
    
    private func load() -> String {
        if let vuids = UserDefaults.standard.dictionary(forKey: keyForVuidMap),
           let oldVuid = vuids[keyForVuid] as? String {
            return oldVuid
        }
        
        let vuid = makeVuid()
        save(vuid: vuid)
        return vuid
    }

    private func save(vuid: String) {
        let dict: [String: Any] = [keyForVuid: vuid]
        UserDefaults.standard.set(dict, forKey: keyForVuidMap)
        UserDefaults.standard.synchronize()
    }
    
}
