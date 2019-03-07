//
//  OptimizelyManagerTests_Invalid.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/7/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Invalid: XCTestCase {
    let kSdkKey = "12345"
    let kUserId = "11111"
    let kExperimentKey = "e1"
    let kFeatureKey = "f1"
    let kVariationKey = "v1"
    let kVariableKey = "va1"
    let kEventKey  = "ev1"

    var optimizely: OptimizelyManager!

    override func setUp() {
        super.setUp()
        
        self.optimizely = OptimizelyManager(sdkKey: kSdkKey)
        
        let invalidDatafile = "{\"version\": \"4\"}"
        try? self.optimizely.initializeSDK(datafile: invalidDatafile)
    }
    
    func testActivate_WhenManagerNonInitialized() {
        let variationKey: String? = try? self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testGetVariationKey_WhenManagerNonInitialized() {
        let variationKey: String? = try? self.optimizely.getVariationKey(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    func testGetForcedVariation_WhenManagerNonInitialized() {
        let variationKey: String? = try? self.optimizely.getForcedVariation(experimentKey: kExperimentKey,
                                                                            userId: kUserId)!
        XCTAssertNil(variationKey)
    }
    
    func testSetVariationKey_WhenManagerNonInitialized() {
        do {
            try self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                             userId: kUserId,
                                                             variationKey: kVariationKey)
            XCTAssert(false)
        } catch {
            XCTAssert(true)
        }
    }

    func testIsFeatureEnabled_WhenManagerNonInitialized() {
        let result: Bool? = try? self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
        XCTAssertNil(result)
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
    
    func testGetEnabledFeatures_WhenManagerNonInitialized() {
        let result: [String]? = try? self.optimizely.getEnabledFeatures(userId: kUserId)
        XCTAssertNil(result)
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
