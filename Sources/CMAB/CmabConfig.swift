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

let DEFAULT_CMAB_CACHE_TIMEOUT = 30 * 60 // 30 minutes
let DEFAULT_CMAB_CACHE_SIZE = 100
let CMAB_PREDICTION_END_POINT = "https://prediction.cmab.optimizely.com/predict"

/// Configuration for CMAB (Contextual Multi-Armed Bandit) service
public struct CmabConfig {
    /// The maximum size of CMAB decision cache
    let cacheSize: Int
    /// The timeout in seconds of CMAB cache
    let cacheTimeoutInSecs: Int
    /// The CMAB prediction endpoint
    var predictionEndpoint: String?
    
    ///   - cmabCacheSize: The maximum size of cmab cache (optional. default = 100).
    ///   - cmabCacheTimeoutInSecs: The timeout in seconds of amb cache (optional. default = 30 * 60).
    ///   - predictionEndpoint: Set the CMAB prediction endpoint. default will be used if nil is set.
    public init(
        cacheSize: Int = 100,
        cacheTimeoutInSecs: Int = 30 * 60,
        predictionEndpoint: String? = nil
    ) {
        self.cacheSize = cacheSize
        self.cacheTimeoutInSecs = cacheTimeoutInSecs
        // Sanitize and validate endpoint
        if let endpoint = predictionEndpoint?.trimmingCharacters(in: .whitespaces), !endpoint.isEmpty {
            // Remove trailing slashes
            var sanitized = endpoint
            if sanitized.hasSuffix("/") {
                sanitized = String(sanitized.dropLast())
            }
            self.predictionEndpoint = sanitized
        } else {
            self.predictionEndpoint = CMAB_PREDICTION_END_POINT
        }
    }
}
