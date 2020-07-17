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

class OptimizelyClientTests_Decide_Reasons: XCTestCase {
    
    let kUserId = "tester"
    
    var optimizely: OptimizelyClient!
    var user: OptimizelyUserContext!

    override func setUp() {
        super.setUp()
        
        user = OptimizelyUserContext(userId: kUserId)
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      userProfileService: OTUtils.createClearUserProfileService())
        try! optimizely.start(datafile: OTUtils.loadJSONDatafile("decide_datafile")!)
    }
    
}

/*
sdkNotReady
userNotSet
 
featureKeyInvalid
experimentKeyInvalid
 
conditionNoMatchingAudience
conditionInvalidFormat
conditionCannotBeEvaluated
evaluateAttributeInvalidCondition
evaluateAttributeInvalidType
evaluateAttributeValueOutOfRange
evaluateAttributeInvalidFormat
userAttributeInvalidType
userAttributeInvalidMatch
userAttributeNilValue
userAttributeInvalidName
nilAttributeValue
missingAttributeValue
invalidVariableJSON (OptimizelyJSON parsing error)
variableValueInvalid
 
experimentNotRunning
gotVariationFromUserProfile
forcedVariationFound
forcedVariationFoundButInvalid
userMeetsConditionsForTargetingRule
userBucketedIntoTargetingRule
userBucketedIntoEveryoneTargetingRule
userNotBucketedIntoEveryoneTargetingRule
userNotBucketedIntoTargetingRule
userInFeatureExperiment
userNotInFeatureExperiment
userInRollout
userNotInRollout
userBucketedIntoVariationInExperiment
userNotBucketedIntoVariationInExperiment
userBucketedIntoInvalidVariation
userBucketedIntoExperimentInGroup
userNotBucketedIntoExperimentInGroup
userNotBucketedIntoAnyExperimentInGroup userBucketedIntoInvalidExperiment
userNotInExperiment
userReceivedDefaultVariableValue
*/

// MARK: - error messages

extension OptimizelyClientTests_Decide_Reasons {
    
    func testDecideReasons_sdkNotReady() {
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey,
                                      userProfileService: OTUtils.createClearUserProfileService())
        try? optimizely.start(datafile: OTUtils.loadJSONDatafile("unsupported_datafile")!)
        let decision = optimizely.decide(key: "any-key", user: user)

        XCTAssertEqual(decision.reasons, [OptimizelyError.sdkNotReady.reason])
    }
    
    func testDecideReasons_userNotSet() {
        let decision = optimizely.decide(key: "any-key")
        XCTAssertEqual(decision.reasons, [OptimizelyError.userNotSet.reason])
    }
    
    func testDecideReasons_featureKeyInvalid() {
        let key = "invalid-key"
        let decision = optimizely.decide(key: key, user: user)
        XCTAssertEqual(decision.reasons, [OptimizelyError.featureKeyInvalid(key).reason])
    }
    
    func testDecideReasons_experimentKeyInvalid() {
        let key = "invalid-key"
        let decision = optimizely.decide(key: key, user: user, options: [.forExperiment])
        XCTAssertEqual(decision.reasons, [OptimizelyError.experimentKeyInvalid(key).reason])
    }

}

// MARK: - debugging messages ("includeReasons")

extension OptimizelyClientTests_Decide_Reasons {

    func testDecideReasons_experimentNotRunning() {
        let key = "exp_with_audience"
        var experiment = optimizely.config!.getExperiment(key: key)!
        experiment.status = .paused
        optimizely.config!.experimentKeyMap = [key: experiment]

        let decision = optimizely.decide(key: key, user: user, options: [.includeReasons])
        XCTAssertEqual(decision.reasons, [LogMessage.experimentNotRunning(key).reason])
    }
    
}
