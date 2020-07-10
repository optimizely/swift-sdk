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

class OptimizelyClientTests_Decide: XCTestCase {

    let kUserId = "tester"
    
    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("decide_datafile")!

        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    func testDecide_feature() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = try! optimizely.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssertNil(decision.reasons)
    }
    
    func testDecide_experiment() {
        let experimentKey = "exp_with_audience"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = try! optimizely.decide(key: experimentKey)
        
        XCTAssertEqual(decision.variationKey, "a")
        XCTAssertNil(decision.enabled)
        XCTAssertNil(decision.variables)
        
        XCTAssertEqual(decision.key, experimentKey)
        XCTAssertEqual(decision.user, user)
        XCTAssertNil(decision.reasons)
    }
    
    func testDecide_featureAndExperimentNameConflict() {
        let featureKey = "common_name"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = try! optimizely.decide(key: featureKey)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, false)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssertNil(decision.reasons)
    }

    func testDecide_userInParameter() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)

        let user = OptimizelyUserContext(userId: kUserId)

        let decision = try! optimizely.decide(key: featureKey, user: user)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user)
        XCTAssertNil(decision.reasons)
    }
    
    func testDecide_userInParameterOverriding() {
        let featureKey = "feature_1"
        let variablesExpected = try! optimizely.getAllFeatureVariables(featureKey: featureKey, userId: kUserId)
        
        let user1 = OptimizelyUserContext(userId: kUserId)
        let user2 = OptimizelyUserContext(userId: "newUser")
        try? optimizely.setUserContext(user1)
        let decision = try! optimizely.decide(key: featureKey, user: user2)
        
        XCTAssertNil(decision.variationKey)
        XCTAssertEqual(decision.enabled, true)
        let variables = decision.variables!
        XCTAssertTrue(NSDictionary(dictionary: variables.toMap()).isEqual(to: variablesExpected.toMap()))
        
        XCTAssertEqual(decision.key, featureKey)
        XCTAssertEqual(decision.user, user2)
        XCTAssertNil(decision.reasons)
    }
}
    
// MARK: - errors
  
extension OptimizelyClientTests_Decide {
    
    func testDecide_sdkNotReady() {
        let featureKey = "feature_1"

        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        do {
            _ = try optimizely.decide(key: featureKey)
            XCTAssert(false)
        } catch {
            XCTAssertEqual(error.localizedDescription, OptimizelyError.sdkNotReady.reason)
        }
    }
    
    func testDecide_userNotSet() {
        let featureKey = "feature_1"

        do {
            _ = try optimizely.decide(key: featureKey)
            XCTAssert(false)
        } catch {
            XCTAssertEqual(error.localizedDescription, OptimizelyError.userNotSet.reason)
        }
    }

    func testDecide_invalidFeatureKey() {
        let featureKey = "invalid_key"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        do {
            _ = try optimizely.decide(key: featureKey)
            XCTAssert(false)
        } catch {
            XCTAssertEqual(error.localizedDescription, OptimizelyError.featureKeyInvalid(featureKey).reason)
        }
    }
    
    func testDecide_invalidExperimentKey() {
        let experimentKey = "invalid_key"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        do {
            _ = try optimizely.decide(key: experimentKey, options: [.forExperiment])
            XCTAssert(false)
        } catch {
            XCTAssertEqual(error.localizedDescription, OptimizelyError.experimentKeyInvalid(experimentKey).reason)
        }
    }

}

// MARK: - reasons
  
extension OptimizelyClientTests_Decide {

}

// MARK: - options

extension OptimizelyClientTests_Decide {
    
    func testDecideOptions_forExperiment() {
        let commonKey = "common_name"

        let user = OptimizelyUserContext(userId: kUserId)
        try? optimizely.setUserContext(user)
        let decision = try! optimizely.decide(key: commonKey, options: [.forExperiment])
        
        XCTAssertEqual(decision.variationKey, "variation_a")
        XCTAssertNil(decision.enabled)
        XCTAssertNil(decision.variables)
        
        XCTAssertEqual(decision.key, commonKey)
        XCTAssertEqual(decision.user, user)
        XCTAssertNil(decision.reasons)
    }

}
