//
//  File.swift
//  OptimizelySwiftSDK
//
//  Created by Thomas Zurkan on 3/18/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import Foundation
//
//  OptimizelyManagerTests_Evaluation.swift
//  OptimizelyTests-APIs-iOS
//
//  Created by Jae Kim on 3/11/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class OptimizelyManagerTests_Group: XCTestCase {
    
    let kUserId = "q456789"
    
    var datafile: Data?
    var optimizely: OptimizelyManager?
    var eventDispatcher:FakeEventDispatcher?
    
    // MARK: - Attribute Value Range
    
    func testFeatureEnabledMutextGroup() {
        let optimizely = OTUtils.createOptimizely(datafileName: "grouped_experiments",
                                                  clearUserProfileService: true)!
        
        let featureEnabled = try? optimizely.isFeatureEnabled(featureKey: "mutex_group_feature", userId: kUserId)
        XCTAssertTrue(featureEnabled!)
    }
    
}

