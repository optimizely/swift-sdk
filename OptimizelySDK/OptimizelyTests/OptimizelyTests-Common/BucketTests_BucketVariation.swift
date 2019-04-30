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

class BucketTests_BucketVariation: XCTestCase {

    var optimizely: OptimizelyManager!
    var config: ProjectConfig!
    var bucketer: DefaultBucketer!
    
    var kUserId = "12345"
    var kGroupId = "333333"
    var kExperimentId = "444444"

    var kExperimentKey = "countryExperiment"
    
    var kVariationKeyA = "a"
    var kVariationKeyB = "b"
    var kVariationKeyC = "c"
    var kVariationKeyD = "d"
    
    var kVariationIdA = "a11"
    var kVariationIdB = "b11"
    var kVariationIdC = "c11"
    var kVariationIdD = "d11"

    var kAudienceIdCountry = "10"
    var kAudienceIdAge = "20"
    var kAudienceIdInvalid = "9999999"
    
    var kAttributesCountryMatch: [String: Any] = ["country": "us"]
    var kAttributesCountryNotMatch: [String: Any] = ["country": "ca"]
    var kAttributesAgeMatch: [String: Any] = ["age": 30]
    var kAttributesAgeNotMatch: [String: Any] = ["age": 10]
    var kAttributesEmpty: [String: Any] = [:]
    
    var experiment: Experiment!
    var variation: Variation!
    
    
    // MARK: - Sample datafile data
    
    var sampleExperimentData: [String: Any] { return
        [
            "status": "Running",
            "id": kExperimentId,
            "key": kExperimentKey,
            "layerId": "10420273888",
            "trafficAllocation": [
                ["entityId": kVariationIdA, "endOfRange": 2500],
                ["entityId": kVariationIdB, "endOfRange": 5000],
                ["entityId": kVariationIdC, "endOfRange": 7500],
                ["entityId": kVariationIdD, "endOfRange": 10000]
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                [
                    "variables": [],
                    "id": kVariationIdA,
                    "key": kVariationKeyA
                ],
                [
                    "variables": [],
                    "id": kVariationIdB,
                    "key": kVariationKeyB
                ],
                [
                    "variables": [],
                    "id": kVariationIdC,
                    "key": kVariationKeyC
                ],
                [
                    "variables": [],
                    "id": kVariationIdD,
                    "key": kVariationKeyD
                ]
            ],
            "forcedVariations":[:],
        ]
    }
    
    var sampleGroupData: [String: Any] { return
        ["id": kGroupId,
         "policy": "random",
         "trafficAllocation": [
            ["entityId": kExperimentId, "endOfRange": 10000]
            ],
         "experiments": [sampleExperimentData]
        ]
    }

    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                   clearUserProfileService: true)
        self.config = self.optimizely.config!
        self.bucketer = ((optimizely.decisionService as! DefaultDecisionService).bucketer as! DefaultBucketer)
    }
    
}

// MARK: - bucket to variation (experiment)

extension BucketTests_BucketVariation {
    
    func testBucketExperimentWithEmptyGroup() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        self.config.project.groups = []

        let tests = [["userId": "ppid1", "expect": kVariationKeyB],
                     ["userId": "ppid2", "expect": kVariationKeyD],
                     ["userId": "ppid3", "expect": kVariationKeyA],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": kVariationKeyC]]

        for (idx, test) in tests.enumerated() {
            variation = bucketer.bucketExperiment(config: self.config, experiment: experiment, bucketingId: test["userId"]!)
            if let _ = test["expect"] {
                XCTAssertEqual(test["expect"], variation?.key, "test[\(idx)] failed")
            } else {
                XCTAssertNil(experiment);
            }
        }
    }
    
    func testBucketExperimentWithGroupMatched() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        let group: Group =  try! OTUtils.model(from: sampleGroupData)
        self.config.project.groups = [group]

        
        let tests = [["userId": "ppid1", "expect": kVariationKeyB],
                     ["userId": "ppid2", "expect": kVariationKeyD],
                     ["userId": "ppid3", "expect": kVariationKeyA],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": kVariationKeyC]]

        for (idx, test) in tests.enumerated() {
            variation = bucketer.bucketExperiment(config: self.config, experiment: experiment, bucketingId: test["userId"]!)
            if let _ = test["expect"] {
                XCTAssertEqual(test["expect"], variation?.key, "test[\(idx)] failed")
            } else {
                XCTAssertNil(experiment);
            }
        }
    }
    
    func testBucketExperimentWithGroupNotMatched() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.trafficAllocation[0].endOfRange = 0
        self.config.project.groups = [group]

        let tests = [["userId": "ppid1", "expect": kVariationKeyC],
                     ["userId": "ppid2", "expect": kVariationKeyC],
                     ["userId": "ppid3", "expect": kVariationKeyA],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": kVariationKeyD]]
        
        for test in tests {
            variation = bucketer.bucketExperiment(config: self.config, experiment: experiment, bucketingId: test["userId"]!)
            XCTAssertNil(variation)
        }
    }
    
    func testBucketExperimentWithGroupNotRandom() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.policy = .overlapping
        self.config.project.groups = [group]
        
        
        let tests = [["userId": "ppid1", "expect": kVariationKeyB],
                     ["userId": "ppid2", "expect": kVariationKeyD],
                     ["userId": "ppid3", "expect": kVariationKeyA],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": kVariationKeyC]]

        for (idx, test) in tests.enumerated() {
            variation = bucketer.bucketExperiment(config: self.config, experiment: experiment, bucketingId: test["userId"]!)
            if let _ = test["expect"] {
                XCTAssertEqual(test["expect"], variation?.key, "test[\(idx)] failed")
            } else {
                XCTAssertNil(experiment);
            }
        }
    }
    
}
