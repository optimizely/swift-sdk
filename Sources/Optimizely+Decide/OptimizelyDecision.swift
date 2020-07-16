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

public struct OptimizelyDecision {
    public let variationKey: String?
    public let enabled: Bool?
    public let variables: OptimizelyJSON?

    public let key: String
    public let user: OptimizelyUserContext?
    public let reasons: [String]
}

extension OptimizelyDecision {
    
    static func errorDecision(key: String, user: OptimizelyUserContext?, error: OptimizelyError) -> OptimizelyDecision {
        return OptimizelyDecision(variationKey: nil,
                                  enabled: nil,
                                  variables: nil,
                                  key: key,
                                  user: user,
                                  reasons: [error.reason])
    }
    
}
