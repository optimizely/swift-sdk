/****************************************************************************
* Copyright 2019, Optimizely, Inc. and contributors                        *
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

public struct Variation: Codable, Equatable {
    public var id: String
    public var key: String
    var featureEnabled: Bool?
    var variables: [Variable]?
    
    // MARK: - OptimizelyConfig

    public var variablesMap: [String: Variable] {
        var map = [String: Variable]()
        variables?.forEach({
            map[$0.key] = $0
        })
        return map
    }
}

// MARK: - Utils

extension Variation {
    
    func getVariable(id: String) -> Variable? {
        return variables?.filter { $0.id == id }.first
    }
    
}
