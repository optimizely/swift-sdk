//
// Copyright 2021, Optimizely, Inc. and contributors 
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

class UserProfileServiceTests_MultiClients: XCTestCase {

    let profiles: [[String: Any]] = [
        [
            "user_id": "0",
            "experiment_bucket_map": [
                "1234": [
                    "variation_id": "5678"
                ]
            ]
        ],
        [
            "user_id": "1",
            "experiment_bucket_map": [
                "1234": [
                    "variation_id": "5678"
                ]
            ]
        ]
    ]

    override func setUpWithError() throws {
        OTUtils.bindLoggerForTest(.error)
        OTUtils.clearAllUPS()
    }

    override func tearDownWithError() throws {
        OTUtils.clearAllUPS()
    }

    func testConcurrentAccess() {
        let ups = DefaultUserProfileService()
        let userId1 = "0"
        let userId2 = "1"

        let result = OTUtils.runConcurrent(count: 100) { item in
            (0..<100).forEach{ _ in
                ups.save(userProfile: self.profiles[0])
                ups.save(userProfile: self.profiles[1])
                
                let up1 = ups.lookup(userId: userId1)!
                let up2 = ups.lookup(userId: userId2)!
                
                XCTAssertEqual(up1["user_id"] as? String, userId1)
                if let a = up1["experiment_bucket_map"] as? [String: [String: String]], let variation = a["1234"]?["variation_id"] {
                    XCTAssertEqual(variation, "5678")
                }
                XCTAssertEqual(up2["user_id"] as? String, userId2)
                if let a = up2["experiment_bucket_map"] as? [String: [String: String]], let variation = a["1234"]?["variation_id"] {
                    XCTAssertEqual(variation, "5678")
                }
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
    func testConcurrentUpdateFromDecisionService() {
        // this test is validating thread-safety of read-modify-write UPS operations from decision-service
        
        let ups = DefaultUserProfileService()
        let ds = DefaultDecisionService(userProfileService: ups)
        let numThreads = 4
        let numUsers = 2
        let numEventsPerThread = 10

        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 10) { thIdx in
            print("[MultiClients] UpdateFromDecisionService starts: \(thIdx)")
            for userIdx in 0..<numUsers {
                for eventIdx in 0..<numEventsPerThread {
                    let userId = String(userIdx)
                    let experimentId = String((thIdx * numEventsPerThread) + eventIdx)
                    let variationId = experimentId
                    ds.saveProfile(userId: userId, experimentId: experimentId, variationId: variationId)
                    
                    print("[MultiClients] saving: \(thIdx) \(userId) \(experimentId)")
                }
            }
            print("[MultiClients] UpdateFromDecisionService ends: \(thIdx)")
        }
        XCTAssertTrue(result, "Concurrent tasks timed out")
        
        (0..<numThreads).forEach{ thIdx in
            for userIdx in 0..<numUsers {
                for eventIdx in 0..<numEventsPerThread {
                    let userId = String(userIdx)
                    let experimentId = String((thIdx * numEventsPerThread) + eventIdx)
                    let variationId = ds.getVariationIdFromProfile(userId: userId, experimentId: experimentId)
                    XCTAssertEqual(variationId, experimentId, "UPS variation for {\(userId), \(experimentId)}: \(String(describing:variationId))")
                }
            }
            print("[MultiClients] UpdateFromDecisionService validated: \(thIdx)")
        }
    }
    
    func testConcurrentUpdateFromDecisionService_2() {
        // this test is validating thread-safety of read-modify-write UPS operations from decision-service
        
        let ups = DefaultUserProfileService()
        let numThreads = 4
        let numUsers = 2
        let numEventsPerThread = 10
        
        var dss = [DefaultDecisionService]()
        (0..<numThreads).forEach { _ in
            dss.append(DefaultDecisionService(userProfileService: ups))
        }

        let result = OTUtils.runConcurrent(count: numThreads, timeoutInSecs: 10) { thIdx in
            let ds = dss[thIdx]

            print("[MultiClients] UpdateFromDecisionService starts: \(thIdx)")
            for userIdx in 0..<numUsers {
                for eventIdx in 0..<numEventsPerThread {
                    let userId = String(userIdx)
                    let experimentId = String((thIdx * numEventsPerThread) + eventIdx)
                    let variationId = experimentId
                    ds.saveProfile(userId: userId, experimentId: experimentId, variationId: variationId)
                    
                    print("[MultiClients] saving: \(thIdx) \(userId) \(experimentId)")
                }
            }
            print("[MultiClients] UpdateFromDecisionService ends: \(thIdx)")
        }
        XCTAssertTrue(result, "Concurrent tasks timed out")
        
        (0..<numThreads).forEach{ thIdx in
            let ds = dss[thIdx]

            for userIdx in 0..<numUsers {
                for eventIdx in 0..<numEventsPerThread {
                    let userId = String(userIdx)
                    let experimentId = String((thIdx * numEventsPerThread) + eventIdx)
                    let variationId = ds.getVariationIdFromProfile(userId: userId, experimentId: experimentId)
                    XCTAssertEqual(variationId, experimentId, "UPS variation for {\(userId), \(experimentId)}: \(String(describing:variationId))")
                }
            }
            print("[MultiClients] UpdateFromDecisionService validated: \(thIdx)")
        }
    }
    
}
