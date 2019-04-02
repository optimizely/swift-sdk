//
//  DecisionServiceTests_Others.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/5/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class DecisionServiceTests_Others: XCTestCase {
    
    let ktypeAudienceDatafileName = "typed_audience_datafile"
    let kExperimentWithTypedAudienceKey = "audience_combinations_experiment"

    let kUserId = "6369992312"
    let kAttributeKey = "browser_type"
    let kAttributeValue = "firefox"

    func testUserInExperimentWithValidAudienceIdAndEmptyAudienceConditions() {
        let optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName, clearUserProfileService: true)!
        let config = optimizely.config!
        
        let attributes = [kAttributeKey : kAttributeValue]

        var experiment = optimizely.config!.getExperiment(key: kExperimentWithTypedAudienceKey)!
        experiment.audienceConditions = ConditionHolder.array([])
        let isValid = try! (optimizely.decisionService as! DefaultDecisionService).isInExperiment(config: config,
                                                                                                  experiment: experiment,
                                                                                                  userId: kUserId,
                                                                                                  attributes: attributes)
        XCTAssert(isValid)
    }
    
    // TODO: transfer valid ObjC SDK tests
    

}
