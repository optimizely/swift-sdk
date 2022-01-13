//
// Copyright 2021-2022, Optimizely, Inc. and contributors
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

extension OptimizelyUserContext {

    // fetch (or read from cache) all qualified segments for the user attribute (userId default)
    public func fetchQualifiedSegments(apiKey: String, completionHandler: @escaping (Bool) -> Void) {
        optimizely?.audienceHandler.fetchQualifiedSegments(apiKey: apiKey, user: self) { segments, err in
            if let err = err {
                self.logger.e("Fetch segments failed with error: \(err)")
                completionHandler(false)
                return
            }
            
            guard let segments = segments else {
                self.logger.e("Fetch segments failed with invalid segments")
                completionHandler(false)
                return
            }
            
            self.qualifiedSegments = Set(segments)
            completionHandler(true)
        }
    }

    // true if the user is qualified for the given segment name
    public func isQualifiedFor(segment: String) -> Bool {
        return qualifiedSegments != nil
    }
    
}
