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

public struct OptimizelySdkSettings {
    /// The maximum size of audience segments cache - cache is disabled if this is set to zero.
    let segmentsCacheSize: Int
    /// The timeout in seconds of audience segments cache - timeout is disabled if this is set to zero.
    let segmentsCacheTimeoutInSecs: Int
    /// The timeout in seconds of odp segment fetch - OS default timeout will be used if this is set to zero.
    let timeoutForSegmentFetchInSecs: Int
    /// The timeout in seconds of odp event dispatch - OS default timeout will be used if this is set to zero.
    let timeoutForOdpEventInSecs: Int
    /// ODP features are disabled if this is set to true.
    let disableOdp: Bool
    /// VUID is enabled if this is set to true.
    let enableVuid: Bool
    
    /// Optimizely SDK Settings
    ///
    /// - Parameters:
    ///   - segmentsCacheSize: The maximum size of audience segments cache (optional. default = 100). Set to zero to disable caching.
    ///   - segmentsCacheTimeoutInSecs: The timeout in seconds of audience segments cache (optional. default = 600). Set to zero to disable timeout.
    ///   - timeoutForSegmentFetchInSecs: The timeout in seconds of odp segment fetch (optional. default = 10) - OS default timeout will be used if this is set to zero.
    ///   - timeoutForOdpEventInSecs: The timeout in seconds of odp event dispatch (optional. default = 10) - OS default timeout will be used if this is set to zero.
    ///   - disableOdp: Set this flag to true (default = false) to disable ODP features
    ///   - sdkName: Set this flag to override sdkName included in events
    ///   - sdkVersion: Set this flag to override sdkVersion included in events
    public init(segmentsCacheSize: Int = 100,
                segmentsCacheTimeoutInSecs: Int = 600,
                timeoutForSegmentFetchInSecs: Int = 10,
                timeoutForOdpEventInSecs: Int = 10,
                disableOdp: Bool = false,
                enabledVuid: Bool = false,
                sdkName: String? = nil,
                sdkVersion: String? = nil) {
        self.segmentsCacheSize = segmentsCacheSize
        self.segmentsCacheTimeoutInSecs = segmentsCacheTimeoutInSecs
        self.timeoutForSegmentFetchInSecs = timeoutForSegmentFetchInSecs
        self.timeoutForOdpEventInSecs = timeoutForOdpEventInSecs
        self.disableOdp = disableOdp
        self.enableVuid = enabledVuid
        if let _sdkName = sdkName, _sdkName != "" {
            Utils.swiftSdkClientName = _sdkName
        }
        if let _sdkVersion = sdkVersion, _sdkVersion != "" {
            Utils.sdkVersion = _sdkVersion
        }
    }
}
