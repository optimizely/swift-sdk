//
// Copyright 2021, Optimizely, Inc. and contributors 
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

import XCTest

class DecisionReasonsTests: XCTestCase {

    func testReasons() {
        let r1 = DecisionReasons()
        r1.addError(OptimizelyError.sdkNotReady)
        r1.addInfo(OptimizelyError.dataFileInvalid)
        let r2 = DecisionReasons()
        r2.addError(OptimizelyError.featureKeyInvalid("key"))
        r2.addInfo(OptimizelyError.invalidJSONVariable)

        r1.merge(r2)
        XCTAssert(r1.errors.count == 2)
        XCTAssert(r1.infos?.count == 2)
        XCTAssert(r2.errors.count == 1)
        XCTAssert(r2.infos?.count == 1)
        XCTAssert(r1.toReport() == [OptimizelyError.sdkNotReady.reason,
                                    OptimizelyError.featureKeyInvalid("key").reason,
                                    OptimizelyError.dataFileInvalid.reason,
                                    OptimizelyError.invalidJSONVariable.reason])
    }
    
    func testReasons_notIncludeInfos() {
        let r1 = DecisionReasons(includeInfos: false)
        r1.addError(OptimizelyError.sdkNotReady)
        r1.addInfo(OptimizelyError.dataFileInvalid)
        let r2 = DecisionReasons()
        r2.addError(OptimizelyError.featureKeyInvalid("key"))
        r2.addInfo(OptimizelyError.invalidJSONVariable)

        r1.merge(r2)
        XCTAssert(r1.errors.count == 2)
        XCTAssertNil(r1.infos)
        XCTAssert(r1.toReport() == [OptimizelyError.sdkNotReady.reason,
                                    OptimizelyError.featureKeyInvalid("key").reason])
    }
    
    func testReasons_MergeNotIncludeInfos() {
        let r1 = DecisionReasons()
        r1.addError(OptimizelyError.sdkNotReady)
        r1.addInfo(OptimizelyError.dataFileInvalid)
        let r2 = DecisionReasons(includeInfos: false)
        r2.addError(OptimizelyError.featureKeyInvalid("key"))
        r2.addInfo(OptimizelyError.invalidJSONVariable)

        r1.merge(r2)
        XCTAssert(r1.errors.count == 2)
        XCTAssert(r1.infos?.count == 1)
        XCTAssert(r1.toReport() == [OptimizelyError.sdkNotReady.reason,
                                    OptimizelyError.featureKeyInvalid("key").reason,
                                    OptimizelyError.dataFileInvalid.reason])
    }


}
