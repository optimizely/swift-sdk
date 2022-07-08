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

public struct OptimizelySdkSettings {
    /// maximum size (default = 100) of audience segments cache (optional)
    let segmentsCacheSize: Int
    /// timeout in seconds (default = 600) of audience segments cache (optional)
    let segmentsCacheTimeoutInSecs: Int
    /// set this flag to false (default = true) to disable ODP features
    let enableOdp: Bool
    
    public init(segmentsCacheSize: Int = 100,
                segmentsCacheTimeoutInSecs: Int = 600,
                enableOdp: Bool = true) {
        self.segmentsCacheSize = segmentsCacheSize
        self.segmentsCacheTimeoutInSecs = segmentsCacheTimeoutInSecs
        self.enableOdp = enableOdp
    }
}
