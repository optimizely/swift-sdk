//
//  BucketTests.swift
//  OptimizelyCoreTests
//
//  Created by Thomas Zurkan on 12/4/18.
//  Copyright © 2018 Optimizely. All rights reserved.
//

import XCTest

class BucketTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
        let experimentId = "1886780721"
        let bucketer = DefaultBucketer.createInstance(config: ProjectConfig())
        // These test inputs/outputs should be reproduced exactly in all clients to make sure that they behave
        // consistently.
        let tests = [["userId": "ppid1", "experimentId": experimentId, "expect": 5254],
        ["userId": "ppid2", "experimentId": experimentId, "expect": 4299],
        // Same PPID as previous, diff experiment ID
        ["userId": "ppid2", "experimentId": "1886780722", "expect": 2434],
        ["userId": "ppid3", "experimentId": experimentId, "expect": 5439],
        ["userId": "a very very very very very very very very very very very very very very very long ppd string", "experimentId": experimentId, "expect": 6128]];
        
        for test in tests {
            let hashId = bucketer?.makeHashIdFromBucketingId(bucketingId:test["userId"] as! String, entityId:test["experimentId"] as! String)
            let bucketingValue = bucketer?.generateBucketValue(bucketingId: hashId!)
            
            XCTAssertEqual(test["expect"] as! Int, bucketingValue!);
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
