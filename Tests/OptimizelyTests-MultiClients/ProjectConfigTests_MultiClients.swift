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

class ProjectConfigTests_MultiClients: XCTestCase {
    var config: ProjectConfig!
    
    override func setUpWithError() throws {
        config = try! ProjectConfig()
    }

    func testConcurrentAccess() {
        let numThreads = 10
        let numEventsPerThread = 100
        
        let result = OTUtils.runConcurrent(count: numThreads) { thIdx in
            for idx in 0..<numEventsPerThread {
                let userId = String(idx)
                let experimentId = String((thIdx * numEventsPerThread) + idx)
                let variationId = experimentId

                self.config.whitelistUser(userId: userId, experimentId: experimentId, variationId: variationId)
                let result = self.config.getWhitelistedVariationId(userId: userId, experimentId: experimentId)
                XCTAssertEqual(result, variationId)
            }
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }
    
}
