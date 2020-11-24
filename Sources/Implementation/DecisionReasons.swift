/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
*                                                                          *
* Licensed under the Apache License, Version 2.0 (the "License");          *
* you may not use this file except in compliance with the License.         *
* You may obtain a copy of the License at                                  *
*                                                                          *
*    http://www.apache.org/licenses/LICENSE-2.0                            *
*                                                                          *
* Unless required by applicable law or agreed to in writing, software      *
* distributed under the License is distributed on an "AS IS" BASIS,        *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. *
* See the License for the specific language governing permissions and      *
* limitations under the License.                                           *
***************************************************************************/

import Foundation

protocol ReasonProtocol {
    var reason: String { get }
}

class DecisionReasons {
    var errors: [ReasonProtocol]
    var infos: [ReasonProtocol]
    let includeReasons: Bool
    
    init(options: [OptimizelyDecideOption]) {
        includeReasons = options.contains(.includeReasons)
        errors = []
        infos = []
    }
    
    func addError(_ error: ReasonProtocol) {
        errors.append(error)
    }
    
    func addInfo(_ info: ReasonProtocol) {
        if includeReasons {
            infos.append(info)
        }
    }
    
    func toReport() -> [String] {
        return errors.map { $0.reason } + infos.map { $0.reason }
    }
}
