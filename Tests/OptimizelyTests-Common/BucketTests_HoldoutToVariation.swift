//
// Copyright 2019, 2021, Optimizely, Inc. and contributors
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

class BucketTests_HoldoutToVariation: XCTestCase {
    var optimizely: OptimizelyClient!
    var config: ProjectConfig!
    var bucketer: DefaultBucketer!
    
    var kUserId = "123456"
    var kHoldoutId = "4444444"
    var kHoldoutKey = "holdout_key"
    
    var kVariationKeyA = "a"
    var kVariationIdA = "a11"
    
    var kAudienceIdCountry = "10"
    var kAudienceIdAge = "20"
    var kAudienceIdInvalid = "9999999"
    
    var kAttributesCountryMatch: [String: Any] = ["country": "us"]
    var kAttributesCountryNotMatch: [String: Any] = ["country": "ca"]
    var kAttributesAgeMatch: [String: Any] = ["age": 30]
    var kAttributesAgeNotMatch: [String: Any] = ["age": 10]
    var kAttributesEmpty: [String: Any] = [:]
    
    var holdout: Holdout!
    
    // MARK: - Sample datafile data
    
    var sampleHoldoutData: [String: Any] {
        return [
            "status": "Running",
            "id": kHoldoutId,
            "key": kHoldoutKey,
            "layerId": "10420273888",
            "trafficAllocation": [
                ["entityId": kVariationIdA, "endOfRange": 1000] // 10% traffic allocation (0-1000 out of 10000)
            ],
            "audienceIds": [kAudienceIdCountry],
            "variations": [
                ["variables": [], "id": kVariationIdA, "key": kVariationKeyA]
            ],
        ]
    }
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        
        self.optimizely = OTUtils.createOptimizely(datafileName: "empty_datafile",
                                                   clearUserProfileService: true)
        self.config = self.optimizely.config!
        self.bucketer = ((optimizely.decisionService as! DefaultDecisionService).bucketer as! DefaultBucketer)
        
        // Initialize holdout
        holdout = try! OTUtils.model(from: sampleHoldoutData)
    }
    
    // MARK: - Tests for bucketToVariation
    
    func testBucketToVariation_ValidBucketingWithinAllocation() {
        // Test users that should bucket into the single variation (within 0-1000 range)
        let testCases = [
            ["userId": "user1", "expectedVariation": kVariationKeyA], // Buckets to variation A
            ["userId": "testuser", "expectedVariation": kVariationKeyA] // Buckets to variation A
        ]
        
        for (index, test) in testCases.enumerated() {
            // Mock bucket value to ensure it falls within 0-1000
            let mockBucketValue = 500 // Within 10% allocation
            let mockBucketer = Mockbucketer(mockBucketValue: mockBucketValue)
            let response = mockBucketer.bucketToVariation(experiment: holdout, bucketingId: test["userId"]!)
            XCTAssertNotNil(response.result, "Variation should not be nil for test case \(index)")
            XCTAssertEqual(response.result?.key, test["expectedVariation"], "Wrong variation for test case \(index)")
        }
    }
    
    func testBucketToVariation_BucketValueOutsideAllocation() {
        // Test users that fall outside the 10% allocation (bucket value > 1000)
        let testCases = [
            ["userId": "user2"],
            ["userId": "anotheruser"]
        ]
        
        for (index, test) in testCases.enumerated() {
            // Mock bucket value to ensure it falls outside 0-1000
            let mockBucketValue = 1500 // Outside 10% allocation
            let mockBucketer = Mockbucketer(mockBucketValue: mockBucketValue)
            let response = mockBucketer.bucketToVariation(experiment: holdout, bucketingId: test["userId"]!)
            XCTAssertNil(response.result, "Variation should be nil for test case \(index) when outside allocation")
        }
    }
    
    func testBucketToVariation_NoTrafficAllocation() {
        // Create a holdout with empty traffic allocation
        var modifiedHoldoutData = sampleHoldoutData
        modifiedHoldoutData["trafficAllocation"] = []
        let modifiedHoldout = try! OTUtils.model(from: modifiedHoldoutData) as Holdout
        
        let response = bucketer.bucketToVariation(experiment: modifiedHoldout, bucketingId: kUserId)
        
        XCTAssertNil(response.result, "Variation should be nil when no traffic allocation")        
    }
    
    func testBucketToVariation_InvalidVariationId() {
        // Create a holdout with invalid variation ID in traffic allocation
        var modifiedHoldoutData = sampleHoldoutData
        modifiedHoldoutData["trafficAllocation"] = [
            ["entityId": "invalid_variation_id", "endOfRange": 1000]
        ]
        let modifiedHoldout = try! OTUtils.model(from: modifiedHoldoutData) as Holdout
        
        let response = bucketer.bucketToVariation(experiment: modifiedHoldout, bucketingId: kUserId)
        
        XCTAssertNil(response.result, "Variation should be nil for invalid variation ID")
    }
    
    func testBucketToVariation_EmptyBucketingId() {
        // Test with empty bucketing ID, still within allocation
        let mockBucketValue = 500
        let mockBucketer = Mockbucketer(mockBucketValue: mockBucketValue)
        let response = mockBucketer.bucketToVariation(experiment: holdout, bucketingId: "")
        
        XCTAssertNotNil(response.result, "Should still bucket with empty bucketing ID")
        XCTAssertEqual(response.result?.key, kVariationKeyA, "Should bucket to variation A")
    }
}

// MARK: - Helper for mocking bucket value

class Mockbucketer: DefaultBucketer {
    var mockBucketValue: Int
    
    init(mockBucketValue: Int) {
        self.mockBucketValue = mockBucketValue
        super.init()
    }
    
    override func generateBucketValue(bucketingId: String) -> Int {
        print(mockBucketValue)
        return mockBucketValue
    }
}
