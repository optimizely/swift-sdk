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

import XCTest

class DecisionServiceTests_Others: XCTestCase {
    
    let ktypeAudienceDatafileName = "typed_audience_datafile"
    let kExperimentWithTypedAudienceKey = "audience_combinations_experiment"

    let kUserId = "6369992312"
    let kAttributeKey = "browser_type"
    let kAttributeValue = "firefox"

    func testUserInExperimentWithValidAudienceIdAndEmptyAudienceConditions() {
        let optimizely = OTUtils.createOptimizely(datafileName: ktypeAudienceDatafileName,
                                                   clearUserProfileService: true)!
        let config = optimizely.config!
        
        let attributes = [kAttributeKey: kAttributeValue]

        var experiment = optimizely.config!.getExperiment(key: kExperimentWithTypedAudienceKey)!
        experiment.audienceConditions = ConditionHolder.array([])
        let isValid = (optimizely.decisionService as! DefaultDecisionService).isInExperiment(config: config,
                                                                                                  experiment: experiment,
                                                                                                  userId: kUserId,
                                                                                                  attributes: attributes)
        XCTAssert(isValid)
    }
    
    // TODO: transfer valid ObjC SDK tests

}
