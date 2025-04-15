//
// Copyright 2022, Optimizely, Inc. and contributors 
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

class HoldoutConfigTests: XCTestCase {
    
    func testHoldoutMap() {
        let holdout0: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        let holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedFlags)
        let holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExcludedFlags)
        
        let allHoldouts =  [holdout0, holdout1, holdout2]
        
        
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        XCTAssertEqual(holdoutConfig.holdoutIdMap["11111"]?.includedFlags, [])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["11111"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutConfig.holdoutIdMap["55555"]?.includedFlags, ["4444", "5555"])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["55555"]?.excludedFlags, [])
        
        XCTAssertEqual(holdoutConfig.holdoutIdMap["3333"]?.includedFlags, [])
        XCTAssertEqual(holdoutConfig.holdoutIdMap["3333"]?.excludedFlags, ["8888", "9999"])
        
        
        XCTAssertEqual(holdoutConfig.global, [holdout0])
        XCTAssertEqual(holdoutConfig.others, [holdout2])
        
        XCTAssertEqual(holdoutConfig.includedHoldouts["4444"], [holdout1])
        XCTAssertEqual(holdoutConfig.excludedHoldouts["8888"], [holdout2])
        
    }
    
    func testGetHoldoutById() {
        var holdout0: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout0.id = "00000"
        
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithIncludedFlags)
        holdout1.id = "11111"
        
        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleDataWithExcludedFlags)
        holdout2.id = "22222"
        
        let allHoldouts =  [holdout0, holdout1, holdout2]
        
        
        let holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        XCTAssertEqual(holdoutConfig.getHoldout(id: "00000"), holdout0)
        XCTAssertEqual(holdoutConfig.getHoldout(id: "11111"), holdout1)
        XCTAssertEqual(holdoutConfig.getHoldout(id: "22222"), holdout2)
        
    }
    
    func testGetHoldoutForFlag() {
        
        let flag1 = "11111"
        let flag2 = "22222"
        let flag3 = "33333"
        let flag4 = "44444"
        
        var holdout1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout1.id = "11"
        holdout1.includedFlags = [flag1]
        holdout1.excludedFlags = []
        
        var holdout2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout2.id = "22"
        holdout2.includedFlags = []
        holdout2.excludedFlags = [flag2]
        
        var holdout3: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout3.id = "33"
        holdout3.includedFlags = []
        holdout3.excludedFlags = []
        
        var holdout4: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout4.id = "44"
        holdout4.includedFlags = []
        holdout4.excludedFlags = []
        
        
        let allHoldouts =  [holdout1, holdout2, holdout3, holdout4]
        var holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        // Should maintain order. Global first then lcoal
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag1), [holdout3, holdout4, holdout1])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag2), [holdout3, holdout4])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag3), [holdout3, holdout4, holdout2])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag4), [holdout3, holdout4, holdout2])

    }
    
    
    
}
