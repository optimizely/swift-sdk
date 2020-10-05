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

class BucketTests_Base: XCTestCase {

    // MARK: - murmur-hash compliant

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
    
    func testAllocateExperimentTraffic() {
        var experimentData: [String: Any] { return
            [
                "status": "Running",
                "id": "12345",
                "key": "experimentA",
                "layerId": "10420273888",
                "trafficAllocation": [
                    [
                        "entityId": "1000",
                        "endOfRange": 0
                    ],
                    [
                        "entityId": "1001",
                        "endOfRange": 3000
                    ],
                    [
                        "entityId": "1002",
                        "endOfRange": 6000
                    ]
                ],
                "audienceIds": [],
                "variations": [
                    [
                        "variables": [],
                        "id": "1000",
                        "key": "a"
                    ],
                    [
                        "variables": [],
                        "id": "1001",
                        "key": "b"
                    ],
                    [
                        "variables": [],
                        "id": "1002",
                        "key": "c"
                    ]
                ],
                "forcedVariations": [:]
            ]
        }
        
        let bucketer = DefaultBucketer()
        let experiment: Experiment = try! OTUtils.model(from: experimentData)
        let trafficAllocation = experiment.trafficAllocation
        
        XCTAssert(bucketer.allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: 0) == "1001")
        XCTAssert(bucketer.allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: 2999) == "1001")
        XCTAssert(bucketer.allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: 3000) == "1002")
        XCTAssert(bucketer.allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: 5999) == "1002")
        XCTAssertNil(bucketer.allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: 6000))
        XCTAssertNil(bucketer.allocateTraffic(trafficAllocation: trafficAllocation, bucketValue: 7000))
    }
    
}
