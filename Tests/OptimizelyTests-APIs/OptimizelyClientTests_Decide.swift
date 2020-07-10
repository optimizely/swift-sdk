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
        
        let datafile = OTUtils.loadJSONDatafile("api_datafile")!

        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                           userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    func testDecideFeature() {
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
    
    func testDecideExperiment() {
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
            XCTAssertEqual(error.localizedDescription, OptimizelyError.sdkNotReady.reason)
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


    // MARK: - options


}
