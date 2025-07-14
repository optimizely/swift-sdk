//
// Copyright 2022, Optimizely, Inc. and contributors 
// 
// Licensed under the Apache License, Version 2.0 (the "License");  
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at   
// 
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

class BucketTests_BucketToEntity: XCTestCase {
    var optimizely: OptimizelyClient!
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
            "forcedVariations": [:]
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
        self.config = self.optimizely.config
        self.bucketer = ((optimizely.decisionService as! DefaultDecisionService).bucketer as! DefaultBucketer)
    }
    
    func testBucketToEntityWithEmptyGroup() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        self.config.project.groups = []
        
        let fullAllocation = TrafficAllocation(entityId: "entity_123", endOfRange: 10000)
        let bucketedEntityId = bucketer.bucketToEntityId(config: config, experiment: experiment, bucketingId: "id_123", trafficAllocation: [fullAllocation]).result
        XCTAssertEqual(bucketedEntityId, "entity_123")
        
        let zeroAllocation = TrafficAllocation(entityId: "entity_123", endOfRange: 0)
        let nilEntityId = bucketer.bucketToEntityId(config: config, experiment: experiment, bucketingId: "id_123", trafficAllocation: [zeroAllocation]).result
        XCTAssertEqual(nilEntityId, nil)
    }
    
    func testBucketToEntityWithGroupMatched() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        let group: Group =  try! OTUtils.model(from: sampleGroupData)
        self.config.project.groups = [group]
        
        let tests = [["userId": "ppid1", "entityId": "entity1", "expect": "entity1"],
                     ["userId": "ppid2", "entityId": "entity2", "expect": "entity2"],
                     ["userId": "ppid3", "entityId": "entity3", "expect": "entity3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "entityId": "entity4", "expect": "entity4"]]
        
        var entityId: String!
        
        for (idx, test) in tests.enumerated() {
            entityId = bucketer.bucketToEntityId(config: config, experiment: experiment, bucketingId: test["userId"]!, trafficAllocation: [TrafficAllocation(entityId: test["entityId"]!, endOfRange: 10000)]).result
            XCTAssertEqual(test["expect"], entityId, "test[\(idx)] failed")
        }
    }
    
    func testBucketToEntityWithGroupNotMatched() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.trafficAllocation[0].endOfRange = 0
        self.config.project.groups = [group]
        
        let tests = [["userId": "ppid1", "entityId": "entity1", "expect": "entity1"],
                     ["userId": "ppid2", "entityId": "entity2", "expect": "entity2"],
                     ["userId": "ppid3", "entityId": "entity3", "expect": "entity3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "entityId": "entity4", "expect": "entity4"]]
        
        for (_, test) in tests.enumerated() {
            let response: DecisionResponse<String> = bucketer.bucketToEntityId(config: config, experiment: experiment, bucketingId: test["userId"]!, trafficAllocation: [TrafficAllocation(entityId: test["entityId"]!, endOfRange: 10000)])
            XCTAssertEqual(response.result, nil)
        }
    }
    
    func testBucketToEntityWithNoRandoomGroup() {
        experiment = try! OTUtils.model(from: sampleExperimentData)
        self.config.project.experiments = [experiment]
        
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.policy = .overlapping
        self.config.project.groups = [group]
        
        let tests = [["userId": "ppid1", "entityId": "entity1", "expect": "entity1"],
                     ["userId": "ppid2", "entityId": "entity2", "expect": "entity2"],
                     ["userId": "ppid3", "entityId": "entity3", "expect": "entity3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "entityId": "entity4", "expect": "entity4"]]
        
        var entityId: String!
        
        for (idx, test) in tests.enumerated() {
            entityId = bucketer.bucketToEntityId(config: config, experiment: experiment, bucketingId: test["userId"]!, trafficAllocation: [TrafficAllocation(entityId: test["entityId"]!, endOfRange: 10000)]).result
            XCTAssertEqual(test["expect"], entityId, "test[\(idx)] failed")
        }
    }
    
}
