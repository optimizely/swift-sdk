//
//  OptimizelyManagerTests_ForcedVariation.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Jae Kim on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_ForcedVariation: XCTestCase {
    
    let kExperimentKey = "exp_with_audience"
    let kVariationKey = "a"
    let kVariationOtherKey = "b"
    let kUserId = "11111"
    
    var datafile: Data!
    var optimizely: OptimizelyManager!
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("api_datafile")
        
        self.optimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.initializeSDK(datafile: datafile)
    }
    
    func testForcedVariation_ThenActivate() {
        
        // get - initially empty
        
        var variationKey: String = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationKey)
        
        // set local forced variation
        
        let _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)

        // get must return forced variation

        variationKey = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
        
        // active must be deterimined by forced variation
        
        variationKey = try! self.optimizely.activate(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssert(variationKey == kVariationOtherKey)
    }

    func testForcedVariation_NotPersistent() {
        
        // get - initially empty
        var variationKey: String? =  self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)

        // set local forced variation
        
        let _ = self.optimizely.setForcedVariation(experimentKey: kExperimentKey,
                                                userId: kUserId,
                                                variationKey: kVariationOtherKey)
        
        // get must return forced variation
        
        variationKey = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)!
        XCTAssert(variationKey == kVariationOtherKey)
        
        // reload ProjectConfig (whitelist must NOT be sustained)
        
        try! self.optimizely.initializeSDK(datafile: datafile)
        variationKey = self.optimizely.getForcedVariation(experimentKey: kExperimentKey, userId: kUserId)
        XCTAssertNil(variationKey)
    }
    
    
}
