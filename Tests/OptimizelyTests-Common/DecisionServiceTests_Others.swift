//
// Copyright 2019-2022, Optimizely, Inc. and contributors
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

class DecisionServiceTests_Others: XCTestCase {
    
    let ktypeAudienceDatafileName = "typed_audience_datafile"
    let kExperimentWithTypedAudienceKey = "audience_combinations_experiment"
    
    let kUserId = "6369992312"
    let kAttributeKey = "browser_type"
    let kAttributeValue = "firefox"
    
    func testDoesMeetAudienceConditionsWithValidAudienceIdAndEmptyAudienceConditions() {
        let optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName, clearUserProfileService: true)!
        let config = optimizely.config!
        
        let attributes = [kAttributeKey: kAttributeValue]
        
        var experiment = optimizely.config!.getExperiment(key: kExperimentWithTypedAudienceKey)!
        experiment.audienceConditions = ConditionHolder.array([])
        let isValid = (optimizely.decisionService as! DefaultDecisionService)
            .doesMeetAudienceConditions(config: config,
                                        experiment: experiment,
                                        userId: kUserId,
                                        attributes: attributes).result!
        XCTAssert(isValid)
    }
    
    func testFindValidatedForcedDecision() {
        let optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName, clearUserProfileService: true)!
        let config = optimizely.config!

        let user = optimizely.createUserContext(userId: kUserId)
        
        let flagKey = "feat_with_var"
        let ruleKey = "feat_with_var_test"
        let variationKeys = [
            "variation_2",
            "11475708558"
        ]
        
        var fdContext: OptimizelyDecisionContext
        var fdForFlag: String
        var fd: DecisionResponse<Variation>
        
        // F-to-D

        fdContext = OptimizelyDecisionContext(flagKey: flagKey)
        fdForFlag = variationKeys[0]
        _ = user.setForcedDecision(context: fdContext, decision: OptimizelyForcedDecision(variationKey: fdForFlag))
        fd = optimizely.decisionService.findValidatedForcedDecision(config: config, user: user, context: fdContext)
        
        XCTAssertEqual(fdForFlag, fd.result!.key)
        XCTAssertEqual("Variation (\(fdForFlag)) is mapped to flag (\(flagKey)) and user (\(kUserId)) in the forced decision map.", fd.reasons.infos![0].reason)
        
        fdForFlag = "invalid"
        _ = user.setForcedDecision(context: fdContext, decision: OptimizelyForcedDecision(variationKey: fdForFlag))
        fd = optimizely.decisionService.findValidatedForcedDecision(config: config, user: user, context: fdContext)

        XCTAssertNil(fd.result)
        XCTAssertEqual("Invalid variation is mapped to flag (\(flagKey)) and user (\(kUserId)) in the forced decision map.", fd.reasons.infos![0].reason)

        // E-to-D
        
        fdContext = OptimizelyDecisionContext(flagKey: flagKey, ruleKey: ruleKey)
        fdForFlag = variationKeys[1]
        _ = user.setForcedDecision(context: fdContext, decision: OptimizelyForcedDecision(variationKey: fdForFlag))
        fd = optimizely.decisionService.findValidatedForcedDecision(config: config, user: user, context: fdContext)
        
        XCTAssertEqual(fdForFlag, fd.result!.key)
        XCTAssertEqual("Variation (\(fdForFlag)) is mapped to flag (\(flagKey)), rule (\(ruleKey)) and user (\(kUserId)) in the forced decision map.", fd.reasons.infos![0].reason)
        
        fdForFlag = "invalid"
        _ = user.setForcedDecision(context: fdContext, decision: OptimizelyForcedDecision(variationKey: fdForFlag))
        fd = optimizely.decisionService.findValidatedForcedDecision(config: config, user: user, context: fdContext)
        
        XCTAssertNil(fd.result)
        XCTAssertEqual("Invalid variation is mapped to flag (\(flagKey)), rule (\(ruleKey)) and user (\(kUserId)) in the forced decision map.", fd.reasons.infos![0].reason)

    }
}
