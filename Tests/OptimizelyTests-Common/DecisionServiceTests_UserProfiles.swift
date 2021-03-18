//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class DecisionServiceTests_UserProfiles: XCTestCase {
    
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var decisionService: DefaultDecisionService!
    
    // MARK: - Sample datafile data
    
    let emptyExperimentData: [String: Any] = [
        "id": "11111",
        "key": "empty",
        "status": "Running",
        "layerId": "22222",
        "variations": [],
        "trafficAllocation": [],
        "audienceIds": [],
        "forcedVariations": [:]]
    
    let kUserId = "12345"
    let kExperimentId = "21"
    let kVariationId = "31"
    
    var sampleProfile: [String: Any] { return
        [
            "user_id": kUserId,
            "experiment_bucket_map": [
                kExperimentId: [
                    "variation_id": kVariationId
                ]
            ]
        ]
    }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                   clearUserProfileService: true)
        self.config = self.optimizely.config
        self.decisionService = (optimizely.decisionService as! DefaultDecisionService)
    }
    
}

// MARK: - Test UserProfileService helpers

extension DecisionServiceTests_UserProfiles {
    
    func testGetVariationIdFromProfile() {
        var variatonId = self.decisionService.getVariationIdFromProfile(userId: kUserId, experimentId: kExperimentId)
        XCTAssertNil(variatonId)
        
        self.decisionService.userProfileService.save(userProfile: sampleProfile)
        variatonId = self.decisionService.getVariationIdFromProfile(userId: kUserId, experimentId: kExperimentId)
        XCTAssert(variatonId! == kVariationId)
    }
    
    func testSaveProfile() {
        var variationId = self.decisionService.getVariationIdFromProfile(userId: kUserId, experimentId: kExperimentId)
        XCTAssertNil(variationId)
        
        self.decisionService.saveProfile(userId: kUserId, experimentId: kExperimentId, variationId: kVariationId)
        variationId = self.decisionService.getVariationIdFromProfile(userId: kUserId, experimentId: kExperimentId)
        XCTAssert(variationId! == kVariationId)
    }
    
}
