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
 Full testing in SemanticVersionTests.
 */
extension SemanticVersion {
    func compareVersion(targetedVersion: SemanticVersion?) throws -> Int {
        guard let targetedVersion = targetedVersion else {
            // Any version.
            return 0
          }
        

        let targetedVersionParts = try targetedVersion.splitSemanticVersion()
        let versionParts = try self.splitSemanticVersion()

        // Up to the precision of targetedVersion, expect version to match exactly.
        for (idx, _) in targetedVersionParts.enumerated() {
            if versionParts.count <= idx {
                // even if they are equal at this point. if the target is a prerelease then it must be greater than the pre release.
                return targetedVersion.isPreRelease ?  1 : -1
            } else if !versionParts[idx].isNumber {
                //Compare strings
                if versionParts[idx] < targetedVersionParts[idx] {
                    return targetedVersion.isPreRelease && !self.isPreRelease ? 1: -1;
                }
                else if versionParts[idx] > targetedVersionParts[idx] {
                    return !targetedVersion.isPreRelease && self.isPreRelease ? -1: 1;
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
        
        if self.isPreRelease && !targetedVersion.isPreRelease {
            return -1;
        }
    
        return 0;
    }
    
    func splitSemanticVersion() throws -> [Substring] {
        var targetParts:[Substring]?
        var targetPrefix = self
        var targetSuffix:ArraySlice<Substring>?
        
        if hasWhiteSpace {
            throw OptimizelyError.attributeFormatInvalid
        }
        
        if isPreRelease || isBuild {
            targetParts = split(separator: isPreRelease ? preReleaseSeperator : buildSeperator,
            maxSplits: 1)
            guard let targetParts = targetParts, targetParts.count > 1 else {
                throw OptimizelyError.attributeFormatInvalid
            }
            
            targetPrefix = String(targetParts[0])
            targetSuffix = targetParts[1...]
        }
        // Expect a version string of the form x.y.z
        let dotCount = targetPrefix.filter({$0 == "."}).count
        if dotCount > 2 {
            throw OptimizelyError.attributeFormatInvalid
        }
        var targetedVersionParts = targetPrefix.split(separator: ".")
        guard targetedVersionParts.count == dotCount + 1 && targetedVersionParts.filter({$0.isNumber}).count == targetedVersionParts.count else {
            throw OptimizelyError.attributeFormatInvalid
        }
        if let targetSuffix = targetSuffix {
            targetedVersionParts.append(contentsOf: targetSuffix)
        }
        return targetedVersionParts
    }
    
    var hasWhiteSpace: Bool {
        return contains(" ")
    }

    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    var isPreRelease: Bool {
        return firstIndex(of: "-")?.utf16Offset(in: self) ?? Int.max < firstIndex(of: "+")?.utf16Offset(in: self) ?? Int.max
    }

    var isBuild: Bool {
        return firstIndex(of: "+")?.utf16Offset(in: self) ?? Int.max < firstIndex(of: "-")?.utf16Offset(in: self) ?? Int.max
    }
    
    var buildSeperator:Character {
        return "+"
    }
    var preReleaseSeperator:Character {
        return "-"
    }
}

extension Substring {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }

    var isPreRelease: Bool {
        return firstIndex(of: "-")?.utf16Offset(in: self) ?? Int.max < firstIndex(of: "+")?.utf16Offset(in: self) ?? Int.max
    }

    var isBuild: Bool {
        return firstIndex(of: "+")?.utf16Offset(in: self) ?? Int.max < firstIndex(of: "-")?.utf16Offset(in: self) ?? Int.max
    }

}
