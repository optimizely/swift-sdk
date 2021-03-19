//
// Copyright 2019-2021, Optimizely, Inc. and contributors
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

class OptimizelyClientTests_Invalid: XCTestCase {
    let kSdkKey = "12345"
    let kUserId = "11111"
    let kExperimentKey = "e1"
    let kFeatureKey = "f1"
    let kVariationKey = "v1"
    let kVariableKey = "va1"
    let kEventKey  = "ev1"

    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        self.optimizely = OptimizelyClient(sdkKey: kSdkKey)
        
        let invalidDatafile = "{\"version\": \"4\"}"
        try? self.optimizely.start(datafile: invalidDatafile)
    }
}

// MARK: - ManagerNonInitialized

extension OptimizelyClientTests_Invalid {
    
    func testActivate_WhenManagerNonInitialized() {
        let variationKey: String? = try? self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testGetVariationKey_WhenManagerNonInitialized() {
        let variationKey: String? = try? self.optimizely.getVariationKey(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testGetForcedVariation_WhenManagerNonInitialized() {
        let variationKey: String? = self.optimizely.getForcedVariation(experimentKey: kExperimentKey,
                                                                            userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testSetForcedVariationKey_WhenManagerNonInitialized() {
        let result = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                                userId: kUserId,
                                                                variationKey: kVariationKey)
        XCTAssertFalse(result)
    }

    func testIsFeatureEnabled_WhenManagerNonInitialized() {
        let result = self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        XCTAssertFalse(result)
    }
    
    func testGetFeatureVariableBoolean_WhenManagerNonInitialized() {
        let result: Bool? = try? self.optimizely.getFeatureVariableBoolean(featureKey: kFeatureKey,
                                                                           variableKey: kVariableKey,
                                                                           userId: kUserId)
        XCTAssertNil(result)
    }
    
    func testGetFeatureVariableDouble_WhenManagerNonInitialized() {
        let result: Double? = try? self.optimizely.getFeatureVariableDouble(featureKey: kFeatureKey,
                                                                           variableKey: kVariableKey,
                                                                           userId: kUserId)
        XCTAssertNil(result)
    }

    func testGetFeatureVariableInteger_WhenManagerNonInitialized() {
        let result: Int? = try? self.optimizely.getFeatureVariableInteger(featureKey: kFeatureKey,
                                                                           variableKey: kVariableKey,
                                                                           userId: kUserId)
        XCTAssertNil(result)
    }

    func testGetFeatureVariableString_WhenManagerNonInitialized() {
        let result: String? = try? self.optimizely.getFeatureVariableString(featureKey: kFeatureKey,
                                                                           variableKey: kVariableKey,
                                                                           userId: kUserId)
        XCTAssertNil(result)
    }
    
    func testGetFeatureVariableJSON_WhenManagerNonInitialized() {
        let result: OptimizelyJSON? = try? self.optimizely.getFeatureVariableJSON(featureKey: kFeatureKey,
                                                                                  variableKey: kVariableKey,
                                                                                  userId: kUserId)
        XCTAssertNil(result)
    }
    
    func testGetAllFeatureVariables_WhenManagerNonInitialized() {
        let result = try? self.optimizely.getAllFeatureVariables(featureKey: kFeatureKey, userId: kUserId)
        XCTAssertNil(result)
    }
    
    func testGetEnabledFeatures_WhenManagerNonInitialized() {
        let result = self.optimizely.getEnabledFeatures(userId: kUserId)
        XCTAssert(result.count == 0)
    }
    
    func testTrack_WhenManagerNonInitialized() {
        do {
            try self.optimizely.track(eventKey: kEventKey, userId: kUserId)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }
    
}

// MARK: - Invalid Keys

extension OptimizelyClientTests_Invalid {

    func testTrack_WhenEventNotInDatafile() {
        do {
            try self.optimizely.track(eventKey: "somecrazytrackingidthatdoesntexist", userId: kUserId)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

}


