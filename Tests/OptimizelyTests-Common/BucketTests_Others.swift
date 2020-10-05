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

class BucketTests_Others: XCTestCase {

    var config: ProjectConfig?
    
    let testBucketingIdControl = "1291332554"
    let testBucketingIdVariation = "791931608"
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let data = OTUtils.loadJSONDatafile("grouped_experiments")
        config = try? ProjectConfig(datafile: data!)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        config = nil
    }
    
}

// MARK: - murmur-hash compliant

extension BucketTests_Others {

    func testHashIsCompliant() {
        let experimentId = "1886780721"
        let bucketer = DefaultBucketer()
        // These test inputs/outputs should be reproduced exactly in all clients to make sure that they behave
        // consistently.
        let tests = [
            ["userId": "ppid1", "experimentId": experimentId, "expect": 5254],
            ["userId": "ppid2", "experimentId": experimentId, "expect": 4299],
            // Same PPID as previous, diff experiment ID
            ["userId": "ppid2", "experimentId": "1886780722", "expect": 2434],
            ["userId": "ppid3", "experimentId": experimentId, "expect": 5439],
            ["userId": "a very very very very very very very very very very very very very very very long ppd string", "experimentId": experimentId, "expect": 6128]]
        
        for test in tests {
            let hashId = bucketer.makeHashIdFromBucketingId(bucketingId:test["userId"] as! String, entityId:test["experimentId"] as! String)
            let bucketingValue = bucketer.generateBucketValue(bucketingId: hashId)
            
            XCTAssertEqual(test["expect"] as! Int, bucketingValue)
        }
    }
    
}

// MARK: - bucket to experiment (group)

extension BucketTests_Others {
    
    func testBucketGroupWithOneAllocation() {
        let groupId = "12115595439"
        let bucketer = DefaultBucketer()
        
        let tests = [["userId": "ppid1", "expect": "all_traffic_experiment"],
                     ["userId": "ppid2", "expect": "all_traffic_experiment"],
                     ["userId": "ppid3", "expect": "all_traffic_experiment"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": "all_traffic_experiment"]]
        
        let group = config?.getGroup(id: groupId)
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(config: config!, group: group!, bucketingId: test["userId"]!)
            XCTAssertEqual(test["expect"]!, experiment?.key)
        }
    }
    
    func testBucketGroupWithNoTrafficAllocation() {
        // this group has no traffic allocation
        let groupId = "12250460410"
        let bucketer = DefaultBucketer()
        
        let tests = [["userId": "ppid1"],
                     ["userId": "ppid2"],
                     ["userId": "ppid3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string"]]
        
        let group = config?.getGroup(id: groupId)
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(config: config!, group: group!, bucketingId: test["userId"]!)
            XCTAssertNil(experiment)
        }
    }

    func testBucketToExperimentInGroup() {
        let optimizely = OTUtils.createOptimizely(datafileName: "grouped_experiments",
                                                  clearUserProfileService: true)!
        
        let experimentKey = "experiment_4000"
        let userIdForThisTestOnly = "ppid31886780721"
        
        let expectedVariationKey = "all_traffic_variation_exp_1"
        
        let variationKey = try! optimizely.activate(experimentKey: experimentKey, userId: userIdForThisTestOnly)
        XCTAssert(variationKey == expectedVariationKey)
        
    }
    
}

// MARK: - bucket to variation (experiment)

extension BucketTests_Others {
    
    func testBucketToVariationInExperiment() {
    }
    
    func testBucketExperiment() {
    }
    
