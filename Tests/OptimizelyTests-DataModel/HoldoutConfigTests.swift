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
    func testEmptyHoldouts_shouldHaveEmptyMaps() {
        let config = HoldoutConfig(allholdouts: [])
        
        XCTAssertTrue(config.holdoutIdMap.isEmpty)
        XCTAssertTrue(config.global.isEmpty)
        XCTAssertTrue(config.includedHoldouts.isEmpty)
        XCTAssertTrue(config.excludedHoldouts.isEmpty)
    }
    
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
        
        XCTAssertEqual(holdoutConfig.global, [holdout0, holdout2])
        
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
    
    func testHoldoutOrdering_globalThenIncluded() {
        var global1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global1.id = "g1"
        
        var global2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global2.id = "g2"
        
        var included: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        included.id = "i1"
        included.includedFlags = ["f"]
        
        var config = HoldoutConfig(allholdouts: [included, global1, global2])
        
        let result = config.getHoldoutForFlag(id: "f").map(\.id)
        XCTAssertEqual(result, ["g1", "g2", "i1"])
    }
    
    func testHoldoutOrdering_with_Both_IncludedAndExcludedFlags() {
        let flag1 = "11111"
        let flag2 = "22222"
        let flag3 = "33333"
        let flag4 = "44444"
        
        var inc: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        inc.id = "i1"
        inc.includedFlags = [flag1]
        
        var exc: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        exc.id = "e1"
        exc.excludedFlags = [flag2]
        
        var gh1: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        gh1.id = "gh1"
        gh1.includedFlags = []
        gh1.excludedFlags = []
        
        var gh2: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        gh2.id = "gh2"
        gh2.includedFlags = []
        gh2.excludedFlags = []
        
        
        let allHoldouts =  [inc, exc, gh1, gh2]
        var holdoutConfig = HoldoutConfig(allholdouts: allHoldouts)
        
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag1), [exc, gh1, gh2, inc])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag2), [gh1, gh2])
        
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag3), [exc, gh1, gh2])
        XCTAssertEqual(holdoutConfig.getHoldoutForFlag(id: flag4), [exc, gh1, gh2])
        
    }
    
    func testExcludedHoldout_shouldNotAppearInGlobalForFlag() {
        var global: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        global.id = "global"
        
        var excluded: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        excluded.id = "excluded"
        excluded.excludedFlags = ["f"]
        
        var config = HoldoutConfig(allholdouts: [global, excluded])
        
        let result = config.getHoldoutForFlag(id: "f").map(\.id)
        XCTAssertEqual(result, ["global"]) // excluded should not appear
    }
    
    func testGetHoldoutForFlag_shouldUseCacheOnSecondCall() {
        var holdout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout.id = "1"
        holdout.excludedFlags = ["f1"]
        
        var config = HoldoutConfig(allholdouts: [holdout])
        
        _ = config.getHoldoutForFlag(id: "f1")
        let writeCountAfterFirst = config.cacheWriteCount
        
        _ = config.getHoldoutForFlag(id: "f1")
        let writeCountAfterSecond = config.cacheWriteCount
        
        XCTAssertEqual(writeCountAfterFirst, 1)
        XCTAssertEqual(writeCountAfterSecond, 1, "Second call should not increase cache write count")
    }
    
    func testHoldoutWithBothIncludedAndExcludedFlags_shouldLogError() {
        class ConfigMockLogger: OPTLogger {
            static var logLevel: OptimizelyLogLevel = .info
            var expectedLog: String = ""
            var logFound = false
            
            required init() {}
            
            func log(level: OptimizelyLogLevel, message: String) {
                if (message == expectedLog) {
                    logFound = true
                }
            }
        }
        
        var holdout: Holdout = try! OTUtils.model(from: HoldoutTests.sampleData)
        holdout.id = "invalid"
        holdout.includedFlags = ["f1"]
        holdout.excludedFlags = ["f2"]
        
        let mockLogger = ConfigMockLogger()
        mockLogger.expectedLog = LogMessage.holdoutToFlagMappingError.description
        
        var config = HoldoutConfig(allholdouts: [])
        config.logger = mockLogger
        
        config.allHoldouts = [holdout]
        
        XCTAssertTrue(mockLogger.logFound)
    }
}
