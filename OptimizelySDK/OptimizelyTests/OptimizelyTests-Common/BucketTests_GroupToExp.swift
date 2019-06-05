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

class BucketTests_GroupToExp: XCTestCase {

    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var bucketer: OPTBucketer!
    
    var kUserId = "12345"
    var kGroupId = "333333"
    
    var kExperimentKey1 = "countryExperiment"
    var kExperimentId1 = "country11"
    var kExperimentKey2 = "ageExperiment"
    var kExperimentId2 = "age11"
    var kExperimentKey3 = "browserExperiment"
    var kExperimentId3 = "browser11"

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
    
    var sampleExperimentData1: [String: Any] { return
        [
            "status": "Running",
            "id": kExperimentId1,
            "key": kExperimentKey1,
            "layerId": "10420273888",
            "trafficAllocation": [],
            "audienceIds": [],
            "variations": [],
            "forcedVariations": [:]
        ]
    }
    
    var sampleExperimentData2: [String: Any] { return
        [
            "status": "Running",
            "id": kExperimentId2,
            "key": kExperimentKey2,
            "layerId": "10420273888",
            "trafficAllocation": [],
            "audienceIds": [],
            "variations": [],
            "forcedVariations": [:]
        ]
    }
    
    var sampleExperimentData3: [String: Any] { return
        [
            "status": "Running",
            "id": kExperimentId3,
            "key": kExperimentKey3,
            "layerId": "10420273888",
            "trafficAllocation": [],
            "audienceIds": [],
            "variations": [],
            "forcedVariations": [:]
        ]
    }
    
    var sampleGroupData: [String: Any] { return
        ["id": kGroupId,
         "policy": "random",
         "trafficAllocation": [
            ["entityId": kExperimentId1, "endOfRange": 3000],
            ["entityId": kExperimentId2, "endOfRange": 6000],
            ["entityId": kExperimentId3, "endOfRange": 10000]
            ],
         "experiments": [sampleExperimentData1, sampleExperimentData2, sampleExperimentData3]
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

// MARK: - bucket to experiment (group)

extension BucketTests_GroupToExp {
    
    func testBucketGroup() {
        self.config.project.groups = [try! OTUtils.model(from: sampleGroupData)]

        let tests = [["userId": "ppid1", "expect": kExperimentKey1],
                     ["userId": "ppid2", "expect": kExperimentKey3],
                     ["userId": "ppid3", "expect": kExperimentKey3],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": kExperimentKey2]]
        
        let group = self.config.getGroup(id: kGroupId)
        
        for (idx, test) in tests.enumerated() {
            let experiment = bucketer.bucketToExperiment(config: self.config, group: group!, bucketingId: test["userId"]!)
            if let _ = test["expect"] {
                XCTAssertEqual(test["expect"], experiment?.key, "test[\(idx)] failed")
            } else {
                XCTAssertNil(experiment)
            }
        }
    }
    
    func testBucketGroupWithTrafficAllocationEmpty() {
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.trafficAllocation = []
        self.config.project.groups = [group]
        
        let tests = [["userId": "ppid1"],
                     ["userId": "ppid2"],
                     ["userId": "ppid3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string"]]
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(config: self.config, group: group, bucketingId: test["userId"]!)
            XCTAssertNil(experiment)
        }
    }
    
    func testBucketGroupWithTrafficAllocationToInvalidExperiment() {
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.trafficAllocation[0].entityId = "99999"
        group.trafficAllocation[0].endOfRange = 10000
        self.config.project.groups = [group]
        
        let tests = [["userId": "ppid1"],
                     ["userId": "ppid2"],
                     ["userId": "ppid3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string"]]
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(config: self.config, group: group, bucketingId: test["userId"]!)
            XCTAssertNil(experiment)
        }
    }
    
    func testBucketGroupWithTrafficAllocationNotAllocated() {
        var group: Group =  try! OTUtils.model(from: sampleGroupData)
        group.trafficAllocation[0].endOfRange = 10
        group.trafficAllocation[1].endOfRange = 20
        group.trafficAllocation[2].endOfRange = 30
        self.config.project.groups = [group]
        
        let tests = [["userId": "ppid1"],
                     ["userId": "ppid2"],
                     ["userId": "ppid3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string"]]
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(config: self.config, group: group, bucketingId: test["userId"]!)
            XCTAssertNil(experiment)
        }
    }

}
