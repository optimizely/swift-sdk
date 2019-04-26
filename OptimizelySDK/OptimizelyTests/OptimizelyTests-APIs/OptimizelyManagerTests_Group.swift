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

import Foundation
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

