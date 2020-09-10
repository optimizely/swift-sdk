/****************************************************************************
* Copyright 2020, Optimizely, Inc. and contributors                        *
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

class OptimizelyClientTests_Decide: XCTestCase {

    var optimizely: OptimizelyClient!

    override func setUp() {
        super.setUp()
        
        let datafile = OTUtils.loadJSONDatafile("api_datafile")!
        optimizely = OptimizelyClient(sdkKey: OTUtils.randomSdkKey)
        try! optimizely.start(datafile: datafile)
    }
   
    func testSetUserContext() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user = OptimizelyUserContext(userId: "tester", attributes: attributes)
        
        try! optimizely.setUserContext(user)
        
        XCTAssert(optimizely.userContext == user)
    }
    
    func testSetUserContext_replace() {
        let attributes: [String: Any] = [
            "country": "us",
            "age": 100,
            "old": true
        ]
        let user1 = OptimizelyUserContext(userId: "tester1", attributes: attributes)
        let user2 = OptimizelyUserContext(userId: "tester2", attributes: [:])
        
        try! optimizely.setUserContext(user1)
        XCTAssert(optimizely.userContext == user1)
        
        try! optimizely.setUserContext(user2)
        XCTAssert(optimizely.userContext == user2)
    }
    
    func testSetDefaultDecideOptions() {
        let expOptions: [OptimizelyDecideOption] = [.ignoreUPS,
                                                    .disableDecisionEvent,
                                                    .enabledOnly,
                                                    .includeReasons]
        optimizely.setDefaultDecideOptions(expOptions)
        
        XCTAssert(optimizely.defaultDecideOptions == expOptions)
    }
    
    func testSetDefaultDecideOptions_replace() {
        let options1: [OptimizelyDecideOption] = [.ignoreUPS, .disableDecisionEvent]
        let options2: [OptimizelyDecideOption] = [.enabledOnly]

        optimizely.setDefaultDecideOptions(options1)
        XCTAssert(optimizely.defaultDecideOptions == options1)
        
        optimizely.setDefaultDecideOptions(options2)
        XCTAssert(optimizely.defaultDecideOptions == options2)
    }


}

