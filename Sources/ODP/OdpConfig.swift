//
// Copyright 2022-2023, Optimizely, Inc. and contributors 
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

public class OdpConfig {
    /// The host URL for the ODP audience segments API (optional).
    private var _apiHost: String?
    /// The public API key for the ODP account from which the audience segments will be fetched (optional).
    private var _apiKey: String?
    /// An array of all ODP segments used in the current datafile (associated with apiHost/apiKey).
    private var _segmentsToCheck: [String]
    /// An enum value indicating that odp is integrated for the project or not
    private var _odpServiceIntegrated: OdpConfigState

    enum OdpConfigState {
        case notDetermined
        case integrated
        case notIntegrated
    }
    
    let queue = DispatchQueue(label: "odpConfig")
    
    public init(apiKey: String? = nil, apiHost: String? = nil, segmentsToCheck: [String] = []) {
        self._apiKey = apiKey
        self._apiHost = apiHost
        self._segmentsToCheck = segmentsToCheck
        self._odpServiceIntegrated = .notDetermined  // initially queueing allowed until the first datafile is parsed
    }

    func update(apiKey: String?, apiHost: String?, segmentsToCheck: [String]) -> Bool {
        if (apiKey != nil) && (apiHost != nil) {
            self.odpServiceIntegrated = .integrated
        } else {
            // disable future event queueing if datafile has no ODP integrations.
            self.odpServiceIntegrated = .notIntegrated
        }

        if self.apiKey == apiKey, self.apiHost == apiHost, self.segmentsToCheck == segmentsToCheck {
            return false
        } else {
            self.apiKey = apiKey
            self.apiHost = apiHost
            self.segmentsToCheck = segmentsToCheck
            return true
        }
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
    
    var odpServiceIntegrated: OdpConfigState {
        get {
            var value = OdpConfigState.notDetermined
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
    
    var eventQueueingAllowed: Bool {
        var value = true
        queue.sync {
            switch _odpServiceIntegrated {
            case .notDetermined, .integrated: value = true
            case .notIntegrated: value = false
            }
        }
        return value
    }

}
