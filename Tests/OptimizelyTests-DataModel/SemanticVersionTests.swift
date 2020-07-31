//
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
    

import XCTest

class SemanticVersionTests: XCTestCase {
    
    // MARK: - version tests.
    
    func testTargetString() {
        let target = "2.0" as SemanticVersion
        let version = "2.0.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) == 0)
    }

    func testTargetFullStringTargetLess() {
        let target = "2.0.0" as SemanticVersion
        let version = "2.0.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }

    func testTargetFullStringTargetMore() {
        let target = "2.0.1" as SemanticVersion
        let version = "2.0.0" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }

    func testTargetFullStringTargetEq() {
        let target = "2.0.0" as SemanticVersion
        let version = "2.0.0" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) == 0)
    }
    func testTargetMajorPartGreater() {
        let target = "3.0" as SemanticVersion
        let version = "2.0.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }

    func testTargetMajorPartLess() {
        let target = "2.0" as SemanticVersion
        let version = "3.0.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }

    func testTargetMinorPartGreater() {
        let target = "2.3" as SemanticVersion
        let version = "2.0.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }

    func testTargetMinorPartLess() {
        let target = "2.0" as SemanticVersion
        let version = "2.9.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }

    func testTargetMinorPartEqual() {
        let target = "2.9" as SemanticVersion
        let version = "2.9.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) == 0)
    }

    func testTargetPatchGreater() {
        let target = "2.3.5" as SemanticVersion
        let version = "2.3.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }

    func testTargetPatchLess() {
        let target = "2.9.0" as SemanticVersion
        let version = "2.9.1" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }

    func testTargetPatchEqual() {
        let target = "2.9.9" as SemanticVersion
        let version = "2.9.9" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) == 0)
    }

    func testTargetPatchWithBetaTagEqual() {
        let target = "2.9.9-beta" as SemanticVersion
        let version = "2.9.9-beta" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) == 0)
    }

    func testPartialVersionEqual() {
        let target = "2.9.8" as SemanticVersion
        let version = "2.9" as SemanticVersion
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }
    
    func testBetaTagGreater() {
        let target = "2.1.2"
        let version = "2.1.3-beta"
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }
    
    func testBetaToRelease() {
        let target = "2.1.2-release"
        let version = "2.1.2-beta"
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }
    
    func testReleaseToBeta() {
        let version = "2.1.2-release"
        let target = "2.1.2-beta"
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }

    func testTargetWithVersionBetaLess() {
        let target = "2.1.3"
        let version = "2.1.3-beta"
        
        XCTAssert(try version.compareVersion(targetedVersion: target) < 0)
    }

    func testTargetBetaLess() {
        let target = "2.1.3-beta"
        let version = "2.1.3"
        
        XCTAssert(try version.compareVersion(targetedVersion: target) > 0)
    }

    func testOtherTests() {
        let targets = ["2.1", "2.1", "2", "2"]
        let versions = ["2.1.0", "2.1.215", "2.12", "2.785.13"]
        
        for (idx,target) in targets.enumerated() {
            XCTAssert(try versions[idx].compareVersion(targetedVersion: target) == 0)
        }
    }
    
    func testInvalidAttributes() {
        let target = "2.1.0"
        let versions = ["-", ".", "..", "+", "+test", " ", "2 .3. 0", "2.", ".2.2", "3.7.2.2"]
        for (_, version) in versions.enumerated() {
            XCTAssert(((try? (version.compareVersion(targetedVersion: target)) < 0) == nil))
        }
    }
}