    func testBucketToVariation() {
        let experimentData: [String: Any] = [
            "id": "1886780721",
            "key": "Basic_Experiment",
            "layerId": "1234",
            "status": "Running",
            "audienceIds": [String](),
            "forcedVariations": [String: Any](),
            "variations": [
                ["id": "6030714421",
                 "key": "Variation_A",
                 "variables": [Any]()],
                ["id": "6030714422",
                 "key": "Variation_B",
                 "variables": [Any]()]
            ],
            "trafficAllocation": [
                ["entityId": "6030714421",
                 "endOfRange": 5000],
                ["entityId": "6030714422",
                 "endOfRange": 10000]
            ]
            ]
        
        let experiment: Experiment = try! OTUtils.model(from: experimentData)
        
        let bucketer = DefaultBucketer()
        
        // These test inputs/outputs should be reproduced exactly in all clients to make sure that they behave
        // consistently.
        let tests = [["userId": "ppid1", "expect": "Variation_B"],
                     ["userId": "ppid2", "expect": "Variation_A"],
                     ["userId": "ppid3", "expect": "Variation_B"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": "Variation_B"]]

        for test in tests {
            let variation = bucketer.bucketToVariation(experiment: experiment, bucketingId: test["userId"]!)!
            XCTAssert(variation.key == test["expect"])
        }
    }
    
}

// MARK: - bucket to experiment (group) + variation (experiment)

extension BucketTests_Others {

    func testBucketExperimentInMutexGroup() {        
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketer_test", clearUserProfileService: true)!
        let group = optimizely.config!.getGroup(id: "1886780721")!

        let bucketer = DefaultBucketer()

        // These test inputs/outputs should be reproduced exactly in all clients to make sure that they behave
        // consistently.
        let tests = [["userId": "ppid1", "expect": "experiment2"],
                     ["userId": "ppid2", "expect": "experiment1"],
                     ["userId": "ppid3", "expect": "experiment2"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": "null"]]

        for test in tests {
            let experiment = bucketer.bucketToExperiment(config: optimizely.config!, group: group, bucketingId: test["userId"]!)
            let expected = test["expect"]
            if expected != "null" {
                XCTAssert(experiment!.key == expected)
            } else {
                XCTAssertNil(experiment)
            }
        }
     }

    func testBucketReturnsNilWhenExperimentIsExcludedFromMutex() {
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketer_test", clearUserProfileService: true)!
        let config = optimizely.config!
        let bucketer = DefaultBucketer()

        // These test inputs/outputs should be reproduced exactly in all clients to make sure that they behave
        // consistently.
        let tests = [["userId": "ppid1", "experiment": "experiment2", "expect": "variationOfExperiment2"],
                     ["userId": "ppid2", "experiment": "experiment1", "expect": "variationOfExperiment1"],
                     ["userId": "ppid3", "experiment": "experiment2", "expect": "variationOfExperiment2"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string", "experiment": "null", "expect": "null"]]

        let experiment1 = config.getExperiment(key: "experiment1")!
        let experiment2 = config.getExperiment(key: "experiment2")!

        for test in tests {
            if test["experiment"] == "experiment1" {
                var variation = bucketer.bucketExperiment(config: config, experiment: experiment1, bucketingId: test["userId"]!)
                XCTAssertNotNil(variation)
                XCTAssert(variation!.key == test["expect"])
                variation = bucketer.bucketExperiment(config: config, experiment: experiment2, bucketingId: test["userId"]!)
                XCTAssertNil(variation)
            } else if test["experiment"] == "experiment2" {
                var variation = bucketer.bucketExperiment(config: config, experiment: experiment2, bucketingId: test["userId"]!)
                XCTAssertNotNil(variation)
                XCTAssert(variation!.key == test["expect"])
                variation = bucketer.bucketExperiment(config: config, experiment: experiment1, bucketingId: test["userId"]!)
                XCTAssertNil(variation)
            } else {
                var variation = bucketer.bucketExperiment(config: config, experiment: experiment1, bucketingId: test["userId"]!)
                XCTAssertNil(variation)
                variation = bucketer.bucketExperiment(config: config, experiment: experiment2, bucketingId: test["userId"]!)
                XCTAssertNil(variation)
            }
        }
    }

    func testBucketExperimentWithMutexDoesNotChangeExperimentReference() {
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketer_test", clearUserProfileService: true)!
        let config = optimizely.config!
        let bucketer = DefaultBucketer()

        let experiment = config.getExperiment(key: "experiment2")!
        XCTAssertNotNil(experiment)
        let variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: "user")
        XCTAssertNil(variation)
    }

    func testBucketWithBucketingId() {
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketer_test2", clearUserProfileService: true)!
        let config = optimizely.config!
        let bucketer = DefaultBucketer()
        
        let experiment = config.getExperiment(key: "test_experiment")!
        XCTAssertNotNil(experiment)
    
        // check testBucketingIdControl is bucketed into "control" variation
        var variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: testBucketingIdControl)
        XCTAssertNotNil(variation)
        XCTAssert(variation!.key == "control", "Unexpected variationKey")
        
        // check testBucketingIdVariation is bucketed into "variation" variation
        variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: testBucketingIdVariation)
        XCTAssertNotNil(variation)
        XCTAssert(variation!.key == "variation", "Unexpected variationKey")
    }

    func testBucketVariationGroupedExperimentsWithBucketingId() {
        // make sure that bucketing works with experiments in group
        
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketer_test2", clearUserProfileService: true)!
        let config = optimizely.config!
        let bucketer = DefaultBucketer()

        var experiment = config.getExperiment(key: "group_experiment_2")!
        XCTAssertNotNil(experiment)
        var variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: testBucketingIdVariation)
        XCTAssertNotNil(variation)
        XCTAssert(variation!.key == "group_exp_2_var_2")
    
        experiment = config.getExperiment(key: "group_experiment_1")!
        XCTAssertNotNil(experiment)
        variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: testBucketingIdVariation)
        XCTAssertNil(variation)

        experiment = config.getExperiment(key: "group_experiment_2")!
        XCTAssertNotNil(experiment)
        variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: "testUserId")
        XCTAssertNotNil(variation)
        XCTAssert(variation!.key == "group_exp_2_var_1")

        experiment = config.getExperiment(key: "group_experiment_1")!
        XCTAssertNotNil(experiment)
        variation = bucketer.bucketExperiment(config: config, experiment: experiment, bucketingId: "testUserId")
        XCTAssertNil(variation)
    }

    func testBucketVariationAtBoundaries() {
        // testing #OASIS-7150
        // userId(2113143589306368718) + experId(18513703488) = “211314358930636871818513703488” creates a hash value of 0
        
        let optimizely = OTUtils.createOptimizely(datafileName: "bucketer_test3", clearUserProfileService: true)!
        
        XCTAssertFalse(optimizely.isFeatureEnabled(featureKey: "async_payments", userId: "2113143589306368718"))
        XCTAssertFalse(optimizely.isFeatureEnabled(featureKey: "async_payments", userId: "2113143589306368719"))
        XCTAssertFalse(optimizely.isFeatureEnabled(featureKey: "async_payments", userId: "2113143589306368710"))
        XCTAssertFalse(optimizely.isFeatureEnabled(featureKey: "async_payments", userId: "2113143589306368711"))
        XCTAssertFalse(optimizely.isFeatureEnabled(featureKey: "async_payments", userId: "2113143589306368712"))
    }
}
