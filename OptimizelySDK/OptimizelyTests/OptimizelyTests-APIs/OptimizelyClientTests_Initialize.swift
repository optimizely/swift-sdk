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

class OptimizelyClientTests_Initialize: XCTestCase {
    
    // MARK: - Properties
    
    // Change to test with a mock DatafileHandler (instead of a real sdkKey)
    var sdkKey = "AqLkkcss3wRGUbftnKNgh2"
    
    func testStartOptimizelyClient_CachedDatafile() {
        let optimizely = OptimizelyClient(sdkKey: sdkKey)
        
        // 1st fetch - cache hit or miss
        
        var exp = expectation(description: "fetch")
        optimizely.start { result in
            switch result {
            case .success:
                XCTAssert(true)
            case .failure:
                XCTAssert(false)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)

        // 2nd fetch - cache hit
        
        exp = expectation(description: "fetch")
        optimizely.start { result in
            switch result {
            case .success:
                XCTAssert(true)
            case .failure:
                XCTAssert(false)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 30)

        XCTAssert(true)
    }

}
