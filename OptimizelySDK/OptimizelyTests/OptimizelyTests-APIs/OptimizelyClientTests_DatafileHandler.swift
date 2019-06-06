//
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

class OptimizelyClientTests_DatafileHandler: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testOptimizelyClientWithCachedDatafile() {
        var fileUrl:URL?
        
        // create a dummy file at a url to use as our datafile local download
        fileUrl = OTUtils.saveAFile(name: "localcdn", data: OTUtils.loadJSONDatafile("api_datafile")!)
        
        // default datafile handler
        class InnerDatafileHandler : DefaultDatafileHandler {
            var localFileUrl:URL?
            // override getSession to return our own session.
            override func getSession(resourceTimeoutInterval: Double?) -> URLSession {
                
                let session = MockUrlSession()
                session.downloadCacheUrl = localFileUrl
                
                return session
            }
        }
        
        // create test datafile handler
        let handler = InnerDatafileHandler()
        //save the cached datafile..
        let data = OTUtils.loadJSONDatafile("api_datafile")

        handler.saveDatafile(sdkKey: "localcdnTestSDKKey", dataFile: data!)
        handler.dataStore.setLastModified(sdkKey: "localcdnTestSDKKey", lastModified: "1234")
        // set the url to use as our datafile download url
        handler.localFileUrl = fileUrl
        
        HandlerRegistryService.shared.registerBinding(binder: Binder<OPTDatafileHandler>(service: OPTDatafileHandler.self).using(instance: handler).singetlon().sdkKey(key: "localcdnTestSDKKey").reInitializeStrategy(strategy: .reUse))
        
        let client = OptimizelyClient(sdkKey: "localcdnTestSDKKey")
        
        let expectation = XCTestExpectation(description: "get datafile from cache")
        
        client.start() { (result) in
            switch result {
            case .success(let data):
                XCTAssert(!data.isEmpty)
                expectation.fulfill()
            case .failure:
                XCTAssert(false)
            }
        }
        
        wait(for: [expectation], timeout: 3)
        
        try? FileManager.default.removeItem(at: fileUrl!)
        
        client.datafileHandler.stopAllUpdates()
        
        HandlerRegistryService.shared.binders.removeAll()

        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
