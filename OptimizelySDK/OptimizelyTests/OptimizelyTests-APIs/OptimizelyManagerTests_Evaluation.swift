//
//  OptimizelyManagerTests_Evaluation.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Jae Kim on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Evaluation: XCTestCase {

    let kUserId = "11111"
    
    var datafile: Data!
    var optimizely: OptimizelyManager!
    
    // MARK: - SetUp
    
    override func setUp() {
        super.setUp()
        
        self.datafile = OTUtils.loadJSONDatafile("audience_targeting")
        
        self.optimizely = OptimizelyManager(sdkKey: "12345",
                                            userProfileService: OTUtils.createClearUserProfileService())
        try! self.optimizely.initializeSDK(datafile: datafile)
    }

    func testActivateWithNilAttributeValues() {
        let experimentKey = "ab_running_exp_audience_combo_exact_foo_and_42"
        
        let attributes: [String : Any?] = [
            "s_foo": "foo",
            "b_true": nil,
            "i_42": 44,
            "d_4_2": nil
            ]
        
        let variationKey = try? optimizely.activate(experimentKey: experimentKey, userId: kUserId, attributes: attributes)
        XCTAssertNil(variationKey)
    }
    
    func testActivateWithExactCombo() {
        let experimentKey = "ab_running_exp_audience_combo_exact_foo_and_true__or__42_and_4_2"
        let expectedVariationKey = "all_traffic_variation"

        let attributes: [String: Any] = [
            "s_foo": "foo",
            "b_true": true,
            "i_42": 42,
            "d_4_2": 4.3
        ]
        
        do {
            let variationKey = try optimizely.activate(experimentKey: experimentKey, userId: kUserId, attributes: attributes)
            XCTAssert(variationKey == expectedVariationKey)
        } catch {
            XCTAssert(false)
        }
    }

}
