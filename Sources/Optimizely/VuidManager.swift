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

public class VuidManager {
    private var _vuid: String = ""
    private(set) var enable: Bool = false
    let logger = OPTLoggerFactory.getLogger()
    
    // a single vuid should be shared for all SDK instances
    public static let shared = VuidManager()
    
    public func configure(enable: Bool) {
        self.enable = enable
        if enable {
            self._vuid = load()
        } else {
            self.remove()
            self._vuid = ""
        }
    }
    
    static var newVuid: String {
        let maxLength = 32   // required by ODP server
        
        // make sure UUIDv4 is used (not UUIDv1 or UUIDv6) since the trailing 5 chars will be truncated. See TDD for details.
        let vuidFull = "vuid_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let vuid = (vuidFull.count <= maxLength) ? vuidFull : String(vuidFull.prefix(maxLength))
        return vuid
    }

    static func isVuid(_ visitorId: String) -> Bool {
        return visitorId.lowercased().starts(with: "vuid_")
    }
    
}

// MARK: - VUID Store

extension VuidManager {
    public var vuid: String? {
        if self.enable {
            return _vuid
        } else {
            logger.w("VUID is not enabled.")
            return nil
        }
    }
    
    private var keyForVuid: String {
        return "optimizely-vuid"
    }
    
    private func load() -> String {
        if let oldVuid = UserDefaults.standard.string(forKey: keyForVuid) {
            return oldVuid
        }
        
        let vuid = VuidManager.newVuid
        save(vuid: vuid)
        return vuid
    }
    
    private func remove() {
        UserDefaults.standard.set(nil, forKey: keyForVuid)
        UserDefaults.standard.synchronize()
    }
    
    private func save(vuid: String) {
        UserDefaults.standard.set(vuid, forKey: keyForVuid)
        UserDefaults.standard.synchronize()
    }
    
}
