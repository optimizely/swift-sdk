//
//  BucketTests_Base.swift
//  OptimizelySwiftSDK
//
//  Created by Jae Kim on 3/26/19.
//  Copyright © 2019 Optimizely. All rights reserved.
//

import XCTest

class BucketTests_Base: XCTestCase {

    // MARK: - murmur-hash compliant

    func testHashIsCompliant() {
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
    
}

