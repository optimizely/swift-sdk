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

class OptimizelyClientTests_DatafileHandler: XCTestCase {

    let sdkKey = "localcdnTestSDKKey"
    
    override func setUp() {
        OTUtils.bindLoggerForTest(.info)
        OTUtils.createDocumentDirectoryIfNotAvailable()
    }

    override func tearDown() {
        OTUtils.clearAllBinders()
        OTUtils.clearAllTestStorage(including: sdkKey)
    }

    func testOptimizelyClientWithCachedDatafile() {
        // create test datafile handler
        let handler = MockDatafileHandler(statusCode: 0, passError: false, localResponseData: OTUtils.loadJSONDatafileString("api_datafile"))
        //save the cached datafile..
        let data = OTUtils.loadJSONDatafile("api_datafile")

        handler.saveDatafile(sdkKey: sdkKey, dataFile: data!)
        handler.sharedDataStore.setLastModified(sdkKey: sdkKey, lastModified: "1234")
        
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDatafileHandler>(sdkKey: sdkKey, service: OPTDatafileHandler.self, strategy: .reUse, isSingleton: true, inst: handler))
        
        let client = OptimizelyClient(sdkKey: sdkKey)
        
        let expectation = XCTestExpectation(description: "get datafile from cache")
        
        client.start() { (result) in
            if case let .success(data) = result{
                XCTAssert(!data.isEmpty)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3)
                
        client.datafileHandler?.stopAllUpdates()
        
        HandlerRegistryService.shared.binders.property?.removeAll()

        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
