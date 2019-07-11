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

class OptimizelyClientTests_Valid: XCTestCase {

    // MARK: - Constants
    
    let kExperimentKey = "exp_with_audience"
    
    let kVariationKey = "a"
    let kVariationOtherKey = "b"
    
    let kFeatureKey = "feature_1"
    let kFeatureOtherKey = "feature_2"
    
    let kVariableKeyString = "s_foo"
    let kVariableKeyInt = "i_42"
    let kVariableKeyDouble = "d_4_2"
    let kVariableKeyBool = "b_true"
    
    let kVariableValueString = "foo"
    let kVariableValueInt = 42
    let kVariableValueDouble = 4.2
    let kVariableValueBool = true
    
    let kEventKey = "event1"
    
    let kUserId = "11111"
    
    // MARK: - Properties
    
    var datafile: Data!
    var optimizely: OptimizelyClient!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = OptimizelyClient(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.start(datafile: datafile)
    }
    
    func testMultiStart() {
        try! self.optimizely.start(datafile: datafile)
        try! self.optimizely.start(datafile: datafile)
        DispatchQueue.global().async {
            for _ in 0...10 {
                try! self.optimizely.start(datafile: self.datafile)
            }
        }
        sleep(1)
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)

    }
    
    func testActivate() {
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testActivateEmptyUserId() {
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: "")
        XCTAssert(variationKey == kVariationKey)
    }

    func testGetVariationKey() {
        let variationKey: String = try! self.optimizely.getVariationKey(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testGetForcedVariation() {
        let variationKey: String? = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testSetForcedVariationKey() {
        _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)
        let variationKey: String? = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
    }
    
    func testIsFeatureEnabled() {
        let result = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        XCTAssertTrue(result)
    }
    
    func testGetFeatureVariableBoolean() {
        let result: Bool = try! self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey,
                                                                           variableKey: kVariableKeyBool,
                                                                           userId: kUserId)
        XCTAssert(result == kVariableValueBool)
    }
    
    func testGetFeatureVariableDouble() {
        let result: Double = try! self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey,
                                                                            variableKey: kVariableKeyDouble,
                                                                            userId: kUserId)
        XCTAssert(result == kVariableValueDouble)
    }
    
    func testGetFeatureVariableInteger() {
        let result: Int? = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey,
                                                                          variableKey: kVariableKeyInt,
                                                                          userId: kUserId)
        XCTAssert(result == kVariableValueInt)
    }
    
    func testGetFeatureVariableString() {
        let result: String? = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey,
                                                                            variableKey: kVariableKeyString,
                                                                            userId: kUserId)
        XCTAssert(result == kVariableValueString)
    }
    
    func testGetEnabledFeatures() {
        let result: [String] = self.optimizely.getEnabledFeatures(userId: kUserId)
        XCTAssert(result == [kFeatureKey])
    }
    
    func testTrack() {
        var trackSuccessful = false
        do {
            try self.optimizely.track(eventKey: kEventKey, userId: kUserId)
            trackSuccessful = true
        } catch {
        }
        XCTAssert(trackSuccessful)
    }

}
