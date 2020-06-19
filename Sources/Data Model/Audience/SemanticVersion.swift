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

typealias SemanticVersion = String
/*
 This comparison is ported from the Optimizely web version of semantic version compare.
 https://github.com/optimizely/client-js/blob/devel/src/core/lib/compare_version.js
 Full testing in SemanticVersionTests.
 */
extension SemanticVersion {
    func compareVersion(targetedVersion: SemanticVersion?) -> Int {
        guard let targetedVersion = targetedVersion else {
            // Any version.
            return 0
          }

          // Expect a version string of the form x.y.z
        let targetedVersionParts = targetedVersion.split(separator: ".");
        let versionParts = self.split(separator: ".");

        // Up to the precision of targetedVersion, expect version to match exactly.
        for (idx, _) in targetedVersionParts.enumerated() {
            if versionParts.count <= idx {
              return -1;
            } else if !String(versionParts[idx]).isNumber {
                //Compare strings
                if versionParts[idx] != targetedVersionParts[idx] {
                    return -1;
              }
            } else if let part = Int(versionParts[idx]), let target = Int(targetedVersionParts[idx]){
                if (part < target) {
                  return -1;
                } else if part > target {
                  return 1;
                }
            } else {
                return -1;
            }
        }

          return 0;
        }

    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}
