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

class OdpConfig {
    /// The host URL for the ODP audience segments API (optional). If not provided, SDK will use the default host in datafile.
    private var _apiHost: String?
    /// The public API key for the ODP account from which the audience segments will be fetched (optional). If not provided, SDK will use the default publicKey in datafile.
    private var _apiKey: String?
    /// assumed integrated by default (set to false when datafile has no ODP key/host settings)
    private var _odpServiceIntegrated: Bool
    /// an array of all ODP segments used in the current datafile (associated with apiHost/apiKey).
    private var _segmentsToCheck: [String]
    
    let queue = DispatchQueue(label: "odpConfig")
    
    init(apiKey: String? = nil, apiHost: String? = nil, segmentsToCheck: [String] = [], odpServiceIntegrated: Bool = true) {
        self._apiKey = apiKey
        self._apiHost = apiHost
        self._segmentsToCheck = segmentsToCheck
        self._odpServiceIntegrated = odpServiceIntegrated  // initially assumed true until the first datafile is parsed
    }

    func update(apiKey: String?, apiHost: String?, segmentsToCheck: [String]) -> Bool {
        // disable future event queueing if datafile has no ODP integrations.
        self.odpServiceIntegrated = (apiKey != nil) && (apiHost != nil)

        if self.apiKey == apiKey, self.apiHost == apiHost, self.segmentsToCheck == segmentsToCheck {
            return false
        }
        
        self.apiKey = apiKey
        self.apiHost = apiHost
        self.segmentsToCheck = segmentsToCheck
        return true
    }
}

// MARK: - Thread-safe

extension OdpConfig {
    
    var apiHost: String? {
        get {
            var value: String?
            queue.sync {
                value = _apiHost
            }
            return value
        }
        set {
            queue.async {
                self._apiHost = newValue
            }
        }
    }

    var apiKey: String? {
        get {
            var value: String?
            queue.sync {
                value = _apiKey
            }
            return value
        }
        set {
            queue.async {
                self._apiKey = newValue
            }
        }
    }
    
    var segmentsToCheck: [String] {
        get {
            var value = [String]()
            queue.sync {
                value = _segmentsToCheck
            }
            return value
        }
        set {
            queue.async {
                self._segmentsToCheck = newValue
            }
        }
    }
    
    var odpServiceIntegrated: Bool {
        get {
            var value = false
            queue.sync {
                value = _odpServiceIntegrated
            }
            return value
        }
        set {
            queue.async {
                self._odpServiceIntegrated = newValue
            }
        }
    }
}

