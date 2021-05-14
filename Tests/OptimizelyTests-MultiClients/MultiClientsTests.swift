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

class MultiClientsTests: XCTestCase {
    let testSdkKeyBasename = "testSdkKey"
    var sdkKeys = [String]()

    override func setUp() {
        OTUtils.createDocumentDirectoryIfNotAvailable()
        OTUtils.clearAllTestStorage(including: testSdkKeyBasename)
    }

    override func tearDown() {
        OTUtils.clearAllBinders()
        OTUtils.clearAllTestStorage(including: testSdkKeyBasename)
    }

    func testMultiClients() {        
        sdkKeys = OTUtils.makeRandomSdkKeys(10)

        let datafile = OTUtils.loadJSONDatafileString("decide_datafile")
        
        let result = OTUtils.runConcurrent(for: sdkKeys) { thIdx, sdkKey in
            let datafileHandler = MockDatafileHandler(statusCode: 200, localResponseData: datafile)

            let eventDispatcher = DumpEventDispatcher()
            let client = OptimizelyClient(sdkKey: sdkKey,
                                          eventDispatcher: eventDispatcher,
                                          datafileHandler: datafileHandler,
                                          periodicDownloadInterval: 1,
                                          defaultLogLevel: .debug)
            
            let group = DispatchGroup()
            group.enter()
            
            client.start { result in
                let expectedDatafile = datafileHandler.getDatafile(sdkKey: sdkKey)

                switch result {
                case .success(let data):
                    let str = String(data: data, encoding: .utf8)
                    XCTAssert(str == expectedDatafile)
                default:
                    XCTAssert(false)
                }
                group.leave()
            }
            
            group.wait()
        }
        
        XCTAssertTrue(result, "Concurrent tasks timed out")
    }

}
