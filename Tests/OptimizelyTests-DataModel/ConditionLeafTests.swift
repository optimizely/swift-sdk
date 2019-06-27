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
    

import XCTest

class ConditionLeafTests: XCTestCase {
    
    func testDecodeSample_UserAttribute() {
        let userAttribute: UserAttribute = try! OTUtils.model(from: UserAttributeTests.sampleData)
        let model: ConditionLeaf = try! OTUtils.model(from: UserAttributeTests.sampleData)
        
        XCTAssert(model == ConditionLeaf.attribute(userAttribute))
    }
    
    func testDecodeSample_AudienceId() {
        let audienceId = "12345"
        // JSON does not support raw string, so wrap in array for decode
        let model: [ConditionLeaf] = try! OTUtils.model(from: [audienceId])
        
        XCTAssert(model[0] == ConditionLeaf.audienceId(audienceId))
    }

    func testDecodeSample_Invalid() {
        do {
            let invalidData = 100
            // JSON does not support raw string, so wrap in array for decode
            let _: [ConditionLeaf] = try OTUtils.model(from: [invalidData])
            XCTAssert(false)
        } catch is DecodingError {
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }
    
    func testEvaluate_InvalidProject() {
        let audienceId = "12345"
        // JSON does not support raw string, so wrap in array for decode
        let model: [ConditionLeaf] = try! OTUtils.model(from: [audienceId])

        do {
            let _ = try model[0].evaluate(project: nil, attributes: ["country": "us"])
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

}
