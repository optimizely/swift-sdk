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

public class OptimizelyODPConfig {
    /// maximum size (default = 100) of audience segments cache (optional)
    let segmentsCacheSize: Int
    /// timeout in seconds (default = 600) of audience segments cache (optional)
    let segmentsCacheTimeoutInSecs: Int
    /// The host URL for the ODP audience segments API (optional). If not provided, SDK will use the default host in datafile.
    private var _apiHost: String?
    /// The public API key for the ODP account from which the audience segments will be fetched (optional). If not provided, SDK will use the default publicKey in datafile.
    private var _apiKey: String?
    /// enabled by default (disabled when datafile has no ODP key/host settings)
    private var _enabled = true

    let queue = DispatchQueue(label: "odpConfig")
    
    public init(segmentsCacheSize: Int = 100,
                segmentsCacheTimeoutInSecs: Int = 600) {
        self.segmentsCacheSize = segmentsCacheSize
        self.segmentsCacheTimeoutInSecs = segmentsCacheTimeoutInSecs
    }
    
    func update(apiKey: String?, apiHost: String?) {
        self.apiKey = apiKey
        self.apiHost = apiHost
        
        // disable future event queueing if datafile has no ODP settings
    
        self.enabled = (apiKey != nil) && (apiHost != nil)
    }
}

// MARK: - Thread-safe

extension OptimizelyODPConfig {
    
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
    
    var enabled: Bool {
        get {
            var value = false
            queue.sync {
                value = _enabled
            }
            return value
        }
        set {
            queue.async {
                self._enabled = newValue
            }
        }
    }
    
}

