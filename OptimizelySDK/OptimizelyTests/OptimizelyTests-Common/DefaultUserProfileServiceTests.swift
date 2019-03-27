//
//  DefaultUserProfileServiceTests.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/26/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DefaultUserProfileServiceTests: XCTestCase {

    let sampleProfile: [String: Any] = [
        "experiment_bucket_map": [
            "21": [
                "variation_id": "31"
            ],
            "22": [
                "variation_id": "32"
            ]
        ],
        "user_id": "11"
    ]
    
    let sampleProfile2: [String: Any] = [
        "experiment_bucket_map": [
            "61": [
                "variation_id": "71"
            ],
            "62": [
                "variation_id": "72"
            ]
        ],
        "user_id": "51"
    ]

    
    var ups: DefaultUserProfileService!
    var decisionService: DefaultDecisionService!
    
    override func setUp() {
        ups = DefaultUserProfileService()
        ups.reset()
        
        decisionService = DefaultDecisionService(bucketer: DefaultBucketer(), userProfileService: ups)
    }
    
    func testSave() {
        ups.save(userProfile: sampleProfile)
        let variationId = decisionService.getVariationIdFromProfile(userId: "11", experimentId: "21")
        XCTAssert(variationId == "31")
    }

    func testLookup_Found() {
        ups.save(userProfile: sampleProfile)
        let profile = ups.lookup(userId: "11")!
        XCTAssert(profile["user_id"] as! String == "11")
        XCTAssertNotNil(profile["experiment_bucket_map"])
    }
    
    func testLookup_NotFound() {
        ups.save(userProfile: sampleProfile)
        let profile = ups.lookup(userId: "99999")
        XCTAssertNil(profile)
    }

    func testVariationId_Found() {
        ups.save(userProfile: sampleProfile)
        let variationId = decisionService.getVariationIdFromProfile(userId: "11", experimentId: "22")
        XCTAssert(variationId == "32")
    }
    
    func testVariationId_WrongUserId() {
        ups.save(userProfile: sampleProfile)
        let variationId = decisionService.getVariationIdFromProfile(userId: "99999", experimentId: "21")
        XCTAssertNil(variationId)
    }

    func testVariationId_WrongExperimentId() {
        ups.save(userProfile: sampleProfile)
        let variationId = decisionService.getVariationIdFromProfile(userId: "11", experimentId: "99999")
        XCTAssertNil(variationId)
    }
    
    func testSaveProfile_MultipleProfiels() {
        ups.save(userProfile: sampleProfile)
        
        var profile = ups.lookup(userId: "11")
        XCTAssertNotNil(profile)
        profile = ups.lookup(userId: "51")
        XCTAssertNil(profile)

        ups.save(userProfile: sampleProfile2)
        
        profile = ups.lookup(userId: "51")
        XCTAssertNotNil(profile)
    }

    func testSaveProfile_MultipleProfiels2() {
        ups.save(userProfile: sampleProfile)
        
        var variationId = decisionService.getVariationIdFromProfile(userId: "11", experimentId: "21")
        XCTAssert(variationId == "31")
        variationId = decisionService.getVariationIdFromProfile(userId: "51", experimentId: "61")
        XCTAssertNil(variationId)

        ups.save(userProfile: sampleProfile2)
        
        variationId = decisionService.getVariationIdFromProfile(userId: "51", experimentId: "61")
        XCTAssert(variationId == "71")
    }

    func testSaveProfile_NewUserId() {
        ups.save(userProfile: sampleProfile)
        decisionService.saveProfile(userId: "19999", experimentId: "29999", variationId: "39999")
        let variationId = decisionService.getVariationIdFromProfile(userId: "19999", experimentId: "29999")
        XCTAssert(variationId == "39999")
    }
    
    func testSaveProfile_OldUserIdWithNewExperiment() {
        ups.save(userProfile: sampleProfile)
        decisionService.saveProfile(userId: "11", experimentId: "29999", variationId: "39999")
        let variationId = decisionService.getVariationIdFromProfile(userId: "11", experimentId: "29999")
        XCTAssert(variationId == "39999")
    }

    func testSaveProfile_OldUserIdWithOldExperimentWithNewVariation() {
        ups.save(userProfile: sampleProfile)
        decisionService.saveProfile(userId: "11", experimentId: "21", variationId: "39999")
        let variationId = decisionService.getVariationIdFromProfile(userId: "11", experimentId: "21")
        XCTAssert(variationId == "39999")
    }

}
