//
//  DefaultUserProfileServiceTests.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 2/26/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DefaultUserProfileServiceTests: XCTestCase {

    let sampleData = [
        "11": [
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
    ]
    
    var ups: DefaultUserProfileService!
    
    override func setUp() {
        ups = DefaultUserProfileService()
    }
    
    func testSave() {
        ups.save(userProfile: sampleData)
        let variationId = ups.variationId(userId: "11", experimentId: "21")
        XCTAssert(variationId == "31")
    }

    func testLookup_Found() {
        ups.save(userProfile: sampleData)
        let profile = ups.lookup(userId: "11")!
        XCTAssert(profile["user_id"] as! String == "11")
        XCTAssertNotNil(profile["experiment_bucket_map"])
    }
    
    func testLookup_NotFound() {
        ups.save(userProfile: sampleData)
        let profile = ups.lookup(userId: "99999")
        XCTAssertNil(profile)
    }

    func testVariationId_Found() {
        ups.save(userProfile: sampleData)
        let variationId = ups.variationId(userId: "11", experimentId: "22")
        XCTAssert(variationId == "32")
    }
    
    func testVariationId_WrongUserId() {
        ups.save(userProfile: sampleData)
        let variationId = ups.variationId(userId: "99999", experimentId: "21")
        XCTAssertNil(variationId)
    }

    func testVariationId_WrongExperimentId() {
        ups.save(userProfile: sampleData)
        let variationId = ups.variationId(userId: "11", experimentId: "99999")
        XCTAssertNil(variationId)
    }

    func testSaveProfile_NewUserId() {
        ups.save(userProfile: sampleData)
        ups.saveProfile(userId: "19999", experimentId: "29999", variationId: "39999")
        let variationId = ups.variationId(userId: "19999", experimentId: "29999")
        XCTAssert(variationId == "39999")
    }
    
    func testSaveProfile_OldUserIdWithNewExperiment() {
        ups.save(userProfile: sampleData)
        ups.saveProfile(userId: "11", experimentId: "29999", variationId: "39999")
        let variationId = ups.variationId(userId: "11", experimentId: "29999")
        XCTAssert(variationId == "39999")
    }

    func testSaveProfile_OldUserIdWithOldExperimentWithNewVariation() {
        ups.save(userProfile: sampleData)
        ups.saveProfile(userId: "11", experimentId: "21", variationId: "39999")
        let variationId = ups.variationId(userId: "11", experimentId: "21")
        XCTAssert(variationId == "39999")
    }

}
