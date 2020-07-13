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

public struct OptimizelyUserContext {
    var userId: String?
    var attributes: [String: Any]
    var bucketingId: String?
    var userProfileUpdates: [(String?, String?)]
    
    public init(userId: String?, attributes: [String: Any]? = nil) {
        self.userId = userId
        self.attributes = attributes ?? [:]
        self.userProfileUpdates = []
    }
    
    public mutating func setAttribute(key: String, value: Any) {
        attributes[key] = value
    }
    
    public mutating func setBucketingId(_ id: String) {
        bucketingId = id
        attributes[Constants.Attributes.OptimizelyBucketIdAttribute] = bucketingId
    }
    
    public mutating func setUserProfile(key: String?, value: String?) {
        userProfileUpdates.append((key, value))
    }
}

extension OptimizelyUserContext: Equatable {
    
    public static func ==(lhs: OptimizelyUserContext, rhs: OptimizelyUserContext) -> Bool {
        if !(lhs.userId == rhs.userId &&
            lhs.bucketingId == rhs.bucketingId &&
            lhs.attributes.count == rhs.attributes.count &&
            lhs.userProfileUpdates.count == rhs.userProfileUpdates.count) {
            return false
        }
                
        if !(lhs.attributes as NSDictionary).isEqual(to: rhs.attributes) { return false }
        
        for idx in 0..<lhs.userProfileUpdates.count {
            if lhs.userProfileUpdates[idx] != rhs.userProfileUpdates[idx] {
                return false
            }
        }
        
        return true
    }
}
