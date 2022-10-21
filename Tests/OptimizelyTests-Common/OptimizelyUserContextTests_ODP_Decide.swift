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

class OptimizelyUserContextTests_ODP_Decide: XCTestCase {

    var optimizely: OptimizelyClient!
    var user: OptimizelyUserContext!
    let kUserId = "tester"
    let kFlagKey = "flag-segment"

    override func setUp() {
        let datafile = OTUtils.loadJSONDatafile("decide_audience_segments")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey, defaultLogLevel: .info)
        try! optimizely.start(datafile: datafile)
        user = optimizely.createUserContext(userId: kUserId)
    }
        
    func testDecideWithQualifiedSegments_segmentHitInABTest() {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = ["odp-segment-1", "odp-segment-none"]
        
        let decision = user.decide(key: kFlagKey, options: [.ignoreUserProfileService])
        
        XCTAssertEqual(decision.variationKey, "variation-a")
    }
    
    func testDecideWithQualifiedSegments_otherAudienceHitInABTest() {
        user = optimizely.createUserContext(userId: kUserId, attributes: ["age": 30])
        user.qualifiedSegments = ["odp-segment-none"]
        
        let decision = user.decide(key: kFlagKey, options: [.ignoreUserProfileService])
        
        XCTAssertEqual(decision.variationKey, "variation-a")
    }

    func testDecideWithQualifiedSegments_segmentHitInRollout() {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = ["odp-segment-2"]
        
        let decision = user.decide(key: kFlagKey, options: [.ignoreUserProfileService])
        
        XCTAssertEqual(decision.variationKey, "rollout-variation-on")
    }

    func testDecideWithQualifiedSegments_segmentMissInRollout() {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = ["odp-segment-none"]
        
        let decision = user.decide(key: kFlagKey, options: [.ignoreUserProfileService])
        
        XCTAssertEqual(decision.variationKey, "rollout-variation-off")
    }
    
    func testDecideWithQualifiedSegments_emptySegments() {
        user = optimizely.createUserContext(userId: kUserId)
        user.qualifiedSegments = []

        let decision = user.decide(key: kFlagKey, options: [.ignoreUserProfileService])
        
        XCTAssertEqual(decision.variationKey, "rollout-variation-off")
    }

    func testDecideWithQualifiedSegments_default() {
        user = optimizely.createUserContext(userId: kUserId)

        let decision = user.decide(key: kFlagKey, options: [.ignoreUserProfileService])
        
        XCTAssertEqual(decision.variationKey, "rollout-variation-off")
    }

}
