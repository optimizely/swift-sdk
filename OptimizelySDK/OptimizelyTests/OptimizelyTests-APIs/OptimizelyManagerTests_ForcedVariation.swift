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

class OptimizelyManagerTests_ForcedVariation: XCTestCase {
    
    let kExperimentKey = "exp_with_audience"
    let kVariationKey = "a"
    let kVariationOtherKey = "b"
    let kUserId = "11111"
    
    var datafile: Data!
    var optimizely: OptimizelyManager!
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    func testForcedVariation_ThenActivate() {
        
        // get - initially empty
        
        var variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
        
        // set local forced variation
        
        let _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)

        // get must return forced variation

        variationKey = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
        
        // active must be deterimined by forced variation
        
        variationKey = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationOtherKey)
    }

    func testForcedVariation_NotPersistent() {
        
        // get - initially empty
        var variationKey: String? =  self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)

        // set local forced variation
        
        let _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)
        
        // get must return forced variation
        
        variationKey = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
        
        // reload ProjectConfig (whitelist must NOT be sustained)
        
        try! self.optimizely.start(datafile: datafile)
        variationKey = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    
}
