//
//  BucketTests.swift
//  OptimizelySDKTests
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import XCTest

class BucketTests: XCTestCase {

    var config:ProjectConfig?
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let data = OTUtils.loadJSONDatafile("grouped_experiments")
        do {
            config = try ProjectConfig(datafile: data!)
        }
        catch {
            print(error.localizedDescription)
        }
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        config = nil
    }
    
    func testBucketGroupWithOneAllocation() {
        let groupId = "12115595439"
        let bucketer = DefaultBucketer(config: config!)
        
        let tests = [["userId": "ppid1","expect": "all_traffic_experiment"],
        ["userId": "ppid2", "expect": "all_traffic_experiment"],
        ["userId": "ppid3", "expect": "all_traffic_experiment"],
        ["userId": "a very very very very very very very very very very very very very very very long ppd string", "expect": "all_traffic_experiment"]]
        
        let group = config?.getGroup(id: groupId)
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(group: group!, bucketingId: test["userId"]!)
            if let _ = test["expect"] {
                XCTAssertEqual(test["expect"]!, experiment?.key)
            }
            else {
                XCTAssertNil(experiment);
            }
        }
        
    }

    func testBucketGroupWithNoAllocation() {
        let groupId = "12250460410"
        let bucketer = DefaultBucketer(config: config!)
        
        let tests = [["userId": "ppid1"],
                     ["userId": "ppid2"],
                     ["userId": "ppid3"],
                     ["userId": "a very very very very very very very very very very very very very very very long ppd string"]]
        
        let group = config?.getGroup(id: groupId)
        
        for test in tests {
            let experiment = bucketer.bucketToExperiment(group: group!, bucketingId: test["userId"]!)
            XCTAssertNil(experiment);
        }
        
    }

    func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
        let experimentId = "1886780721"
        let bucketer = DefaultBucketer(config: ProjectConfig())
        // These test inputs/outputs should be reproduced exactly in all clients to make sure that they behave
        // consistently.
        let tests = [
            ["userId": "ppid1", "experimentId": experimentId, "expect": 5254],
            ["userId": "ppid2", "experimentId": experimentId, "expect": 4299],
            // Same PPID as previous, diff experiment ID
            ["userId": "ppid2", "experimentId": "1886780722", "expect": 2434],
            ["userId": "ppid3", "experimentId": experimentId, "expect": 5439],
            ["userId": "a very very very very very very very very very very very very very very very long ppd string", "experimentId": experimentId, "expect": 6128]];
        
        for test in tests {
            let hashId = bucketer.makeHashIdFromBucketingId(bucketingId:test["userId"] as! String, entityId:test["experimentId"] as! String)
            let bucketingValue = bucketer.generateBucketValue(bucketingId: hashId)
            
            XCTAssertEqual(test["expect"] as! Int, bucketingValue);
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
