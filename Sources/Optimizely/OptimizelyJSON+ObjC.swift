/****************************************************************************
* Copyright 2020-2021, Optimizely, Inc. and contributors                   *
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

extension OptimizelyJSON {
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithPayload:)
    convenience init?(p: String) {
        self.init(payload: p)
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(initWithMap:)
    convenience init?(m: [String: Any]) {
        self.init(map: m)
    }
    
    /// - Returns: true when one or more variables are included.
    @available(swift, obsoleted: 1.0)
    @objc(isEmpty)
    public func objcIsEmpty() -> Bool {
        return self.isEmpty
    }

    @available(swift, obsoleted: 1.0)
    @objc(toString)
    /// - Returns: The string representation of json
    public func objcToString() -> String? {
        return self.toString()
    }
    
    @available(swift, obsoleted: 1.0)
    @objc(toMap)
    /// - Returns: The json dictionary
    public func objcToMap() -> [String: Any] {
        return self.toMap()
    }
}
