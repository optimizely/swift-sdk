//
//  OptimizelyManagerTests_Valid.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Jae Kim on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Valid: XCTestCase {

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
    var optimizely: OptimizelyManager!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.initializeSDK(datafile: datafile)
    }
    
    func testActivate() {
        let variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testGetVariationKey() {
        let variationKey: String = try! self.optimizely.getVariationKey(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
    }
    
    func testGetForcedVariation() {
        do {
            let variationKey: String? = try self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
            XCTAssertNil(variationKey)
        } catch {
            XCTAssert(false)
        }
    }
    
    func testSetForcedVariationKey() {
        try! self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)
        let variationKey: String = try! self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
    }
    
    func testIsFeatureEnabled() {
        let result: Bool = try! self.optimizely.isFeatureEnabled(featureKey: kFeatureKey, userId: kUserId)
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
        let result: [String] = try! self.optimizely.getEnabledFeatures(userId: kUserId)
        XCTAssert(result == [kFeatureKey])
    }
    
    func testTrack() {
        do {
            try self.optimizely.track(eventKey: kEventKey, userId: kUserId)
            XCTAssert(true)
        } catch {
            XCTAssert(false)
        }
    }



}
