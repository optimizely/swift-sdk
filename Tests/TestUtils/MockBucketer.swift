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


// MARK: - Helper for mocking bucketer

class MockBucketer: DefaultBucketer {
    var mockBucketValue: Int
    
    init(mockBucketValue: Int) {
        self.mockBucketValue = mockBucketValue
        super.init()
    }
    
    override func generateBucketValue(bucketingId: String) -> Int {
        return mockBucketValue
    }
}

// MARK: - Mock Decision Service

class MockDecisionService: DefaultDecisionService {
    init(bucketer: OPTBucketer, userProfileService: OPTUserProfileService = DefaultUserProfileService()) {
        super.init(userProfileService: userProfileService, bucketer: bucketer)
    }
}

