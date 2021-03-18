//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

class DecisionResponse<T> {
    var result: T?
    var reasons: DecisionReasons
    
    init(result: T?, reasons: DecisionReasons) {
        self.result = result
        self.reasons = reasons
    }
    
    static func responseNoReasons(result: T?) -> DecisionResponse {
        return DecisionResponse(result: result, reasons: DecisionReasons(includeInfos: false))
    }
    
    static func nilNoReasons() -> DecisionResponse {
        return DecisionResponse(result: nil, reasons: DecisionReasons(includeInfos: false))
    }
}
