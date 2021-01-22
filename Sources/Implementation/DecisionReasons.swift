/****************************************************************************
* Copyright 2021, Optimizely, Inc. and contributors                        *
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
    var infos: [ReasonProtocol]?
    
    init(includeInfos: Bool = true) {
        errors = []
        if includeInfos {
            infos = []
        }
    }

    convenience init(options: [OptimizelyDecideOption]?) {
        // include infos if options is not provided (default)
        self.init(includeInfos: options?.contains(.includeReasons) ?? true)
    }
    
    func addError(_ error: ReasonProtocol) {
        errors.append(error)
    }
    
    func addInfo(_ info: ReasonProtocol) {
        infos?.append(info)
    }
    
    func merge(_ reasons: DecisionReasons) {
        errors.append(contentsOf: reasons.errors)
        infos?.append(contentsOf: reasons.infos ?? [])
    }
    
    func toReport() -> [String] {
        return (errors + (infos ?? [])).map { $0.reason }
    }
}
